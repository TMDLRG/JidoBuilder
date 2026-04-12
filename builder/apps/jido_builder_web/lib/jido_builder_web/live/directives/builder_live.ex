defmodule JidoBuilderWeb.Directives.BuilderLive do
  @moduledoc "Phase Final A.1 — interactive directives composer with preview."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.DirectiveEmitter

  @directive_types [
    {"emit", "Emit"},
    {"error", "Error"},
    {"spawn", "Spawn"},
    {"spawn_agent", "SpawnAgent"},
    {"adopt_child", "AdoptChild"},
    {"stop_child", "StopChild"},
    {"schedule", "Schedule"},
    {"run_instruction", "RunInstruction"},
    {"stop", "Stop"},
    {"cron", "Cron"},
    {"cron_cancel", "CronCancel"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Directives Builder",
       directive_types: @directive_types,
       form_data: %{"kind" => "emit"},
       preview: nil,
       error: nil
     )}
  end

  @impl true
  def handle_event("change_kind", %{"directive" => params}, socket) do
    {:noreply, assign(socket, form_data: params, preview: nil, error: nil)}
  end

  @impl true
  def handle_event("preview", %{"directive" => params}, socket) do
    config = normalize(params)

    case DirectiveEmitter.from_config(config) do
      {:ok, directive} ->
        {:noreply, assign(socket, form_data: params, preview: inspect(directive, pretty: true), error: nil)}

      {:error, reason} ->
        {:noreply, assign(socket, form_data: params, preview: nil, error: reason.message)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>
    <p class="text-sm mb-4">Compose directives that agents execute in response to signals.</p>

    <form id="directive-composer" phx-submit="preview" phx-change="change_kind" class="space-y-3 max-w-xl">
      <div>
        <label class="block text-xs font-medium mb-1">Directive type</label>
        <select name="directive[kind]" class="border rounded px-2 py-1 w-full text-sm">
          <option :for={{key, label} <- @directive_types} value={key} selected={@form_data["kind"] == key}>
            <%= label %>
          </option>
        </select>
      </div>

      <div>
        <label class="block text-xs font-medium mb-1">signal_type</label>
        <input type="text" name="directive[signal_type]" value={@form_data["signal_type"]} class="border rounded px-2 py-1 w-full text-sm" />
      </div>

      <div>
        <label class="block text-xs font-medium mb-1">dispatch adapter</label>
        <input type="text" name="directive[dispatch]" value={@form_data["dispatch"]} class="border rounded px-2 py-1 w-full text-sm" />
      </div>

      <div>
        <label class="block text-xs font-medium mb-1">delay_ms</label>
        <input type="number" name="directive[delay_ms]" value={@form_data["delay_ms"]} class="border rounded px-2 py-1 w-full text-sm" />
      </div>

      <div>
        <label class="block text-xs font-medium mb-1">message/tag/reason</label>
        <input type="text" name="directive[tag]" value={@form_data["tag"]} class="border rounded px-2 py-1 w-full text-sm" />
      </div>

      <div>
        <label class="block text-xs font-medium mb-1">agent_module</label>
        <input type="text" name="directive[agent_module]" value={@form_data["agent_module"]} class="border rounded px-2 py-1 w-full text-sm font-mono" />
      </div>

      <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-xs">Preview directive</button>
    </form>

    <div :if={@preview} id="directive-preview" class="mt-6 rounded bg-zinc-50 border p-4 font-mono text-xs whitespace-pre-wrap"><%= @preview %></div>
    <div :if={@error} id="directive-error" class="mt-4 text-sm text-red-600"><%= @error %></div>
    """
  end

  defp normalize(params) do
    kind = Map.get(params, "kind", "")

    base = %{"kind" => kind}

    case kind do
      "emit" -> Map.merge(base, %{"signal_type" => params["signal_type"], "payload" => %{}, "dispatch" => params["dispatch"]})
      "schedule" -> Map.merge(base, %{"delay_ms" => parse_int(params["delay_ms"]), "message" => params["tag"]})
      "spawn_agent" -> Map.merge(base, %{"agent_module" => params["agent_module"], "tag" => params["tag"]})
      "stop_child" -> Map.merge(base, %{"tag" => params["tag"], "reason" => params["tag"] || "normal"})
      "stop" -> Map.merge(base, %{"reason" => params["tag"] || "normal"})
      _ -> base
    end
  end

  defp parse_int(nil), do: 0
  defp parse_int(""), do: 0

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {num, ""} when num >= 0 -> num
      _ -> 0
    end
  end
end
