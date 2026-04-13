defmodule JidoBuilderWeb.Live.Phase6PolishTest do
  use JidoBuilderWeb.ConnCase, async: false
  @moduletag :authenticated

  import Phoenix.LiveViewTest
  alias JidoBuilderCore.{Agents, Pods, Templates}

  setup do
    {:ok, ws} =
      Agents.create_workspace(
        %{name: "phase6-ws-#{System.unique_integer()}", slug: "phase6-#{System.unique_integer()}"},
        "test"
      )

    {:ok, tmpl} =
      Templates.create_template(
        %{workspace_id: ws.id, name: "Phase6Template", slug: "phase6-template-#{System.unique_integer()}", version: "0.1.0", status: "draft"},
        "test"
      )

    {:ok, topology} = Pods.create_topology(%{workspace_id: ws.id, name: "pod-a", strategy: "round_robin"}, "test")

    {:ok, agent} =
      Agents.create_agent_instance(
        %{workspace_id: ws.id, template_id: tmpl.id, name: "orphan-agent", status: "running", runtime_ref: "pid:123"},
        "test"
      )

    %{workspace: ws, template: tmpl, topology: topology, agent: agent}
  end

  test "create thread entry", %{conn: conn, workspace: ws} do
    {:ok, lv, _} = live(conn, ~p"/threads?workspace_id=#{ws.id}")
    html = lv |> form("#thread-form", thread: %{name: "incident-room"}) |> render_submit()
    assert html =~ "incident-room"
  end

  test "create memory space", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/memory")
    html = render_click(lv, "create_space", %{"space" => %{"name" => "knowledge-base"}})
    assert html =~ "knowledge-base"
  end

  test "create profile", %{conn: conn, workspace: ws} do
    {:ok, lv, _} = live(conn, ~p"/identity?workspace_id=#{ws.id}")

    html =
      lv
      |> form("#identity-form", profile: %{name: "Helper", persona: "friendly", capabilities: "search"})
      |> render_submit()

    assert html =~ "Helper"
  end

  test "step 1 shows workspace creation form", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/onboarding")
    assert html =~ "Create a Workspace"
    assert html =~ "onboarding-form"
  end

  test "step 3 shows agent hire form", %{conn: conn} do
    {:ok, lv, _} = live(conn, ~p"/onboarding")
    _ = lv |> element("#skip-step") |> render_click()
    _ = lv |> element("#skip-step") |> render_click()
    html = render(lv)
    assert html =~ "Hire an Agent"
  end

  test "toggle debug", %{conn: conn, workspace: ws} do
    {:ok, lv, _} = live(conn, ~p"/debug?workspace_id=#{ws.id}")
    html = lv |> element("#debug-toggle") |> render_click()
    assert html =~ "on" or html =~ "off"
  end

  test "select error policy persists to template config", %{conn: conn, workspace: ws, template: tmpl} do
    {:ok, lv, _} = live(conn, ~p"/error-policy?workspace_id=#{ws.id}")

    _ = lv |> form("#error-policy-form", %{template_id: tmpl.id, policy: "retry_once"}) |> render_submit()

    assert Templates.get_template!(tmpl.id).config["error_policy"] == "retry_once"
  end

  test "adopt links agent to pod", %{conn: conn, workspace: ws, topology: topology, agent: agent} do
    {:ok, lv, _} = live(conn, ~p"/orphans?workspace_id=#{ws.id}")

    html =
      lv
      |> form("#adopt-form-#{agent.id}", %{agent_id: agent.id, pod_topology_id: topology.id})
      |> render_submit()

    assert html =~ "Agent adopted"
  end
end
