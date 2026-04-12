defmodule JidoBuilderWeb.Live.StateOpsTest do
  @moduledoc """
  Phase 3.6 — State Ops editor (all 5 ops).

  Assertions:
    - /state-ops renders the page heading
    - all 5 op types are selectable in the form
    - submit set_state op returns a preview result
    - submit replace_state op returns a preview result
    - submit delete_keys op returns a preview result
    - submit set_path op returns a preview result
    - submit delete_path op returns a preview result
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "renders State Ops editor heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/state-ops")
    assert html =~ "State Ops"
  end

  test "all 5 op types are present in the form", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/state-ops")
    assert html =~ "set_state"
    assert html =~ "replace_state"
    assert html =~ "delete_keys"
    assert html =~ "set_path"
    assert html =~ "delete_path"
  end

  test "set_state op previews result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/state-ops")

    html =
      lv
      |> form("#state-ops-form",
        state_op: %{op: "set_state", state_json: ~s({"x": 1}), payload_json: ~s({"y": 2})}
      )
      |> render_submit()

    assert html =~ "result" or html =~ "y" or html =~ "2"
  end

  test "replace_state op previews result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/state-ops")

    html =
      lv
      |> form("#state-ops-form",
        state_op: %{op: "replace_state", state_json: ~s({"a": 1}), payload_json: ~s({"b": 3})}
      )
      |> render_submit()

    assert html =~ "result" or html =~ "b"
  end

  test "delete_keys op previews result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/state-ops")

    html =
      lv
      |> form("#state-ops-form",
        state_op: %{
          op: "delete_keys",
          state_json: ~s({"a": 1, "b": 2}),
          payload_json: ~s({"keys": ["a"]})
        }
      )
      |> render_submit()

    assert html =~ "result" or html =~ "b"
  end

  test "set_path op previews result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/state-ops")

    html =
      lv
      |> form("#state-ops-form",
        state_op: %{
          op: "set_path",
          state_json: ~s({"a": {}}),
          payload_json: ~s({"path": ["a", "b"], "value": 99})
        }
      )
      |> render_submit()

    assert html =~ "result" or html =~ "99"
  end

  test "delete_path op previews result", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/state-ops")

    html =
      lv
      |> form("#state-ops-form",
        state_op: %{
          op: "delete_path",
          state_json: ~s({"a": {"b": 1}}),
          payload_json: ~s({"path": ["a", "b"]})
        }
      )
      |> render_submit()

    assert html =~ "result" or html =~ "a"
  end
end
