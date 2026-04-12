defmodule JidoBuilderWeb.Live.PluginEditorTest do
  @moduledoc "Phase 5 — Plugin editor."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Plugin Editor heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/editor/plugin")
    assert html =~ "Plugin Editor"
  end

  test "preview plugin source", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/editor/plugin")

    html =
      lv
      |> form("#editor-form",
        block: %{module: "MyApp.ChatPlugin", name: "chat", description: "chat plugin"}
      )
      |> render_submit()

    assert html =~ "defmodule" or html =~ "MyApp.ChatPlugin"
  end
end
