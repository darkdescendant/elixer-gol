defmodule GOL.Supervisor do
	use Supervisor

	def start_link do
		Supervisor.start_link(__MODULE__, :ok)
	end

	def init(:ok) do
		children = [
			worker(GOL.CellRegistry, [GOL.CellRegistry.name]),
			supervisor(GOL.Cell.Supervisor, [])
		]

		supervise(children, strategy: :one_for_one)
	end
	
end
