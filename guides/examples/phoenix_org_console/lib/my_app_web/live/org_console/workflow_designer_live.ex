defmodule MyAppWeb.OrgConsole.WorkflowDesignerLive do
  use MyAppWeb, :live_view

  alias MyAppWeb.OrgConsole.BaseLive
  alias MyAppWeb.OrgConsole.Components.ShellComponents

  @impl true
  def mount(_params, _session, socket) do
    patterns = ["Linear", "Branch", "Fan-out"]

    {:ok,
     socket
     |> BaseLive.init(%{
       title: "Workflow Designer",
       subtitle: "Design linear, branch, and fan-out workflows",
       patterns: patterns,
       selected: "Linear",
       empty: nil
     })}
  end

  @impl true
  def handle_event("toggle_advanced", _params, socket),
    do: {:noreply, BaseLive.toggle_advanced(socket)}

  def handle_event("select_pattern", %{"pattern" => pattern}, socket),
    do: {:noreply, assign(socket, :selected, pattern)}

  def handle_event("delete_template", _params, socket) do
    msg =
      "Deleting this template removes it from future assignments and leaves existing runs unchanged."

    {:noreply, BaseLive.open_confirm(socket, :delete_template, "Delete workflow template?", msg)}
  end

  def handle_event("cancel_confirm", _params, socket),
    do: {:noreply, BaseLive.close_confirm(socket)}

  def handle_event(
        "confirm_action",
        _params,
        %{assigns: %{confirming: %{action: :delete_template}}} = socket
      ) do
    {:noreply, socket |> BaseLive.close_confirm() |> assign(:flash_notice, "Template deleted.")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <ShellComponents.page
      title={@title}
      subtitle={@subtitle}
      loading={@loading}
      error={@error}
      empty={@empty}
      advanced_mode={@advanced_mode}
    >
      <:actions>
        <button type="button" class="rounded border px-3 py-1" phx-click="delete_template">Delete template</button>
      </:actions>

      <div class="flex gap-2">
        <button
          :for={pattern <- @patterns}
          type="button"
          class="rounded border px-3 py-1"
          phx-click="select_pattern"
          phx-value-pattern={pattern}
        >
          <%= pattern %>
        </button>
      </div>

      <p class="text-sm text-slate-700">Selected pattern: <strong><%= @selected %></strong></p>
      <p :if={@flash_notice} class="text-sm text-emerald-700"><%= @flash_notice %></p>
    </ShellComponents.page>

    <ShellComponents.confirm_dialog confirming={@confirming} />
    """
  end
end
