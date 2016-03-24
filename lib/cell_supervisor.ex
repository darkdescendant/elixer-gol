defmodule GOL.Cell.Supervisor do
	use Supervisor

	@name GOL.Cell.Supervisor

	def start_link() do
		Supervisor.start_link(__MODULE__, :ok, name: @name)
	end

	def start_cell(name, bounds) do
		Supervisor.start_child(@name, [name, bounds])
	end

	def init(:ok) do
		children = [
			worker(GOL.Cell, [], restart: :temporary)
		]

		supervise(children, strategy: :simple_one_for_one)
	end
	
end
