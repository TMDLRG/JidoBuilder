defmodule JidoBuilderWebTest do
  use ExUnit.Case, async: true

  test "exposes expected static paths" do
    assert "assets" in JidoBuilderWeb.static_paths()
    assert "favicon.ico" in JidoBuilderWeb.static_paths()
  end
end
