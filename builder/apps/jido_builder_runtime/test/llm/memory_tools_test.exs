defmodule JidoBuilderRuntime.LLM.MemoryToolsTest do
  @moduledoc "Epic 2.5 — Memory-augmented generation tools tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.LLM.MemoryTools
  alias JidoBuilderRuntime.LLM.ToolBridge

  describe "all/0" do
    test "returns all memory tool modules" do
      tools = MemoryTools.all()
      assert length(tools) == 3
    end
  end

  describe "MemoryRead" do
    test "has correct tool metadata" do
      assert MemoryTools.MemoryRead.name() == "memory_read"
      assert MemoryTools.MemoryRead.description() != nil
    end

    test "converts to LLM tool schema" do
      [tool] = ToolBridge.actions_to_tools([MemoryTools.MemoryRead])
      assert tool.name == "memory_read"
      assert tool.parameters_schema != nil
    end

    test "runs with params" do
      {:ok, result} = Jido.Exec.run(MemoryTools.MemoryRead,
        %{space: "facts", key: "color"}, %{})

      assert result.space != nil
    end
  end

  describe "MemoryWrite" do
    test "has correct tool metadata" do
      assert MemoryTools.MemoryWrite.name() == "memory_write"
    end

    test "runs with params" do
      {:ok, result} = Jido.Exec.run(MemoryTools.MemoryWrite,
        %{space: "facts", key: "color", value: "blue"}, %{})

      assert result.written == true
      assert result.value == "blue"
    end
  end

  describe "MemorySearch" do
    test "has correct tool metadata" do
      assert MemoryTools.MemorySearch.name() == "memory_search"
    end

    test "runs with params" do
      {:ok, result} = Jido.Exec.run(MemoryTools.MemorySearch,
        %{space: "facts", pattern: "col*"}, %{})

      assert result.space == "facts"
      assert result.results == []
    end
  end
end
