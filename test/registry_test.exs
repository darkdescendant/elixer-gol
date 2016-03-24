defmodule GOL.CellRegistryTest do
  use ExUnit.Case, async: true

	setup context do
		{:ok, registry} = GOL.CellRegistry.start_link(context.test)
		{:ok, registry: registry}
	end

	test "Can register a cell", %{registry: registry} do
		assert GOL.CellRegistry.lookup(registry, {1,1}) == :error

		GOL.CellRegistry.create(registry, {1,1},{10,10})
		assert {:ok, cell} = GOL.CellRegistry.lookup(registry, {1,1})
		assert GOL.Cell.cell_id(cell) == {1,1}
	end

	test "removes cell on exit", %{registry: registry} do
		GOL.CellRegistry.create(registry, {1,1},{10,10})
		assert {:ok, cell} = GOL.CellRegistry.lookup(registry, {1,1})
		Agent.stop(cell)
		assert GOL.CellRegistry.lookup(registry, {1,1}) == :error
		
	end

	test "removes cell on crash", %{registry: registry} do
		GOL.CellRegistry.create(registry, {1,1}, {10,10})
		{:ok, cell} = GOL.CellRegistry.lookup(registry, {1,1})
		Process.exit(cell, :shutdown)

		ref = Process.monitor(cell)
		assert_receive {:DOWN, ^ref, _,_,_}
		assert GOL.CellRegistry.lookup(registry, {1,1}) == :error
	end
	
end
