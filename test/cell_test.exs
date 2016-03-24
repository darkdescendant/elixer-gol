defmodule GOL.CellTest do
  use ExUnit.Case, async: true

	setup do
		{:ok, cell} = GOL.Cell.start_link({1,1}, {10, 10})
		{:ok, cell: cell}
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

	test "can get count of live neighbors", %{cell: cell} do
		neighbors = GOL.Cell.neighbors(cell)
		Enum.each(neighbors, fn (n) ->
			GOL.CellRegistry.create(n, {10,10})
		end)

		anc = GOL.Cell.count_living_neighbors(cell)
		assert anc == 0

		Enum.each(neighbors, fn (n) ->
			{:ok, neighbor_cell} = GOL.CellRegistry.lookup(n)
			assert GOL.Cell.cell_id(neighbor_cell) == n
			GOL.Cell.set_state(neighbor_cell, :alive)
			assert GOL.Cell.get_state(neighbor_cell) == :alive
			:ok
		end)

		anc = GOL.Cell.count_living_neighbors(cell)
		assert anc == 8
	end
		
end
