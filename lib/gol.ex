defmodule GOL do
	use Application

	def start(_type, _args) do
		GOL.Supervisor.start_link
	end
end
