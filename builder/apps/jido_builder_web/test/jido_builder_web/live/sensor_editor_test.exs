defmodule JidoBuilderWeb.Live.SensorEditorTest do
  @moduledoc "Phase 5 — Sensor editor."
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated
  import Phoenix.LiveViewTest

  test "renders Sensor Editor heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/editor/sensor")
    assert html =~ "Sensor Editor"
  end

  test "preview sensor source", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/editor/sensor")

    html =
      lv
      |> form("#editor-form",
        block: %{module: "MyApp.TempSensor", name: "temp", description: "reads temperature"}
      )
      |> render_submit()

    assert html =~ "defmodule" or html =~ "MyApp.TempSensor"
  end
end
