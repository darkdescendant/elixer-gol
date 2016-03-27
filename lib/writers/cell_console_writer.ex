defmodule GOL.Cell.ConsoleWriter do
	defstruct name: "Console Writer"

	def create, do: %GOL.Cell.ConsoleWriter{}
end

defimpl GOL.Cell.Writer, for: GOL.Cell.ConsoleWriter do
	def start_board(_cw) do
		IO.puts ""
	end
	
	def start_line(_cw) do
	end
	
	def print_cell_state(_cw, state) do
		case state do
			:alive -> IO.write "X"
			:dead -> IO.write "."
		end
	end
	
	def end_line(_cw) do
		IO.puts ""
	end
	
	def end_board(_cw) do
		IO.puts ""
	end
	
end
