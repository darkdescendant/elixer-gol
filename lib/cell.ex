defmodule GOL.Cell do
	use GenServer
	
	def start_link(cell_id, bounds) do
		GenServer.start_link(__MODULE__, %{cell_id: cell_id, bounds: bounds, state: :dead}, [])
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
				case Map.get(data, :neighbors) do
					{:ok, n} -> n
					_ ->
						{:ok, {cx, cy}} = Map.fetch(data, :cell_id)
						{:ok, {bx, by}} = Map.fetch(data, :bounds)
						n = for nx <- cx-1..cx+1, ny <- cy-1..cy+1, nx >= 0 && nx < bx, ny >= 0 && ny < by, !(nx == cx && ny == cy), do: {nx, ny}
						{:reply, n, Map.put(data, :neighbors, n)}
				end
		end
		
	end
	
end
