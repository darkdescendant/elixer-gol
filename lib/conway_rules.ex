defmodule GOL.ConwayRules do
	defstruct name: "Conway Rules"

	def create, do: %GOL.ConwayRules{}
end

defimpl GOL.Rules, for: GOL.ConwayRules do
	
	def get_neighbors(_rules, data) do
		case Map.get(data, :neighbors) do
			{:ok, n} -> n
			_ ->
				{:ok, {cx, cy}} = Map.fetch(data, :cell_id)
				{:ok, {bx, by}} = Map.fetch(data, :bounds)
				for nx <- cx-1..cx+1, ny <- cy-1..cy+1, nx >= 0 && nx < bx, ny >= 0 && ny < by, !(nx == cx && ny == cy), do: {nx, ny}
		end
	end
	
	def get_living_neighbor_count(rules, data, registry) do
		n = get_neighbors(rules, data)
		cell_states = Enum.map(n, fn (n) ->
			{:ok, cell} = GOL.CellRegistry.lookup(registry, n)
			GOL.Cell.get_state(cell)
		end)
		
		Enum.count(Enum.filter(cell_states, fn (cs) -> cs == :alive end))
	end
	
	def calculate_next_state(rules, data, registry) do
		lnc = get_living_neighbor_count(rules, data, registry)
		{:ok, cs} = Map.fetch(data, :state)
		get_next_state(rules, lnc, cs)
	end
	
	def get_next_state(_rules, count, current_state) do
		case {count, current_state} do
			{2, :alive} ->
				:alive
			{3, :dead} ->
				:alive
			{3, :alive} ->
				:alive
			_ ->
				:dead
		end
	end

end
