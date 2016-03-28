defprotocol GOL.Cell.Writer do

	@doc """
	Handle start of board output
	"""
	def start_board(_)

	@doc """
	Handle start of line output
	"""
	def start_line(_)

	@doc """
	Handle cell state output
	"""
	def print_cell_state(_, state)

	@doc """
	Handle end of line output
	"""
	def end_line(_)

	@doc """
	Handle end of board output
	"""
	def end_board(_)
end
