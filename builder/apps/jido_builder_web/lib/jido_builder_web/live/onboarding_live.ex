defmodule JidoBuilderWeb.OnboardingLive do
  @moduledoc "Story 6.5 — Interactive onboarding wizard with real actions."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.{Agents, Templates}
  alias JidoBuilderRuntime.Roster

  @total_steps 4

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Onboarding",
       step: 1,
       completed: false,
       workspace: nil,
       template: nil,
       agent: nil,
       form_error: nil
     )}
  end

  @impl true
  def handle_event("submit_step", %{"onboarding" => params}, socket) do
    case socket.assigns.step do
      1 -> handle_step1(socket, params)
      2 -> handle_step2(socket, params)
      3 -> handle_step3(socket, params)
      4 -> handle_step4(socket, params)
      _ -> {:noreply, socket}
    end
  end

  def handle_event("skip_step", _params, socket) do
    next = socket.assigns.step + 1

    if next > @total_steps do
      {:noreply, assign(socket, completed: true)}
    else
      {:noreply, assign(socket, step: next, form_error: nil)}
    end
  end

  def handle_event("prev", _params, socket) do
    {:noreply, assign(socket, step: max(socket.assigns.step - 1, 1))}
  end

  defp handle_step1(socket, %{"workspace_name" => name}) when byte_size(name) > 0 do
    slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")
    actor = socket.assigns.current_user.email

    case Agents.create_workspace(%{name: name, slug: slug}, actor) do
      {:ok, workspace} ->
        {:noreply, assign(socket, step: 2, workspace: workspace, form_error: nil)}

      {:error, err} ->
        {:noreply, assign(socket, form_error: inspect(err))}
    end
  end

  defp handle_step1(socket, _params) do
    {:noreply, assign(socket, form_error: "Workspace name is required")}
  end

  defp handle_step2(socket, %{"template_name" => name}) when byte_size(name) > 0 do
    workspace = socket.assigns.workspace

    if workspace do
      actor = socket.assigns.current_user.email
      slug = name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")

      case Templates.create_template(
             %{"name" => name, "slug" => slug, "workspace_id" => workspace.id, "status" => "active"},
             actor
           ) do
        {:ok, template} ->
          {:noreply, assign(socket, step: 3, template: template, form_error: nil)}

        {:error, err} ->
          {:noreply, assign(socket, form_error: inspect(err))}
      end
    else
      {:noreply, assign(socket, step: 3, form_error: nil)}
    end
  end

  defp handle_step2(socket, _params) do
    {:noreply, assign(socket, form_error: "Template name is required")}
  end

  defp handle_step3(socket, %{"agent_name" => name}) when byte_size(name) > 0 do
    workspace = socket.assigns.workspace
    template = socket.assigns.template

    if workspace do
      actor = socket.assigns.current_user.email
      opts = if template, do: [template_id: template.id], else: []

      case Roster.hire(workspace.id, name, actor, opts) do
        {:ok, agent} ->
          {:noreply, assign(socket, step: 4, agent: agent, form_error: nil)}

        {:error, err} ->
          {:noreply, assign(socket, form_error: inspect(err))}
      end
    else
      {:noreply, assign(socket, step: 4, form_error: nil)}
    end
  end

  defp handle_step3(socket, _params) do
    {:noreply, assign(socket, form_error: "Agent name is required")}
  end

  defp handle_step4(socket, _params) do
    {:noreply, assign(socket, completed: true, form_error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Welcome to JidoBuilder</.page_header>

    <div class="max-w-lg mx-auto mt-6">
      <%!-- Progress bar --%>
      <div class="flex items-center gap-1 mb-6">
        <div :for={i <- 1..4} class={"h-1.5 flex-1 rounded " <> if(i <= @step || @completed, do: "bg-emerald-500", else: "bg-zinc-200")}></div>
      </div>

      <p :if={@form_error} class="mb-4 text-sm text-red-600">{@form_error}</p>

      <%!-- Completed state --%>
      <div :if={@completed}>
        <.card>
          <:header>All Done! Setup complete.</:header>
          <p class="text-sm text-zinc-600 mb-4">Your workspace is ready. Start building with Jido!</p>
          <div class="flex gap-2">
            <.link navigate={~p"/"} class="ui-btn primary">Go to Dashboard</.link>
            <.link navigate={~p"/roster"} class="ui-btn secondary">View Agents</.link>
          </div>
        </.card>
      </div>

      <%!-- Step 1: Create Workspace --%>
      <.card :if={@step == 1 && !@completed}>
        <:header>Step 1: Create a Workspace</:header>
        <p class="text-sm text-zinc-600 mb-4">Workspaces isolate agents, templates, and secrets.</p>
        <form id="onboarding-form" phx-submit="submit_step" class="space-y-3">
          <.input_field name="onboarding[workspace_name]" label="Workspace Name" value="" />
          <div class="flex gap-2">
            <.button>Create Workspace</.button>
            <button type="button" id="skip-step" phx-click="skip_step" class="ui-btn secondary">Skip</button>
          </div>
        </form>
      </.card>

      <%!-- Step 2: Create Template --%>
      <.card :if={@step == 2 && !@completed}>
        <:header>Step 2: Define a Template</:header>
        <p class="text-sm text-zinc-600 mb-4">Templates are agent blueprints with routes and state fields.</p>
        <form id="onboarding-form" phx-submit="submit_step" class="space-y-3">
          <.input_field name="onboarding[template_name]" label="Template Name" value="" />
          <div class="flex gap-2">
            <.button>Create Template</.button>
            <button type="button" id="skip-step" phx-click="skip_step" class="ui-btn secondary">Skip</button>
          </div>
        </form>
      </.card>

      <%!-- Step 3: Hire Agent --%>
      <.card :if={@step == 3 && !@completed}>
        <:header>Step 3: Hire an Agent</:header>
        <p class="text-sm text-zinc-600 mb-4">Start an agent instance from your template.</p>
        <form id="onboarding-form" phx-submit="submit_step" class="space-y-3">
          <.input_field name="onboarding[agent_name]" label="Agent Name" value="" />
          <div class="flex gap-2">
            <.button>Hire Agent</.button>
            <button type="button" id="skip-step" phx-click="skip_step" class="ui-btn secondary">Skip</button>
          </div>
        </form>
      </.card>

      <%!-- Step 4: Send Signal --%>
      <.card :if={@step == 4 && !@completed}>
        <:header>Step 4: Send a Signal</:header>
        <p class="text-sm text-zinc-600 mb-4">Dispatch a signal to your running agent to test it.</p>
        <form id="onboarding-form" phx-submit="submit_step" class="space-y-3">
          <p class="text-xs text-zinc-500">You can dispatch signals from the Assignments page after completing onboarding.</p>
          <div class="flex gap-2">
            <.button>Complete Setup</.button>
            <button type="button" id="skip-step" phx-click="skip_step" class="ui-btn secondary">Skip</button>
          </div>
        </form>
      </.card>

      <span :if={!@completed} class="text-xs text-zinc-400 mt-3 inline-block">Step {@step} of 4</span>
    </div>
    """
  end
end
