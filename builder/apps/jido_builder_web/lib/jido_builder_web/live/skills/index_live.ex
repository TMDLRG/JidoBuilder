defmodule JidoBuilderWeb.Skills.IndexLive do
  @moduledoc "Phase Final A.8 — Skills catalog with search/filter/detail."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Discovery

  @impl true
  def mount(_params, _session, socket) do
    context = %{workspace_id: 1, actor: "web"}
    actions = case Discovery.list_actions(context) do {:ok, list} -> list; _ -> [] end

    {:ok,
     assign(socket,
       page_title: "Skills Catalog",
       actions: actions,
       filtered: actions,
       query: "",
       selected: nil
     )}
  end

  @impl true
  def handle_event("filter", %{"q" => query}, socket) do
    q = String.downcase(String.trim(query || ""))

    filtered =
      Enum.filter(socket.assigns.actions, fn action ->
        inspect(action)
        |> String.downcase()
        |> String.contains?(q)
      end)

    {:noreply, assign(socket, query: query, filtered: filtered)}
  end

  def handle_event("select", %{"idx" => idx}, socket) do
    index = String.to_integer(idx)
    {:noreply, assign(socket, selected: Enum.at(socket.assigns.filtered, index))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header><%= @page_title %></.page_header>

    <form phx-change="filter" class="my-3 max-w-md">
      <input type="text" name="q" value={@query} placeholder="Search actions" class="border rounded px-2 py-1 w-full text-sm" />
    </form>

    <ul id="skills-list" class="space-y-2 text-sm">
      <li :for={{action, idx} <- Enum.with_index(@filtered)} class="border-b pb-2">
        <button type="button" phx-click="select" phx-value-idx={idx} class="text-left w-full">
          <span class="font-semibold"><%= action_name(action) %></span>
        </button>
      </li>
    </ul>

    <p :if={@filtered == []} class="text-sm text-zinc-500 mt-4">No actions match your search.</p>

    <div :if={@selected} id="skill-detail" class="mt-6 rounded border p-3 text-xs font-mono whitespace-pre-wrap"><%= inspect(@selected, pretty: true) %></div>
    """
  end

  defp action_name(action) when is_map(action) do
    Map.get(action, :name) || Map.get(action, "name") || inspect(action)
  end

  defp action_name(action), do: inspect(action)
end
