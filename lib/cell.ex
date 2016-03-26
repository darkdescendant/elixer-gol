defmodule GOL.Cell do
	use GenServer

	@doc"""
	Create a new cell GenServer instance.
	"""
	def start_link(cell_id, bounds) do
		GenServer.start_link(__MODULE__, %{cell_id: cell_id, bounds: bounds, state: :dead})
	end

	# GenServer Call APIs
	
	@doc"""
	Get the cell ID for the cell.
	"""
	def cell_id (cell) do
		GenServer.call(cell, {:get_cell_id})
	end

	@doc"""
	Get the current state of the cell.
	"""
	def get_state(cell) do
		{:ok, state} = GenServer.call(cell, {:get_state})
		state
	end

	@doc"""
	Set the current cell to the given state.
	"""
	def set_state(cell, new_state) do
		GenServer.call(cell, {:set_state, new_state})
	end

	@doc"""
	Return the list of neighbors for this cell. 
	
	The list contains all the cells 1 delta from the current cell, 
	within the bounds {0..bounds_width, 0..bounds_height}
	"""
	def neighbors(cell) do
		GenServer.call(cell, {:neighbors})
	end

	@doc"""
	Return the count of living neighbors for this cell
	"""
	def count_living_neighbors(cell, registry) do
		GenServer.call(cell, {:count_living_neighbors, registry})
	end

	@doc"""
	Calculate and return the next state for this cell.
	"""
	def next_state(cell, registry) do
		GenServer.call(cell, {:get_next_state, registry})
	end

	@doc"""
	Tell the cell to swap the current state for the calculated next state.
	"""
	def swap_state(cell) do
		GenServer.call(cell, {:swap})
	end
	
	def handle_call(request, from, state) do
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
				get_neighbors(state)
			{:count_living_neighbors, registry} ->
				get_living_neighbor_count(state, registry)				
			{:get_next_state, registry} ->
				calculate_next_state(state, registry)
			{:swap} ->
				do_swap_state(state)
		end
	end

	# GenServer Cast APIs

	@doc"""
	Send an asynchronous message to start off an update cycle.
	"""
	def update(cell, from, registry) do
		GenServer.cast(cell, {:update, from, registry})
	end

	@doc"""
	Kick off updates to all teh neighbor cells
	"""
	def update_neighbors(cell) do
		GenServer.cast(cell, {:update_neighbors})
	end
	

	@doc"""
	Handle neighbor cell update completion notices.
	
	Once all neighbor cells have reported completion we can move onto
	getting neighbor states.
	"""
	def update_complete(cell) do
		GenServer.cast(cell, {:update_complete})
	end

	@doc"""
	Request the current state of all neighbors.
	"""
	def get_current_state(cell, from) do
		GenServer.cast(cell, {:get_current_state, from})
	end

	@doc"""
	Handle the response state sent from each neighbor.

	Once all neighbor cells have responded we can kick off calculating
	our new state.
	"""
	def recieve_current_state(cell, from, neighbor_state) do
		GenServer.cast(cell, {:recieve_current_state, from, neighbor_state})
	end

	@doc"""
	Actually calculate the net state of the cell.
	"""
	def calculate_next_state(cell) do
		GenServer.cast(cell, {:calculate_next_state})
	end
	
	@doc"""
	Once we are done calculating we can report back to the parent
	that told us to update that we are done.
	"""
	def report_to_caller(cell, from) do
		GenServer.cast(cell, {:report_to_caller, from})
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
 		end
	end

	# GenServer server callbacks.
	def init(data) do
		{:ok, data}
	end

	defp handle_update(state, from, registry) do
		case Map.fetch(state, :callers) do
			{:ok, callers} ->
			  GOL.Cell.report_to_caller(from, self)
			_ ->
				state = Map.put(state, :callers, [from])
				state = Map.put(state, :registry, registry)
				state = Map.put(state, :neighbor_states, [])
				GOL.Cell.update_neighbors(self)
		end
		{:noreply, state}
	end

	defp handle_update_neighbors(state) do
		{:ok, registry} = Map.fetch(state, :registry)
		{_,n,_} = get_neighbors(state)
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

	defp handle_update_complete(state) do
		{:ok, callers} = Map.fetch(state, :callers)
		Enum.each(callers, fn (caller) ->
			GOL.Cell.report_to_caller(caller, self)
		end)

		state = Map.delete(state, :callers)
		state = Map.delete(state, :registry)
		{:noreply, state}
	end
	
	defp handle_report_to_caller(state, from) do
		if {:ok, update_cells} = Map.fetch(state, :update_cells) do
			update_cells = List.delete(update_cells, from)
			state = Map.put(state, :update_cells, update_cells)
			if (Enum.count(update_cells) == 0) do
				{:ok, registry} = Map.fetch(state, :registry)
				state = Map.delete(state, :update_cells)
				{_,n,_} = get_neighbors(state)
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

	defp handle_get_current_state(state, from) do
		{:ok, current_state} = Map.fetch(state, :state)
		GOL.Cell.recieve_current_state(from, self, current_state)
		{:noreply, state}
	end

	defp handle_recieve_current_state(state, from, neighbor_state) do
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

	defp handle_calculate_next_state(state) do
		{:ok, current_state} = Map.fetch(state, :state)
		{:ok, neighbor_states} = Map.fetch(state, :neighbor_states)
	 	alive_count = Enum.count(Enum.filter(neighbor_states, fn (cs) -> cs == :alive end))
	 	next_state = get_next_state(alive_count, current_state)
	 	state = Map.put(state, :next_state, next_state)
		state = Map.delete(state, :neighbor_states)
		GOL.Cell.update_complete(self)
		{:noreply, state}
	end

	# TODO: All this code should be replaced by a rules engine so that we
	# can plug in new rule sets without changing the cell implementation.
	defp get_neighbors(data) do
		case Map.get(data, :neighbors) do
			{:ok, n} -> n
			_ ->
				{:ok, {cx, cy}} = Map.fetch(data, :cell_id)
				{:ok, {bx, by}} = Map.fetch(data, :bounds)
				n = for nx <- cx-1..cx+1, ny <- cy-1..cy+1, nx >= 0 && nx < bx, ny >= 0 && ny < by, !(nx == cx && ny == cy), do: {nx, ny}
								{:reply, n, Map.put(data, :neighbors, n)}
		end
	end
	
	defp get_living_neighbor_count(data, registry) do
		{_,n,_} = get_neighbors(data)
		cell_states = Enum.map(n, fn (n) ->
			{:ok, cell} = GOL.CellRegistry.lookup(registry, n)
			GOL.Cell.get_state(cell)
		end)
		
		count = Enum.count(Enum.filter(cell_states, fn (cs) -> cs == :alive end))
		{:reply, count, data}
	end
	
	defp calculate_next_state(data, registry) do
		{_, lnc, _} = get_living_neighbor_count(data, registry)
		{:ok, cs} = Map.fetch(data, :state)
		next_state = get_next_state(lnc, cs)
		{:reply, next_state, Map.put(data, :next_state, next_state)}
	end
	
	defp get_next_state(count, current_state) do
		next_state = :dead
		case {count, current_state} do
			{2, :alive} ->
				next_state = :alive
			{3, :dead} ->
				next_state = :alive
			{3, :alive} ->
				next_state = :alive
			_ ->
				next_state = :dead
		end
		next_state
	end
	
	defp do_swap_state(data) do
		{:ok, next_state} = Map.fetch(data, :next_state)
		new_data = Map.put(data, :state, next_state)
		{:reply, :ok, new_data}
	end

end
