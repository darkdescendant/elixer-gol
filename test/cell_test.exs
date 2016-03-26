defmodule GOL.CellTest do
  use ExUnit.Case, async: true

	setup context do
		{:ok, registry} = GOL.CellRegistry.start_link(context.test)
		cells = for cx <- 0..2, cy <- 0..2, do: {cx,cy}
		Enum.each(cells, fn(c) ->
			GOL.CellRegistry.create(registry, c, {3,3})
		end)
		{:ok, cell} = GOL.CellRegistry.lookup(registry, {1,1})
		{:ok, %{cell: cell, registry: registry}}
	end

	test "can get cell's id", %{cell: cell} do
		assert GOL.Cell.cell_id(cell) == {1,1}
	end

	test "can get cell's neighbors", %{cell: cell} do
		assert GOL.Cell.neighbors(cell) == [{0,0}, {0,1}, {0,2}, {1,0}, {1,2}, {2,0}, {2,1}, {2,2}]
	end

	test "can get cells state", %{cell: cell} do
		assert GOL.Cell.get_state(cell) == :dead

		assert GOL.Cell.set_state(cell, :alive) == :ok
		assert GOL.Cell.get_state(cell) == :alive
	end

	test "can get count of live neighbors", %{cell: cell, registry: registry} do
		anc = GOL.Cell.count_living_neighbors(cell, registry)
		assert anc == 0
		neighbors = GOL.Cell.neighbors(cell)
		Enum.each(neighbors, fn (n) ->
			{:ok, neighbor_cell} = GOL.CellRegistry.lookup(registry, n)
			assert GOL.Cell.cell_id(neighbor_cell) == n
			GOL.Cell.set_state(neighbor_cell, :alive)
			assert GOL.Cell.get_state(neighbor_cell) == :alive
			:ok
		end)

		anc = GOL.Cell.count_living_neighbors(cell, registry)
		assert anc == 8
	end

	test "dead cell stays dead", %{registry: registry} do
		{:ok, t_cell} = GOL.CellRegistry.lookup(registry, {0,0})
		assert GOL.Cell.next_state(t_cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,1})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(t_cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,0})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(t_cell, registry) == :dead

	end

	test "dead cell lives", %{registry: registry} do
		{:ok, t_cell} = GOL.CellRegistry.lookup(registry, {0,0})
		assert GOL.Cell.next_state(t_cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,1})
		GOL.Cell.set_state(n_cell, :alive)
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,0})
		GOL.Cell.set_state(n_cell, :alive)
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,1})
		GOL.Cell.set_state(n_cell, :alive)

		anc = GOL.Cell.count_living_neighbors(t_cell, registry)
		assert anc == 3

		assert GOL.Cell.next_state(t_cell, registry) == :alive

	end

	test "alive cell stays alive", %{cell: cell, registry: registry} do
		GOL.Cell.set_state(cell, :alive)

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,0})
		GOL.Cell.set_state(n_cell, :alive)

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,1})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :alive
		
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,0})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :alive
		
	end

	test "alive cell dies", %{cell: cell, registry: registry} do
		GOL.Cell.set_state(cell, :dead)
		assert GOL.Cell.next_state(cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,0})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,1})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :dead
		
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,0})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :alive

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,2})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {2,0})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {2, 1})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {2, 2})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.next_state(cell, registry) == :dead
	end

	test "should set state to next state on command", %{cell: cell, registry: registry} do
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,0})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.get_state(cell) == :dead
		assert GOL.Cell.next_state(cell, registry) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,1})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.get_state(cell) == :dead
		assert GOL.Cell.next_state(cell, registry) == :dead
		
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,0})
		GOL.Cell.set_state(n_cell, :alive)
		assert GOL.Cell.get_state(cell) == :dead
		assert GOL.Cell.next_state(cell, registry) == :alive

		GOL.Cell.swap_state(cell)
		assert GOL.Cell.get_state(cell) == :alive
		assert GOL.Cell.next_state(cell, registry) == :alive
	end

	test "should receive a report notification", %{cell: cell, registry: registry} do
		GOL.Cell.update(cell, self, registry)
		assert_receive {:"$gen_cast", {:report_to_caller, ^cell}}, 5000
	end
	
	test "should change bar to hbar", %{cell: cell, registry: registry} do
		board = for cx <- 0..2, cy <- 0..2, do: {cx,cy}
		
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,1})
		GOL.Cell.set_state(n_cell, :alive)
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,1})
		GOL.Cell.set_state(n_cell, :alive)
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {2,1})
		GOL.Cell.set_state(n_cell, :alive)

		GOL.Cell.update(cell, self, registry)
		assert_receive {:"$gen_cast", {:report_to_caller, ^cell}}, 5000

		Enum.each(board, fn (n) ->
			{:ok, cell} = GOL.CellRegistry.lookup(registry, n)
			state = GOL.Cell.swap_state(cell)
		end)

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {0,1})
		assert GOL.Cell.get_state(n_cell) == :dead
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,1})
		assert GOL.Cell.get_state(n_cell) == :alive
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {2,1})
		assert GOL.Cell.get_state(n_cell) == :dead

		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,0})
		assert GOL.Cell.get_state(n_cell) == :alive
		{:ok, n_cell} = GOL.CellRegistry.lookup(registry, {1,2})
		assert GOL.Cell.get_state(n_cell) == :alive

	end

	defp print_board(board, registry) do
		IO.puts "\n---------"
		
		Enum.each(board, fn (n) ->
			{:ok, cell} = GOL.CellRegistry.lookup(registry, n)
			state = GOL.Cell.get_state(cell)
			case state do
				:alive -> IO.write "X"
				:dead -> IO.write "."
			end
		end)

		IO.puts "\n---------"
	end
	
end
