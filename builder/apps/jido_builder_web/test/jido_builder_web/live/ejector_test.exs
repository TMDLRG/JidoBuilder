defmodule JidoBuilderWeb.Live.EjectorTest do
  @moduledoc "Phase 5 — Ejector: export template as standalone Elixir."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "renders Ejector heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ejector")
    assert html =~ "Ejector"
  end

  test "preview renders source", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ejector")

    html =
      lv
      |> form("#ejector-form",
        block: %{type: "action", module: "MyApp.Export", name: "export", description: "exported action"}
      )
      |> render_submit()

    assert html =~ "defmodule" or html =~ "MyApp.Export"
  end

  test "download event fires", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ejector")

    _ =
      lv
      |> form("#ejector-form",
        block: %{type: "action", module: "MyApp.Export", name: "export", description: "exported action"}
      )
      |> render_submit()

    assert render_click(element(lv, "#ejector-download")) =~ "Download source"
  end
end
