defmodule JidoBuilderWeb.Live.SkillsCatalogTest do
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "search filters actions", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/skills")
    html = lv |> form("form", q: "missing-skill-token") |> render_change()
    assert html =~ "No actions match your search"
  end

  test "click shows detail or empty state", %{conn: conn} do
    {:ok, lv, html} = live(conn, ~p"/skills")

    if html =~ "skills-list" and html =~ "<button" do
      detail_html = lv |> element("#skills-list li:first-child button") |> render_click()
      assert detail_html =~ "skill-detail"
    else
      assert html =~ "No actions match your search"
    end
  end
end
