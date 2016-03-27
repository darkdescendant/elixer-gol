defprotocol GOL.Board.Writer do
	@doc """
	Output a board
	"""
	def write_board(_, registry)
end

