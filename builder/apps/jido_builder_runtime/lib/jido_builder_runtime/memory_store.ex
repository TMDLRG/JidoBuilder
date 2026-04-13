defmodule JidoBuilderRuntime.MemoryStore do
  @moduledoc """
  ETS-backed persistent memory store for JidoBuilder.

  Provides named memory spaces where agents and the notebook can
  read/write/search key-value pairs. Data persists for the lifetime
  of the BEAM node.

  ## Usage

      MemoryStore.write("research", "topic", "Active Inference")
      {:ok, "Active Inference"} = MemoryStore.read("research", "topic")
      results = MemoryStore.search("research", "top")
      spaces = MemoryStore.list_spaces()
  """

  @table :jido_memory_store

  @doc "Initialize the ETS table. Called from Application.start."
  def init do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :public, :set])
    end

    :ok
  end

  @doc "Write a value to a memory space."
  def write(space, key, value) do
    ensure_table()
    :ets.insert(@table, {{to_string(space), to_string(key)}, value})
    :ok
  end

  @doc "Read a value from a memory space."
  def read(space, key) do
    ensure_table()

    case :ets.lookup(@table, {to_string(space), to_string(key)}) do
      [{{_s, _k}, value}] -> {:ok, value}
      [] -> {:ok, nil}
    end
  end

  @doc "Search a memory space for keys matching a pattern."
  def search(space, pattern \\ "") do
    ensure_table()
    space_str = to_string(space)
    pattern_str = String.downcase(to_string(pattern))

    :ets.tab2list(@table)
    |> Enum.filter(fn {{s, k}, _v} ->
      s == space_str and (pattern_str == "" or String.contains?(String.downcase(k), pattern_str))
    end)
    |> Enum.map(fn {{_s, k}, v} -> %{key: k, value: v} end)
  end

  @doc "List all distinct space names."
  def list_spaces do
    ensure_table()

    :ets.tab2list(@table)
    |> Enum.map(fn {{s, _k}, _v} -> s end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc "List all entries in a space."
  def list_entries(space) do
    ensure_table()
    space_str = to_string(space)

    :ets.tab2list(@table)
    |> Enum.filter(fn {{s, _k}, _v} -> s == space_str end)
    |> Enum.map(fn {{_s, k}, v} -> %{key: k, value: v} end)
    |> Enum.sort_by(& &1.key)
  end

  @doc "Delete a specific entry."
  def delete(space, key) do
    ensure_table()
    :ets.delete(@table, {to_string(space), to_string(key)})
    :ok
  end

  @doc "Clear all entries in a space."
  def clear_space(space) do
    ensure_table()
    space_str = to_string(space)

    :ets.tab2list(@table)
    |> Enum.filter(fn {{s, _k}, _v} -> s == space_str end)
    |> Enum.each(fn {key, _v} -> :ets.delete(@table, key) end)

    :ok
  end

  @doc "Count total entries across all spaces."
  def count do
    ensure_table()
    :ets.info(@table, :size)
  end

  defp ensure_table do
    if :ets.whereis(@table) == :undefined, do: init()
  end
end
