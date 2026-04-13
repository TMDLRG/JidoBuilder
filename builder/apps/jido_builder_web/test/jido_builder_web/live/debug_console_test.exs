defmodule JidoBuilderWeb.Live.DebugConsoleTest do
  @moduledoc "Story 7.2 — Debug console with REPL-like interaction."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "debug page renders agent state inspector section", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/debug")

    assert html =~ "Agent State Inspector"
  end

  test "debug page renders signal injection form", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/debug")

    assert html =~ "debug-signal-form"
    assert html =~ "Signal Type"
  end

  test "debug page renders log stream section", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/debug")

    assert html =~ "Log Stream"
    assert html =~ "log-filter"
  end
end
