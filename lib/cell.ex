defmodule GOL.Cell do
	use GenServer
	
	def start_link(cell_id, bounds) do
		GenServer.start_link(__MODULE__, %{cell_id: cell_id, bounds: bounds, state: :dead})
		#Agent.start_link(fn -> %{cell_id: cell_id, bounds: bounds, state: :dead} end)
	end

	def cell_id(cell) do
		{:ok, id} = GenServer.call(cell, {:cell_id})
		id
	end

	def neighbors(cell) do
		GenServer.call(cell, {:neighbors})
	end

	def set_state(cell, state) do
		_ = GenServer.call(cell, {:set_state, state})
		:ok
	end

	def get_state(cell) do
		{:ok, state} = GenServer.call(cell, {:get_state})
		state
	end

	def count_living_neighbors(cell, registry) do
		GenServer.call(cell, {:count_living_neighbors, registry})
	end

	def next_state(cell, registry) do
		GenServer.call(cell, {:next_state, registry})
	end

	def swap_state(cell) do
		GenServer.call(cell, {:swap_state})
	end
	
	def init(data) do
		{:ok, data}
	end

	def handle_call(request, _from, data) do
		case request do
			{:cell_id} -> 
				{:reply, Map.fetch(data, :cell_id), data}
			{:get_state} ->
				{:reply, Map.fetch(data, :state), data}
			{:set_state, state} ->
				{:reply, :ok, Map.put(data, :state, state)}
			{:neighbors} ->
				get_neighbors(data)
			{:count_living_neighbors, registry} ->
				get_living_neighbor_count(data, registry)
			{:next_state, registry} ->
				calculate_next_state(data, registry)
			{:swap_state} ->
				{:ok, next_state} = Map.fetch(data, :next_state)
				{:reply, :ok, Map.put(data, :state, next_state)}
		end
	end

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
		next_state = :dead
		IO.inspect {lnc, cs}
		case {lnc, cs} do
			{2, :alive} ->
				next_state = :alive
			{3, :dead} ->
				next_state = :alive
			{3, :alive} ->
				next_state = :alive
			_ ->
				next_state = :dead
		end
		IO.inspect next_state
		IO.puts ""
		{:reply, next_state, Map.put(data, :next_state, next_state)}
	end
end
