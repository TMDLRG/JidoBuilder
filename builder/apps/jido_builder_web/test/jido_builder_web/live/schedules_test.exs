defmodule JidoBuilderWeb.Live.SchedulesTest do
  @moduledoc """
  Phase 3.7 — Schedules: cron create / cancel via Jido.Scheduler.

  Assertions:
    - /schedules renders the heading
    - create form inserts a template_schedules row
    - the created schedule appears in the list
    - cancel sets enabled=false on the schedule row
  """
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias JidoBuilderCore.{Agents, Repo, Templates}
  alias JidoBuilderCore.Templates.TemplateSchedule

  setup do
    {:ok, workspace} =
      Agents.create_workspace(
        %{
          name: "sched-ws-#{System.unique_integer()}",
          slug: "sched-#{System.unique_integer()}"
        },
        "test"
      )

    {:ok, template} =
      Templates.create_template(
        %{
          workspace_id: workspace.id,
          name: "SchedTemplate",
          slug: "sched-tmpl-#{System.unique_integer()}",
          version: "0.1.0",
          status: "draft"
        },
        "test"
      )

    %{workspace: workspace, template: template}
  end

  test "renders Schedules heading", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/schedules")
    assert html =~ "Schedules"
  end

  test "create schedule form inserts template_schedules row", %{
    conn: conn,
    workspace: ws,
    template: tmpl
  } do
    {:ok, lv, _html} = live(conn, ~p"/schedules?workspace_id=#{ws.id}")

    html =
      lv
      |> form("#schedule-form",
        schedule: %{
          template_id: tmpl.id,
          name: "Heartbeat",
          cron: "* * * * *",
          timezone: "UTC"
        }
      )
      |> render_submit()

    assert html =~ "Heartbeat"

    assert Repo.exists?(
             from s in TemplateSchedule,
               where: s.template_id == ^tmpl.id and s.name == "Heartbeat"
           )
  end

  test "lists existing schedules for workspace", %{
    conn: conn,
    workspace: ws,
    template: tmpl
  } do
    {:ok, _} =
      Templates.create_schedule(
        %{template_id: tmpl.id, name: "DailySweep", cron: "@daily"},
        "test"
      )

    {:ok, _lv, html} = live(conn, ~p"/schedules?workspace_id=#{ws.id}")
    assert html =~ "DailySweep"
  end

  test "cancel schedule sets enabled=false", %{
    conn: conn,
    workspace: ws,
    template: tmpl
  } do
    {:ok, sched} =
      Templates.create_schedule(
        %{template_id: tmpl.id, name: "Cancellable", cron: "*/5 * * * *"},
        "test"
      )

    {:ok, lv, _html} = live(conn, ~p"/schedules?workspace_id=#{ws.id}")

    html =
      lv
      |> element("[phx-click='cancel_schedule'][phx-value-id='#{sched.id}']")
      |> render_click()

    updated = Repo.get(TemplateSchedule, sched.id)
    assert updated.enabled == false
    assert html =~ "cancelled" or html =~ "Cancellable"
  end
end
