defmodule GOL.CellTest do
  use ExUnit.Case, async: true

	@board_width 3
	@board_height 3
	@board_dim {@board_width, @board_height}
	
	setup context do
		{:ok, registry} = GOL.CellRegistry.start_link(context.test)
		cells = for cx <- 0..(@board_width - 1), cy <- 0..(@board_height-1), do: {cx,cy}
		rules = GOL.ConwayRules.create
		Enum.each(cells, fn(c) ->
			GOL.CellRegistry.create(registry, c, @board_dim, rules)
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
	
	test "should change bar to hbar" do
		board_width = board_height = 20
		board_dim = {board_width, board_height}

		{:ok, registry} = GOL.CellRegistry.start_link(:BigTestRegistry)
		cells = for cx <- 0..(board_width - 1), cy <- 0..(board_height-1), do: {cx,cy}
		rules = GOL.ConwayRules.create
		Enum.each(cells, fn(c) ->
			GOL.CellRegistry.create(registry, c, board_dim, rules)
		end)
		{:ok, cell} = GOL.CellRegistry.lookup(registry, {1,1})

		add_pattern_to_board(registry, [{0,1}, {1,1}, {2,1}])

		# board_writer = GOL.Board.ConsoleWriter.create(board_width, board_height)		
		# GOL.Board.Writer.write_board(board_writer, registry)

		GOL.Cell.update(cell, self, registry)
		assert_receive {:"$gen_cast", {:report_to_caller, ^cell}}, 50000

		GOL.Cell.swap(cell, self)
		assert_receive {:"$gen_cast", {:neighbor_swap_complete, ^cell}}, 50000

		# GOL.Board.Writer.write_board(board_writer, registry)

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

		GOL.CellRegistry.stop(registry)
	end

	defp add_pattern_to_board(registry, cell_ids) do
		cells = Enum.map(cell_ids, fn(cell_id) ->
			{:ok, cell} = GOL.CellRegistry.lookup(registry, cell_id)
			cell
		end)

		Enum.each(cells, fn(cell) ->
			GOL.Cell.set_state(cell, :alive)
		end)
	end
			
end
