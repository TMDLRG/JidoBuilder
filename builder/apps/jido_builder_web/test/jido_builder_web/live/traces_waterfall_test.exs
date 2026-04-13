defmodule JidoBuilderWeb.Live.TracesWaterfallTest do
  @moduledoc "Story 7.1 — Traces waterfall visualization."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "traces page renders with correlation filter input", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/traces")

    assert html =~ "correlation_id"
    assert html =~ "Traces"
  end

  test "traces page has waterfall timeline container", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/traces")

    assert html =~ "trace-waterfall"
  end

  test "filtering by correlation_id updates the view", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/traces")

    html =
      lv
      |> element("#trace-filter-form")
      |> render_change(%{"filter" => %{"signal_type" => "", "correlation_id" => "test-123"}})

    assert html =~ "trace-waterfall"
  end
end
