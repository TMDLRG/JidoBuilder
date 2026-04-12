defmodule JidoBuilderWeb.Live.SkillsCatalogTest do
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "search filters actions", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/skills")
    html = lv |> form("form", q: "missing-skill-token") |> render_change()
    assert html =~ "No actions match your search"
  end

  test "click shows detail", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/skills")
    html = lv |> element("#skills-list button") |> render_click()
    assert html =~ "skill-detail"
  end
end
