defmodule JidoBuilderWeb.SchedulesLive do
  @moduledoc """
  Phase 3.7 — Schedules: cron create / cancel.

  Manages DB-backed `template_schedules` rows, which the runtime picks up
  via `DynamicPod.config_for_template/1` to register `Jido.Scheduler` jobs.
  The LV provides create (with cron expression + timezone) and cancel
  (sets enabled=false) operations.
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.{Repo, Templates}

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    schedules = Templates.list_template_schedules(workspace_id)
    templates = list_templates_for_workspace(workspace_id)

    {:ok,
     assign(socket,
       page_title: "Schedules",
       workspace_id: workspace_id,
       schedules: schedules,
       templates: templates,
       form_error: nil, toast: nil
     )}
  end

  @impl true
  def handle_event("create_schedule", %{"schedule" => attrs}, socket) do
    workspace_id = socket.assigns.workspace_id
    user = socket.assigns.current_user

    case Templates.create_schedule(attrs, user.email) do
      {:ok, _sched} ->
        schedules = Templates.list_template_schedules(workspace_id)
        {:noreply, assign(socket, schedules: schedules, form_error: nil, toast: nil)}

      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc -> String.replace(acc, "%{#{key}}", to_string(value)) end)
        end) |> Enum.map_join(", ", fn {field, errs} -> "#{field}: #{Enum.join(errs, ", ")}" end)
        {:noreply, assign(socket, form_error: errors)}
    end
  end

  @impl true
  def handle_event("cancel_schedule", %{"id" => id}, socket) do
    workspace_id = socket.assigns.workspace_id
    user = socket.assigns.current_user
    sched = Repo.get!(JidoBuilderCore.Templates.TemplateSchedule, id)
    {:ok, _} = Templates.update_schedule(sched, %{enabled: false}, user.email)
    schedules = Templates.list_template_schedules(workspace_id)
    {:noreply, assign(socket, schedules: schedules)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>
    <.toast :if={@toast} title={@toast.title} message={@toast.message} variant="info" />
    <p class="text-sm text-zinc-500 mb-4">Manage recurring runs and temporal triggers.</p>

    <.card class="mt-4 max-w-lg"><:header>New Schedule</:header>
      <h2 class="text-sm font-semibold mb-2">New Schedule</h2>
      <form id="schedule-form" phx-submit="create_schedule" class="space-y-3">
        <.select_field name="schedule[template_id]" label="Template">
          <option value="">-- select --</option>
          <option :for={tmpl <- @templates} value={tmpl.id}>{tmpl.name}</option>
        </.select_field>
        <.input_field name="schedule[name]" label="Name" placeholder="Heartbeat" />
        <.input_field name="schedule[cron]" label="Cron Expression" placeholder="* * * * *" />
        <.input_field name="schedule[timezone]" label="Timezone" placeholder="UTC" />
        <.button>Create Schedule</.button>
      </form>
      <p :if={@form_error} class="mt-2 text-red-600 text-xs">{@form_error}</p>
    </.card>

    <.card class="mt-8"><:header>Scheduled Jobs</:header>
      <ul id="schedule-list" class="space-y-2 text-sm">
        <li :for={sched <- @schedules} id={"sched-#{sched.id}"} class="flex items-center gap-4 border-b pb-2">
          <span class="font-semibold">{sched.name}</span>
          <span class="font-mono text-xs text-zinc-500">{sched.cron}</span>
          <.badge variant={if sched.enabled, do: "success", else: "default"}>{if sched.enabled, do: "active", else: "cancelled"}</.badge>
          <button
            :if={sched.enabled}
            phx-click="cancel_schedule"
            phx-value-id={sched.id}
            class="text-xs text-red-600 hover:underline"
          >Cancel</button>
        </li>
      </ul>
      <.empty_state :if={@schedules == []} title="No schedules" description="No schedules configured for this workspace." icon="clock" />
    </.card>
    """
  end

  defp list_templates_for_workspace(workspace_id) do
    Templates.list_templates(workspace_id)
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1
end
