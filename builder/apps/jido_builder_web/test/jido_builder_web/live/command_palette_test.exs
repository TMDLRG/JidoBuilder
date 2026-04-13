defmodule JidoBuilderWeb.Live.CommandPaletteTest do
  @moduledoc """
  Story 6.1 — Command palette search and navigation.
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/")
    %{lv: lv}
  end

  test "command palette hook is present in layout", %{lv: lv} do
    html = render(lv)
    # The layout has the CommandPalette hook and ⌘K shortcut indicator
    assert html =~ "CommandPalette" or html =~ "command-palette"
  end

  test "command palette opens and shows search results", %{lv: lv} do
    # Toggle palette open
    html = lv |> element("#command-palette-trigger") |> render_click()
    assert html =~ "palette-search" or html =~ "Search"
  end

  test "palette search filters navigation items", %{lv: lv} do
    lv |> element("#command-palette-trigger") |> render_click()
    html = lv |> element("#palette-search-form") |> render_change(%{q: "agent"})
    assert html =~ "Agents"
  end
end
