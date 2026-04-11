defmodule JidoBuilderWeb.ConnCaseLoadingTest do
  use JidoBuilderWeb.ConnCase, async: false

  @tag :conn_case_loading
  test "ConnCase support file is compiled for test env" do
    assert true == true
  end
end
