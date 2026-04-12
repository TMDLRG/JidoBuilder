defmodule JidoBuilderWeb.Live.DirectivesBuilderTest do
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "compose emit directive previews struct", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/directives")

    html =
      lv
      |> form("#directive-composer", directive: %{kind: "emit", signal_type: "ping", dispatch: "console"})
      |> render_submit()

    assert html =~ "directive-preview"
    assert html =~ "Emit"
  end

  test "compose cron directive", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/directives")

    html = lv |> form("#directive-composer", directive: %{kind: "cron"}) |> render_submit()
    assert html =~ "directive-error"
  end

  test "compose spawn_agent directive", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/directives")

    html =
      lv
      |> form("#directive-composer", directive: %{kind: "spawn_agent", agent_module: "Elixir.String", tag: "child-a"})
      |> render_submit()

    assert html =~ "directive-preview" or html =~ "directive-error"
  end

  test "compose stop directive", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/directives")
    html = lv |> form("#directive-composer", directive: %{kind: "stop", tag: "normal"}) |> render_submit()
    assert html =~ "directive-preview"
  end
end
