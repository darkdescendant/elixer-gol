defprotocol GOL.Rules do

	@doc """
	Return a list of the neighbor cell ids for this cell
	"""
	def get_neighbors(_, data)

	@doc """
	Return the count of living cells around this cell.
	"""
	def get_living_neighbor_count(_, data, registry)

	@doc """
	Return next state given just the cell data.
	"""
	def calculate_next_state(_, data, registry)

	@doc """
	Return next state given explicit count and current state.
	"""
	def get_next_state(_, count, current_state)
end

