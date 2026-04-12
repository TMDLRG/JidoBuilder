defmodule JidoBuilderWeb.Live.SkillsCatalogTest do
  @moduledoc "Phase 2.6 — Skills catalog renders discovery actions."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "skills index page renders heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/skills")
    assert html =~ "Skills Catalog"
  end
end
