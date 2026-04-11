defmodule JidoBuilderRuntimeTest do
  use ExUnit.Case
  doctest JidoBuilderRuntime

  test "greets the world" do
    assert JidoBuilderRuntime.hello() == :world
  end
end
