defmodule JidoBuilderRuntime.MemoryStoreTest do
  use ExUnit.Case, async: false

  alias JidoBuilderRuntime.MemoryStore

  setup do
    MemoryStore.init()
    # Clear any test data from previous runs
    for space <- MemoryStore.list_spaces() do
      MemoryStore.clear_space(space)
    end

    :ok
  end

  test "write and read a value" do
    :ok = MemoryStore.write("test_space", "key1", "value1")
    assert {:ok, "value1"} = MemoryStore.read("test_space", "key1")
  end

  test "read returns nil for missing key" do
    assert {:ok, nil} = MemoryStore.read("nonexistent", "missing")
  end

  test "write overwrites existing value" do
    :ok = MemoryStore.write("s", "k", "v1")
    :ok = MemoryStore.write("s", "k", "v2")
    assert {:ok, "v2"} = MemoryStore.read("s", "k")
  end

  test "search finds matching keys" do
    :ok = MemoryStore.write("research", "topic_ai", "Active Inference")
    :ok = MemoryStore.write("research", "topic_ml", "Machine Learning")
    :ok = MemoryStore.write("research", "author", "Karl Friston")

    results = MemoryStore.search("research", "topic")
    assert length(results) == 2
    assert Enum.any?(results, &(&1.key == "topic_ai"))
    assert Enum.any?(results, &(&1.key == "topic_ml"))
  end

  test "search with empty pattern returns all entries" do
    :ok = MemoryStore.write("s", "a", "1")
    :ok = MemoryStore.write("s", "b", "2")
    results = MemoryStore.search("s", "")
    assert length(results) == 2
  end

  test "list_spaces returns distinct space names" do
    :ok = MemoryStore.write("alpha", "k", "v")
    :ok = MemoryStore.write("beta", "k", "v")
    spaces = MemoryStore.list_spaces()
    assert "alpha" in spaces
    assert "beta" in spaces
  end

  test "delete removes an entry" do
    :ok = MemoryStore.write("s", "k", "v")
    :ok = MemoryStore.delete("s", "k")
    assert {:ok, nil} = MemoryStore.read("s", "k")
  end

  test "list_entries returns all entries in a space" do
    :ok = MemoryStore.write("s", "a", "1")
    :ok = MemoryStore.write("s", "b", "2")
    entries = MemoryStore.list_entries("s")
    assert length(entries) == 2
  end

  test "clear_space removes all entries in a space" do
    :ok = MemoryStore.write("s", "a", "1")
    :ok = MemoryStore.write("s", "b", "2")
    :ok = MemoryStore.clear_space("s")
    assert MemoryStore.list_entries("s") == []
  end
end
