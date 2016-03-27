defmodule GOL.Board.ConsoleWriter do
	defstruct [name: "Board Console Writer", width: 0, height: 0, cell_writer: GOL.Cell.ConsoleWriter.create]

	def create(width, height) do
		%GOL.Board.ConsoleWriter{width: width, height: height}
	end

	def width(writer) do
		{:ok, width} = Map.fetch(writer, :width)
		width
	end

	def height(writer) do
		{:ok, height} = Map.fetch(writer, :height)
		height
	end

	def cell_writer(board_writer) do
		{:ok, cell_writer} = Map.fetch(board_writer, :cell_writer)
		cell_writer
	end
	
	def write_cell(board_writer, registry, y, x) do
		{:ok, cell} = GOL.CellRegistry.lookup(registry, {x,y})
		state = GOL.Cell.get_state(cell)
		cell_writer = GOL.Board.ConsoleWriter.cell_writer(board_writer)
		GOL.Cell.Writer.print_cell_state(cell_writer, state)
	end

	def write_row(board_writer, registry, y, width) do
		GOL.Board.ConsoleWriter.write_cell( board_writer,registry, y, width)
		if (width >= GOL.Board.ConsoleWriter.width(board_writer)-1) do
			cell_writer = GOL.Board.ConsoleWriter.cell_writer(board_writer)
			GOL.Cell.Writer.end_line(cell_writer)
		else
			GOL.Board.ConsoleWriter.write_row( board_writer,registry, y, width+1)
		end
	end

	def write_board(board_writer, registry, width, height) do
		cell_writer = GOL.Board.ConsoleWriter.cell_writer(board_writer)
		GOL.Cell.Writer.start_line(cell_writer)
		GOL.Board.ConsoleWriter.write_row(board_writer, registry, height, width)
		if (height >= GOL.Board.ConsoleWriter.height(board_writer)-1) do
			cell_writer = GOL.Board.ConsoleWriter.cell_writer(board_writer)
			GOL.Cell.Writer.end_line(cell_writer)
		else
			GOL.Board.ConsoleWriter.write_board(board_writer, registry, width, height+1)
		end
	end

	def write_board(board_writer, registry) do
		cell_writer = GOL.Board.ConsoleWriter.cell_writer(board_writer)
		GOL.Cell.Writer.start_board(cell_writer)
		GOL.Board.ConsoleWriter.write_board(board_writer, registry, 0, 0)
		GOL.Cell.Writer.start_board(cell_writer)
	end

end

defimpl GOL.Board.Writer, for: GOL.Board.ConsoleWriter do
	def write_board(board_writer, registry) do
		GOL.Board.ConsoleWriter.write_board(board_writer, registry)
	end
end
