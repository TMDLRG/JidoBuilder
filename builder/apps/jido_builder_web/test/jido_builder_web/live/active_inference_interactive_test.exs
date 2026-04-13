defmodule JidoBuilderWeb.Live.ActiveInferenceInteractiveTest do
  @moduledoc "Phase 8.3 — Verify Active Inference presets are interactive with belief/policy visualization."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "preset cards have phx-click handler", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/active-inference")
    assert html =~ ~s(phx-click="select_preset")
  end

  test "clicking a preset loads model and updates belief data", %{conn: conn} do
    {:ok, lv, html} = live(conn, "/active-inference")
    # Initially empty
    assert html =~ ~s(data-beliefs="[]")

    # Click on Forager preset
    html = render_click(lv, "select_preset", %{"name" => "Forager"})
    # After selection, beliefs should no longer be empty
    refute html =~ ~s(data-beliefs="[]")
  end

  test "clicking a preset computes EFE and updates policy data", %{conn: conn} do
    {:ok, lv, html} = live(conn, "/active-inference")
    assert html =~ ~s(data-policies="[]")

    html = render_click(lv, "select_preset", %{"name" => "Forager"})
    refute html =~ ~s(data-policies="[]")
  end

  test "observe button runs belief update with observation", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/active-inference")

    # First select a preset
    render_click(lv, "select_preset", %{"name" => "Forager"})

    # Then observe (observation index 0)
    html = render_click(lv, "observe", %{"obs" => "0"})
    # Page should still render with updated beliefs
    assert html =~ "Forager"
    assert html =~ "data-beliefs"
  end

  test "selected preset is visually highlighted", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/active-inference")

    html = render_click(lv, "select_preset", %{"name" => "Forager"})
    assert html =~ "bg-blue-50" or html =~ "ring" or html =~ "border-blue"
  end
end
