defmodule GOL.CellServer do
	use GenServer

		def handle_call(request, _from, state) do
		case request do
			{:get_cell_id} ->
				{:ok, cell_id} = Map.fetch(state, :cell_id)
				{:reply, cell_id, state}
			{:get_state} ->
				{:reply, Map.fetch(state, :state), state}
			{:set_state, new_state} ->
				state = Map.put(state, :state, new_state)
				{:reply, :ok, state}
			{:neighbors} ->
				{:reply, GOL.ConwayRules.get_neighbors(state), state}
			{:count_living_neighbors, registry} ->
				{:reply, GOL.ConwayRules.get_living_neighbor_count(state, registry), state}
			{:get_next_state, registry} ->
				next_cell_state = GOL.ConwayRules.calculate_next_state(state, registry)
			  state = Map.put(state, :next_state, next_cell_state)
			  {:reply, next_cell_state, state}
			{:swap} ->
				do_swap_state(state)
		end
	end

			def handle_cast(request, state) do
		case request do
			{:update, from, registry} ->
				handle_update(state, from, registry)
			{:update_neighbors} ->
				handle_update_neighbors(state)
			{:get_current_state, from} ->
				handle_get_current_state(state, from)
			{:recieve_current_state, from, neighbor_state} ->
				handle_recieve_current_state(state, from, neighbor_state)
			{:calculate_next_state} ->
				handle_calculate_next_state(state)
			{:update_complete} ->
				handle_update_complete(state)
			{:report_to_caller, from} ->
				handle_report_to_caller(state, from)
			{:swap, from, registry} ->
				handle_swap(state, from, registry)
			{:neighbor_swap} ->
				handle_neighbor_swap(state)
			{:neighbor_swap_complete, from} ->
				handle_neighbor_swap_complete(state, from)
			{:report_swap_complete} ->
				handle_report_swap_complete(state)
			{:cell_swap_state} ->
				handle_cell_swap_state(state)
 		end
	end

				# GenServer server callbacks.
	def init(data) do
		{:ok, data}
	end

	def handle_update(state, from, registry) do
		case Map.fetch(state, :callers) do
			{:ok, _callers} ->
			  GOL.Cell.report_to_caller(from, self)
			_ ->
				state = Map.put(state, :callers, [from])
				state = Map.put(state, :registry, registry)
				state = Map.put(state, :neighbor_states, [])
				GOL.Cell.update_neighbors(self)
		end
		{:noreply, state}
	end

	def handle_update_neighbors(state) do
		{:ok, registry} = Map.fetch(state, :registry)
		n = GOL.ConwayRules.get_neighbors(state)
		update_cells = Enum.map(n, fn (c) ->
			{:ok, target} = GOL.CellRegistry.lookup(registry, c)
			target
		end)
		
		state = Map.put(state, :update_cells, update_cells)

		Enum.each(update_cells, fn(c) ->
			GOL.Cell.update(c, self, registry)
		end)
		
		{:noreply, state}
	end

	def handle_update_complete(state) do
		{:ok, callers} = Map.fetch(state, :callers)
		Enum.each(callers, fn (caller) ->
			GOL.Cell.report_to_caller(caller, self)
		end)

		state = Map.delete(state, :callers)
		state = Map.delete(state, :registry)
		{:noreply, state}
	end
	
	def handle_report_to_caller(state, from) do
		if {:ok, update_cells} = Map.fetch(state, :update_cells) do
			update_cells = List.delete(update_cells, from)
			state = Map.put(state, :update_cells, update_cells)
			if (Enum.count(update_cells) == 0) do
				{:ok, registry} = Map.fetch(state, :registry)
				state = Map.delete(state, :update_cells)
				n = GOL.ConwayRules.get_neighbors(state)
				state_cells = Enum.map(n, fn (c) ->
					{:ok, target} = GOL.CellRegistry.lookup(registry, c)
					target
				end)
				state = Map.put(state, :state_cells, state_cells)
				Enum.each(state_cells, fn (c) ->
					GOL.Cell.get_current_state(c, self)
				end)
			end
		end
		{:noreply, state}
	end

	def handle_get_current_state(state, from) do
		{:ok, current_state} = Map.fetch(state, :state)
		GOL.Cell.recieve_current_state(from, self, current_state)
		{:noreply, state}
	end

	def handle_recieve_current_state(state, from, neighbor_state) do
		{:ok, neighbor_states} = Map.fetch(state, :neighbor_states)
		{:ok, state_cells} = Map.fetch(state, :state_cells)
		
		neighbor_states = [neighbor_state] ++ neighbor_states
		state = Map.put(state, :neighbor_states, neighbor_states)
		state_cells = List.delete(state_cells, from)
		state = Map.put(state, :state_cells, state_cells)
		
		if (Enum.count(state_cells) == 0) do
			state = Map.delete(state, :state_cells)
			GOL.Cell.calculate_next_state(self)
		end
		
		{:noreply, state}
	end

	def handle_calculate_next_state(state) do
		{:ok, current_state} = Map.fetch(state, :state)
		{:ok, neighbor_states} = Map.fetch(state, :neighbor_states)
	 	alive_count = Enum.count(Enum.filter(neighbor_states, fn (cs) -> cs == :alive end))
	 	next_state = GOL.ConwayRules.get_next_state(alive_count, current_state)
	 	state = Map.put(state, :next_state, next_state)
		state = Map.delete(state, :neighbor_states)
		GOL.Cell.update_complete(self)
		{:noreply, state}
	end

	
	def do_swap_state(data) do
		{:ok, next_state} = Map.fetch(data, :next_state)
		new_data = Map.put(data, :state, next_state)
		{:reply, :ok, new_data}
	end

	def handle_swap(state, from, registry) do
		case Map.fetch(state, :caller) do
			{:ok, _} ->
				GOL.Cell.neighbor_swap_complete(from, self)
			_ ->
				state = Map.put(state, :caller, from)
				state = Map.put(state, :registry, registry)
				GOL.Cell.neighbor_swap(self)
		end
		{:noreply, state}
	end

	def handle_neighbor_swap(state) do
		{:ok, registry} = Map.fetch(state, :registry)
		ns = GOL.ConwayRules.get_neighbors(state)
		swap_cells = Enum.map(ns, fn (n) ->
			{:ok, cell} = GOL.CellRegistry.lookup(registry, n)
			cell
		end)
		state = Map.put(state, :swap_cells, swap_cells) 
		Enum.each(swap_cells, fn (cell) ->
			GOL.Cell.swap(cell, self, registry)
		end)
		{:noreply, state}
	end

	def handle_neighbor_swap_complete(state, from) do
		{:ok, swap_cells} = Map.fetch(state, :swap_cells)
		swap_cells = List.delete(swap_cells, from)
		state = Map.put(state, :swap_cells, swap_cells)
		if (Enum.count(swap_cells) == 0) do
			state = Map.delete(state, :swap_cells)
			GOL.Cell.report_swap_complete(self)
		end
		{:noreply, state}
	end

	def handle_report_swap_complete(state) do
		GOL.Cell.cell_swap_state(self)
		{:noreply, state}
	end
	
	def handle_cell_swap_state(state) do
		{:ok, caller} = Map.fetch(state, :caller)
		{:ok, next_state} = Map.fetch(state, :next_state)
		state = Map.put(state, :state, next_state)

		state = Map.delete(state, :caller)
		state = Map.delete(state, :registry)

		GOL.Cell.neighbor_swap_complete(caller, self)
		{:noreply, state}
	end

		
end
