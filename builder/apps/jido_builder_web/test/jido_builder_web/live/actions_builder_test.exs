defmodule JidoBuilderWeb.Live.ActionsBuilderTest do
  @moduledoc """
  Story 3.2 — Actions builder page shows action catalog with categories.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "actions page renders all registered actions", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/actions")

    assert html =~ "Actions"
    assert html =~ "Echo"
    assert html =~ "HTTP Request"
    assert html =~ "JSON Transform"
    assert html =~ "State Mutation"
    assert html =~ "Webhook Call"
  end

  test "actions page supports category filtering", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/actions")

    # Filter to integration category
    html = lv |> element("[phx-click=filter_category][phx-value-category=integration]") |> render_click()
    assert html =~ "HTTP Request"
    assert html =~ "Webhook Call"
  end

  test "selecting an action shows its detail", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/actions")

    html = lv |> element("[phx-click=select_action][phx-value-slug=echo]") |> render_click()
    assert html =~ "Returns the inbound message payload"
  end
end
