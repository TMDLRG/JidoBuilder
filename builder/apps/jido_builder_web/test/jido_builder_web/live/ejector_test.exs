defmodule JidoBuilderWeb.Live.EjectorTest do
  @moduledoc "Phase 5 — Ejector: export template as standalone Elixir."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Ejector heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/ejector")
    assert html =~ "Ejector"
  end

  test "export preview for action block", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ejector")

    html =
      lv
      |> form("#ejector-form",
        block: %{type: "action", module: "MyApp.Export", name: "export", description: "exported action"}
      )
      |> render_submit()

    assert html =~ "defmodule" or html =~ "MyApp.Export"
  end
end
