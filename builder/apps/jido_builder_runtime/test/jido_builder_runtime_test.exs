defmodule JidoBuilderRuntimeTest do
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Context

  test "context validation requires workspace and actor" do
    assert {:error, _} = Context.validate(%{})
    assert {:ok, _ctx} = Context.validate(%{workspace_id: 1, actor: "tester"})
  end
end
