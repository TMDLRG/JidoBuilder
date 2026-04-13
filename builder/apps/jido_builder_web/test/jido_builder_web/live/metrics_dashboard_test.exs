defmodule JidoBuilderWeb.Live.MetricsDashboardTest do
  @moduledoc "Story 7.4 — Metrics Dashboard renders with chart containers."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  describe "MetricsLive" do
    test "page renders with chart containers", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/metrics-dashboard")

      assert html =~ "Metrics Dashboard"
      assert html =~ "signals-chart"
      assert html =~ "errors-chart"
    end

    test "page contains stat cards", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/metrics-dashboard")

      assert html =~ "Signals (24h)"
      assert html =~ "Errors (24h)"
    end
  end
end
