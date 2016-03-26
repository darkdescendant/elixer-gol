defmodule GOL.Rules do
	@callback get_neighbors( data :: map) :: [any]
	@callback get_living_neighbor_count(data :: map, registry :: GOL.CellRegistry) :: integer
	@callback calculate_next_state(data :: map, registry :: GOL.CellRegistry) :: atom
	@callback get_next_state(count :: integer, current_state :: atom) :: atom 
end
