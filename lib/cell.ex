defmodule GOL.Cell do

	def start_link(cell_id, bounds) do
		Agent.start_link(fn -> %{cell_id: cell_id, bounds: bounds, state: :dead} end)
	end

	def cell_id(cell) do
		Agent.get(cell, &Map.get(&1, :cell_id))
	end

	def neighbors(cell) do
		case Agent.get(cell, &Map.get(&1, :neighbors)) do
			{:ok, n} -> n
		  _ ->
				{cx, cy} = GOL.Cell.cell_id(cell)
				{bx, by} = Agent.get(cell, &Map.get(&1, :bounds))
				n = for nx <- cx-1..cx+1, ny <- cy-1..cy+1, nx >= 0 && nx < bx, ny >= 0 && ny < by, !(nx == cx && ny == cy), do: {nx, ny}
				Agent.update(cell, &Map.put(&1, :neighbors, n))
				n
		end
	end

	def set_state(cell, state) do
		Agent.update(cell, &Map.put(&1, :state, state))
	end

	def get_state(cell) do
		Agent.get(cell, &Map.get(&1, :state))
	end
	
end
