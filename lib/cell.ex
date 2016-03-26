defmodule GOL.Cell do
	use GenServer

	@doc"""
	Create a new cell GenServer instance.
	"""
	def start_link(cell_id, bounds) do
		GenServer.start_link(GOL.CellServer, %{cell_id: cell_id, bounds: bounds, state: :dead})
	end

	# GenServer Call APIs
	
	@doc"""
	Get the cell ID for the cell.
	"""
	def cell_id (cell) do
		GenServer.call(cell, {:get_cell_id})
	end

	@doc"""
	Get the current state of the cell.
	"""
	def get_state(cell) do
		{:ok, state} = GenServer.call(cell, {:get_state})
		state
	end

	@doc"""
	Set the current cell to the given state.
	"""
	def set_state(cell, new_state) do
		GenServer.call(cell, {:set_state, new_state})
	end

	@doc"""
	Return the list of neighbors for this cell. 
	
	The list contains all the cells 1 delta from the current cell, 
	within the bounds {0..bounds_width, 0..bounds_height}
	"""
	def neighbors(cell) do
		GenServer.call(cell, {:neighbors})
	end

	@doc"""
	Return the count of living neighbors for this cell
	"""
	def count_living_neighbors(cell, registry) do
		GenServer.call(cell, {:count_living_neighbors, registry})
	end

	@doc"""
	Calculate and return the next state for this cell.
	"""
	def next_state(cell, registry) do
		GenServer.call(cell, {:get_next_state, registry})
	end

	@doc"""
	Tell the cell to swap the current state for the calculated next state.
	"""
	def swap_state(cell) do
		GenServer.call(cell, {:swap})
	end
	

	# GenServer Cast APIs

	@doc"""
	Send an asynchronous message to start off an update cycle.
	"""
	def update(cell, from, registry) do
		GenServer.cast(cell, {:update, from, registry})
	end

	@doc"""
	Kick off updates to all teh neighbor cells
	"""
	def update_neighbors(cell) do
		GenServer.cast(cell, {:update_neighbors})
	end
	

	@doc"""
	Handle neighbor cell update completion notices.
	
	Once all neighbor cells have reported completion we can move onto
	getting neighbor states.
	"""
	def update_complete(cell) do
		GenServer.cast(cell, {:update_complete})
	end

	@doc"""
	Request the current state of all neighbors.
	"""
	def get_current_state(cell, from) do
		GenServer.cast(cell, {:get_current_state, from})
	end

	@doc"""
	Handle the response state sent from each neighbor.

	Once all neighbor cells have responded we can kick off calculating
	our new state.
	"""
	def recieve_current_state(cell, from, neighbor_state) do
		GenServer.cast(cell, {:recieve_current_state, from, neighbor_state})
	end

	@doc"""
	Actually calculate the net state of the cell.
	"""
	def calculate_next_state(cell) do
		GenServer.cast(cell, {:calculate_next_state})
	end
	
	@doc"""
	Once we are done calculating we can report back to the parent
	that told us to update that we are done.
	"""
	def report_to_caller(cell, from) do
		GenServer.cast(cell, {:report_to_caller, from})
	end

	@doc"""
	Start swap sate machine to kickoff cell state swap.
	"""
	def swap(cell, from, registry) do
	end

	@doc"""
	Tell our neighbor cells to swap first.
	"""
	def neighbor_swap(cell) do
	end
	
	@doc"""
	Tell parent that the neighbor swap is done.

  When all neighbor cells are done we can swap our state.
	"""
	def neighbor_swap_complete(cell, from) do
	end
	
	@doc"""
	Start swap sate machine to kickoff cell state swap.
	"""
	def swap_state(cell) do
	end
	
	@doc"""
	Report the swap is complete.
	"""
	def report_swap_complete(cell, from, registry) do
	end


end
