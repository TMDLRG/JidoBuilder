defmodule JidoBuilderWeb.Assignments.NewLive do
  @moduledoc """
  Phase 1.2 — Assignments Console.

  Lets the operator select a running agent, choose a signal type,
  supply an optional JSON payload, and dispatch a synchronous
  `Jido.AgentServer.call/3` signal.

  7.14 interlock: Hammer rate-limits dispatches to 10 per user per
  minute via an ETS-backed bucket keyed on `user_id`.  The 11th
  attempt within the window assigns an error message without hitting
  the runtime.
  """
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.{Hiring, Roster, Signals}

  @rate_limit_key "assignments:dispatch"
  @rate_limit_scale_ms :timer.minutes(1)
  @rate_limit_max 10

  @impl true
  def mount(params, _session, socket) do
    workspace_id = workspace_id_from_params(params)
    agents = Roster.list(workspace_id)

    {:ok,
     socket
     |> assign(
       page_title: "New Assignment",
       workspace_id: workspace_id,
       agents: agents,
       result: nil,
       error: nil
     )}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event(
        "dispatch",
        %{"dispatch" => %{"target_agent" => target, "signal_type" => sig_type} = params},
        socket
      ) do
    user = socket.assigns.current_user
    workspace_id = socket.assigns.workspace_id
    bucket = "#{@rate_limit_key}:#{user.id}"

    case Hammer.check_rate(bucket, @rate_limit_scale_ms, @rate_limit_max) do
      {:allow, _count} ->
        do_dispatch(socket, workspace_id, user, target, sig_type, params)

      {:deny, _limit} ->
        {:noreply, assign(socket, error: "Too many signals. Try again in 60 seconds.", result: nil)}
    end
  end

  defp do_dispatch(socket, workspace_id, user, target, sig_type, params) do
    payload =
      case Jason.decode(Map.get(params, "payload", "{}")) do
        {:ok, map} when is_map(map) -> map
        _ -> %{}
      end

    context = %{workspace_id: workspace_id, actor: user.email}

    with {:ok, server} <- Hiring.whereis(context, target),
         {:ok, signal} <- Signals.new(context, sig_type, payload),
         :ok <- Signals.cast(context, server, signal) do
      {:noreply, assign(socket, result: "dispatched async — signal enqueued", error: nil)}
    else
      {:error, reason} ->
        {:noreply, assign(socket, error: inspect(reason), result: nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <form id="dispatch-form" phx-submit="dispatch" class="space-y-4 max-w-lg">
      <div>
        <label class="block text-sm font-medium mb-1">Target Agent</label>
        <select name="dispatch[target_agent]" class="border rounded px-2 py-1 w-full text-sm">
          <option value="">— select —</option>
          <option :for={agent <- @agents} value={agent.name}><%= agent.name %></option>
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Signal Type</label>
        <input
          type="text"
          name="dispatch[signal_type]"
          placeholder="e.g. ping"
          class="border rounded px-2 py-1 w-full text-sm"
        />
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Payload (JSON)</label>
        <textarea
          name="dispatch[payload]"
          rows="3"
          placeholder="{}"
          class="border rounded px-2 py-1 w-full text-sm font-mono"
        ></textarea>
      </div>

      <button type="submit" class="rounded bg-zinc-900 px-4 py-2 text-white text-sm">
        Dispatch
      </button>
    </form>

    <div :if={@result} id="dispatch-result" class="mt-6 rounded bg-green-50 border border-green-200 p-4 text-sm">
      <p class="font-semibold mb-1">dispatched — result</p>
      <pre class="font-mono text-xs whitespace-pre-wrap"><%= @result %></pre>
    </div>

    <div :if={@error} id="dispatch-error" class="mt-6 rounded bg-red-50 border border-red-200 p-4 text-sm text-red-700">
      <%= @error %>
    </div>
    """
  end

  defp workspace_id_from_params(%{"workspace_id" => id}) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp workspace_id_from_params(_), do: 1
end
