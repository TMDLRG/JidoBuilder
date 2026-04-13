defmodule JidoBuilderWeb.MemoryLive do
  @moduledoc "Memory Spaces — backed by real ETS-based MemoryStore."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.MemoryStore

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Memory Spaces",
       spaces: MemoryStore.list_spaces(),
       selected_space: nil,
       entries: [],
       search_query: "",
       write_result: nil
     )}
  end

  @impl true
  def handle_event("create_space", %{"space" => %{"name" => name}}, socket) when byte_size(name) > 0 do
    # Write a placeholder entry to create the space
    MemoryStore.write(name, "_created", DateTime.to_string(DateTime.utc_now()))

    {:noreply,
     assign(socket,
       spaces: MemoryStore.list_spaces(),
       selected_space: name,
       entries: MemoryStore.list_entries(name)
     )}
  end

  def handle_event("create_space", _params, socket), do: {:noreply, socket}

  def handle_event("select_space", %{"name" => name}, socket) do
    {:noreply,
     assign(socket,
       selected_space: name,
       entries: MemoryStore.list_entries(name),
       search_query: ""
     )}
  end

  def handle_event("write_entry", %{"entry" => %{"key" => key, "value" => value}}, socket)
      when byte_size(key) > 0 do
    space = socket.assigns.selected_space

    if space do
      MemoryStore.write(space, key, value)

      {:noreply,
       assign(socket,
         entries: MemoryStore.list_entries(space),
         write_result: "Written: #{key} = #{value}"
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("write_entry", _params, socket), do: {:noreply, socket}

  def handle_event("delete_entry", %{"key" => key}, socket) do
    space = socket.assigns.selected_space

    if space do
      MemoryStore.delete(space, key)
      {:noreply, assign(socket, entries: MemoryStore.list_entries(space))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("search", %{"q" => query}, socket) do
    space = socket.assigns.selected_space

    entries =
      if space do
        if query == "", do: MemoryStore.list_entries(space), else: MemoryStore.search(space, query)
      else
        []
      end

    {:noreply, assign(socket, entries: entries, search_query: query)}
  end

  def handle_event("clear_space", _params, socket) do
    space = socket.assigns.selected_space

    if space do
      MemoryStore.clear_space(space)

      {:noreply,
       assign(socket,
         spaces: MemoryStore.list_spaces(),
         selected_space: nil,
         entries: []
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>{@page_title}</.page_header>

    <section class="grid md:grid-cols-3 gap-4">
      <div class="space-y-4">
        <.card>
          <:header>Create Space</:header>
          <form phx-submit="create_space" class="flex gap-2">
            <input type="text" name="space[name]" placeholder="research" class="ui-input flex-1" autocomplete="off" />
            <.button>Create</.button>
          </form>
        </.card>

        <.card>
          <:header>Spaces ({length(@spaces)})</:header>
          <ul class="space-y-1">
            <li
              :for={space <- @spaces}
              phx-click="select_space"
              phx-value-name={space}
              class={"p-2 rounded cursor-pointer text-sm transition-colors #{if @selected_space == space, do: "bg-blue-50 border border-blue-300 font-semibold", else: "hover:bg-zinc-50 border border-transparent"}"}
            >
              {space}
              <span class="text-xs text-zinc-400 ml-1">({length(MemoryStore.list_entries(space))} entries)</span>
            </li>
          </ul>
          <.empty_state :if={@spaces == []} title="No memory spaces" description="Create a space to start storing data." icon="circle_stack" />
        </.card>
      </div>

      <div class="md:col-span-2 space-y-4">
        <.card :if={@selected_space}>
          <:header>Write to "{@selected_space}"</:header>
          <form phx-submit="write_entry" class="grid grid-cols-3 gap-2">
            <input type="text" name="entry[key]" placeholder="key" class="ui-input" autocomplete="off" />
            <input type="text" name="entry[value]" placeholder="value" class="ui-input" autocomplete="off" />
            <.button>Write</.button>
          </form>
          <p :if={@write_result} class="text-xs text-green-600 mt-1">{@write_result}</p>
        </.card>

        <.card :if={@selected_space}>
          <:header>
            Entries in "{@selected_space}"
            <form phx-change="search" class="inline ml-4">
              <input type="text" name="q" value={@search_query} placeholder="Search keys..." class="ui-input text-xs w-48" phx-debounce="200" />
            </form>
          </:header>
          <table class="w-full text-sm">
            <thead>
              <tr class="text-left text-xs text-zinc-500 border-b">
                <th class="py-1 px-2">Key</th>
                <th class="py-1 px-2">Value</th>
                <th class="py-1 px-2 w-16"></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={entry <- @entries} class="border-b hover:bg-zinc-50">
                <td class="py-1.5 px-2 font-mono text-xs">{entry.key}</td>
                <td class="py-1.5 px-2 text-xs">{entry.value}</td>
                <td class="py-1.5 px-2">
                  <button phx-click="delete_entry" phx-value-key={entry.key} class="text-red-500 hover:text-red-700 text-xs">Delete</button>
                </td>
              </tr>
            </tbody>
          </table>
          <.empty_state :if={@entries == []} title="No entries" description="Write a key-value pair to populate this space." icon="document" />
          <div class="mt-3 pt-2 border-t">
            <button phx-click="clear_space" class="text-xs text-red-500 hover:text-red-700" data-confirm="Clear all entries in this space?">Clear Space</button>
          </div>
        </.card>

        <.card :if={!@selected_space}>
          <.empty_state title="Select a space" description="Click a memory space on the left to view and manage its entries." icon="arrow_path" />
        </.card>
      </div>
    </section>
    """
  end
end
