defmodule JidoBuilderRuntime.ActionsTest do
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Actions.{Echo, IncrementCounter, LogMessage, TransformData}

  test "echo returns inbound payload" do
    assert {:ok, %{echo: "ping"}} = Echo.run(%{message: "ping"}, %{})
  end

  test "increment_counter applies increment amount" do
    assert {:ok, %{counter: 4}} = IncrementCounter.run(%{counter: 1, amount: 3}, %{})
  end

  test "transform_data handles uppercase and reverse" do
    assert {:ok, %{result: "ABC"}} = TransformData.run(%{operation: "uppercase", data: "abc"}, %{})
    assert {:ok, %{result: "cba"}} = TransformData.run(%{operation: "reverse", data: "abc"}, %{})
  end

  test "log_message appends entry" do
    assert {:ok, %{log: [%{message: "hello"}]}} = LogMessage.run(%{message: "hello", log: []}, %{})
  end
end
