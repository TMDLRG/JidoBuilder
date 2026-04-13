defmodule JidoBuilderRuntime.LLM.MemoryTools do
  @moduledoc """
  Jido Actions for reading/writing/searching Memory spaces.

  These actions can be used as LLM tools, enabling memory-augmented
  generation where the LLM can persistently store and retrieve knowledge.
  """

  defmodule MemoryRead do
    @moduledoc "Read a value from a memory space."
    use Jido.Action,
      name: "memory_read",
      description: "Read a value from agent memory by space name and key",
      schema: [
        space: [type: :string, required: true],
        key: [type: :string, required: true]
      ]

    alias JidoBuilderRuntime.MemoryStore

    def run(params, context) do
      space = to_string(params[:space] || params["space"])
      key = to_string(params[:key] || params["key"])
      agent = context[:agent]

      cond do
        agent != nil ->
          try do
            space_atom = String.to_existing_atom(space)
            key_atom = String.to_existing_atom(key)
            value = Jido.Memory.Agent.get_in_space(agent, space_atom, key_atom)
            {:ok, %{space: space, key: key, value: value}}
          rescue
            _ ->
              {:ok, value} = MemoryStore.read(space, key)
              {:ok, %{space: space, key: key, value: value}}
          end

        true ->
          {:ok, value} = MemoryStore.read(space, key)
          {:ok, %{space: space, key: key, value: value}}
      end
    end
  end

  defmodule MemoryWrite do
    @moduledoc "Write a value to a memory space."
    use Jido.Action,
      name: "memory_write",
      description: "Write a value to agent memory in a named space",
      schema: [
        space: [type: :string, required: true],
        key: [type: :string, required: true],
        value: [type: :string, required: true]
      ]

    alias JidoBuilderRuntime.MemoryStore

    def run(params, _context) do
      space = to_string(params[:space] || params["space"])
      key = to_string(params[:key] || params["key"])
      value = to_string(params[:value] || params["value"])

      :ok = MemoryStore.write(space, key, value)
      {:ok, %{written: true, space: space, key: key, value: value}}
    end
  end

  defmodule MemorySearch do
    @moduledoc "Search memory spaces for matching keys."
    use Jido.Action,
      name: "memory_search",
      description: "Search agent memory spaces for keys matching a pattern",
      schema: [
        space: [type: :string, required: true],
        pattern: [type: :string, required: false]
      ]

    alias JidoBuilderRuntime.MemoryStore

    def run(params, _context) do
      space = to_string(params[:space] || params["space"])
      pattern = to_string(params[:pattern] || params["pattern"] || "")

      results = MemoryStore.search(space, pattern)
      {:ok, %{space: space, pattern: pattern, results: results}}
    end
  end

  @doc "Returns all memory tool action modules."
  @spec all() :: [module()]
  def all do
    [MemoryRead, MemoryWrite, MemorySearch]
  end
end
