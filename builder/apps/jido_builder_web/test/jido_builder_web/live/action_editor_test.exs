defmodule JidoBuilderWeb.Live.ActionEditorTest do
  @moduledoc "Phase 5 — Action editor."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Action Editor heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/editor/action")
    assert html =~ "Action Editor"
  end

  test "preview action source", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/editor/action")

    html =
      lv
      |> form("#editor-form",
        block: %{module: "MyApp.PingAction", name: "ping", description: "sends a ping"}
      )
      |> render_submit()

    assert html =~ "defmodule" or html =~ "MyApp.PingAction"
  end
end
