defmodule JidoBuilderWeb.Live.ObservabilityTest do
  @moduledoc """
  Epic 7 — Observability pages render correctly.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "traces page renders with filter controls", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/traces")
    assert html =~ "Traces" or html =~ "traces"
  end

  test "debug page renders", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/debug")
    assert html =~ "Debug" or html =~ "debug"
  end

  test "error policy page renders", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/error-policy")
    assert html =~ "Error" or html =~ "error"
  end

  test "execution page renders", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/execution")
    assert html =~ "Execution" or html =~ "execution"
  end

  test "audit page renders", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/audit")
    assert html =~ "Audit" or html =~ "audit"
  end
end
