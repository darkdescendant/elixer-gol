defmodule GOL.CellRegistry do
	use GenServer

	@name GOL.CellRegistry
	def name, do: @name

	def start_link(name) do
		GenServer.start_link(__MODULE__, :ok, name: name)
	end

	def stop(server) do
		GenServer.stop(server)
	end
	
	def lookup(name) do
		GenServer.call(@name, {:lookup, name})
	end

	def lookup(server, name) do
		GenServer.call(server, {:lookup, name})
	end

	def create(name, bounds) do
		GenServer.cast(@name, {:create, name, bounds})
	end

	def create(server, name, bounds) do
		GenServer.cast(server, {:create, name, bounds})
	end

	def init(:ok) do
		names = %{}
		refs = %{}
		{:ok, {names, refs}}
	end

	def handle_call({:lookup, name}, _from, {names, _} = state) do
		{:reply, Map.fetch(names, name), state}
	end

	def handle_cast({:create, name, bounds}, {names, refs} = state) do
		if Map.has_key?(names, name) do
			{:noreply, state}
		else
			{:ok, pid} = GOL.Cell.Supervisor.start_cell(name, bounds)
			ref = Process.monitor(pid)
			refs = Map.put(refs, ref, name)
			names = Map.put(names, name, pid)
			{:noreply, {names, refs}}
		end
		
	end

	def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
		{name, refs} = Map.pop(refs, ref)
		names = Map.delete(names, name)
		{:noreply, {names, refs}}
	end

	def handle_info(_msg, state) do
		{:noreply, state}
	end
	
end
