defmodule JidoBuilderWeb.LlmAgentWizardLive do
  @moduledoc """
  Multi-step wizard for creating LLM-backed Jido agents.

  Steps:
  1. Template basics (name, description)
  2. LLM config (provider, model, system prompt, temperature)
  3. Tool selection (action whitelist)
  4. Review & create
  """
  use JidoBuilderWeb, :live_view

  import Ecto.Query

  alias JidoBuilderCore.{Repo, Templates.Template, Templates.TemplateLlmConfig}
  alias JidoBuilderRuntime.ActionRegistry

  @providers ["anthropic", "openai", "mock"]
  @models_by_provider %{
    "anthropic" => ["claude-sonnet-4-20250514", "claude-haiku-4-5-20251001"],
    "openai" => ["gpt-4", "gpt-4o", "gpt-3.5-turbo"],
    "mock" => ["mock-model-v1"]
  }

  @impl true
  def mount(_params, _session, socket) do
    actions_by_category =
      ActionRegistry.list()
      |> Enum.reject(fn a -> a.slug == "llm_chat" end)
      |> Enum.group_by(& &1.category)
      |> Enum.sort_by(fn {cat, _} -> to_string(cat) end)

    {:ok,
     assign(socket,
       page_title: "Create LLM Agent",
       step: 1,
       # Step 1: Template
       name: "",
       description: "",
       # Step 2: LLM Config
       providers: @providers,
       selected_provider: "anthropic",
       model_options: @models_by_provider["anthropic"],
       selected_model: hd(@models_by_provider["anthropic"]),
       temperature: "0.7",
       max_tokens: "1024",
       system_prompt: "You are a helpful Jido agent.",
       # Step 3: Tools
       actions_by_category: actions_by_category,
       tool_whitelist: MapSet.new(),
       # State
       error: nil,
       created: false
     )}
  end

  @impl true
  def handle_event("next", _params, %{assigns: %{step: 1}} = socket) do
    if String.trim(socket.assigns.name) == "" do
      {:noreply, assign(socket, error: "Name is required")}
    else
      {:noreply, assign(socket, step: 2, error: nil)}
    end
  end

  def handle_event("next", _params, %{assigns: %{step: 2}} = socket) do
    {:noreply, assign(socket, step: 3, error: nil)}
  end

  def handle_event("next", _params, %{assigns: %{step: 3}} = socket) do
    {:noreply, assign(socket, step: 4, error: nil)}
  end

  def handle_event("back", _params, socket) do
    {:noreply, assign(socket, step: max(1, socket.assigns.step - 1), error: nil)}
  end

  def handle_event("update_field", params, socket) do
    updates =
      params
      |> Enum.filter(fn {k, _v} -> k in ~w(name description system_prompt temperature max_tokens) end)
      |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)

    socket = Enum.reduce(updates, socket, fn {k, v}, s -> assign(s, [{k, v}]) end)

    # Handle provider change
    socket =
      case params["selected_provider"] do
        nil -> socket
        provider ->
          model_options = @models_by_provider[provider] || []
          assign(socket,
            selected_provider: provider,
            model_options: model_options,
            selected_model: List.first(model_options)
          )
      end

    socket =
      case params["selected_model"] do
        nil -> socket
        model -> assign(socket, selected_model: model)
      end

    {:noreply, assign(socket, error: nil)}
  end

  def handle_event("toggle_tool", %{"slug" => slug}, socket) do
    whitelist = socket.assigns.tool_whitelist
    whitelist = if MapSet.member?(whitelist, slug), do: MapSet.delete(whitelist, slug), else: MapSet.put(whitelist, slug)
    {:noreply, assign(socket, tool_whitelist: whitelist)}
  end

  def handle_event("create_agent", _params, socket) do
    slug = socket.assigns.name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")

    workspace = Repo.one(from w in JidoBuilderCore.Agents.Workspace, limit: 1)
    workspace_id = if workspace, do: workspace.id, else: 1

    Repo.transaction(fn ->
      # 1. Create template
      template_attrs = %{
        name: socket.assigns.name,
        slug: slug,
        description: socket.assigns.description,
        status: "active",
        version: "1.0.0",
        workspace_id: workspace_id
      }

      template =
        %Template{}
        |> Template.changeset(template_attrs)
        |> Repo.insert!()

      # 2. Create LLM config
      llm_attrs = %{
        template_id: template.id,
        provider: socket.assigns.selected_provider,
        model: socket.assigns.selected_model,
        temperature: parse_float(socket.assigns.temperature),
        max_tokens: parse_int(socket.assigns.max_tokens),
        system_prompt: socket.assigns.system_prompt,
        tool_whitelist: MapSet.to_list(socket.assigns.tool_whitelist)
      }

      %TemplateLlmConfig{}
      |> TemplateLlmConfig.changeset(llm_attrs)
      |> Repo.insert!()

      # 3. Create chat route
      alias JidoBuilderCore.Templates.TemplateRoute

      %TemplateRoute{}
      |> TemplateRoute.changeset(%{
        template_id: template.id,
        signal: "jido.chat.message",
        action: "llm_chat",
        target: "self",
        opts: %{}
      })
      |> Repo.insert!()

      template
    end)
    |> case do
      {:ok, _template} ->
        {:noreply, assign(socket, created: true)}

      {:error, reason} ->
        {:noreply, assign(socket, error: "Failed to create: #{inspect(reason)}")}
    end
  end

  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error -> 0.7
    end
  end
  defp parse_float(_), do: 0.7

  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> 1024
    end
  end
  defp parse_int(_), do: 1024

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Create LLM Agent</.page_header>

    <div :if={@created} class="mt-6 p-6 border rounded bg-green-50 text-center">
      <h2 class="text-lg font-semibold text-green-800 mb-2">Agent Created!</h2>
      <p class="text-sm text-green-700 mb-4">Your LLM agent "{@name}" is ready.</p>
      <div class="flex justify-center gap-3">
        <.link navigate={~p"/roster"} class="bg-zinc-800 text-white px-4 py-2 rounded text-sm hover:bg-zinc-700">View Agents</.link>
        <.link navigate={~p"/llm-config"} class="bg-blue-600 text-white px-4 py-2 rounded text-sm hover:bg-blue-500">Configure LLM</.link>
      </div>
    </div>

    <div :if={!@created} class="mt-4">
      <%!-- Progress bar --%>
      <div class="flex gap-1 mb-6">
        <div :for={i <- 1..4} class={"h-1.5 flex-1 rounded #{if i <= @step, do: "bg-green-500", else: "bg-zinc-200"}"}></div>
      </div>

      <p :if={@error} class="text-sm text-red-600 mb-3">{@error}</p>

      <%!-- Step 1: Template Basics --%>
      <div :if={@step == 1} class="max-w-lg">
        <h2 class="text-lg font-semibold mb-4">Step 1: Agent Identity</h2>
        <form phx-change="update_field" class="space-y-3">
          <div>
            <label class="text-sm font-semibold block mb-1">Agent Name</label>
            <input type="text" value={@name} name="name" class="w-full border rounded p-2 text-sm" placeholder="My Research Agent" />
          </div>
          <div>
            <label class="text-sm font-semibold block mb-1">Description</label>
            <textarea name="description" class="w-full border rounded p-2 text-sm h-20" placeholder="What does this agent do?">{@description}</textarea>
          </div>
        </form>
      </div>

      <%!-- Step 2: LLM Config --%>
      <div :if={@step == 2} class="max-w-lg">
        <h2 class="text-lg font-semibold mb-4">Step 2: LLM Configuration</h2>
        <form phx-change="update_field" class="space-y-3">
          <div>
            <label class="text-sm font-semibold block mb-1">Provider</label>
            <select name="selected_provider" class="w-full border rounded p-2 text-sm">
              <option :for={p <- @providers} value={p} selected={p == @selected_provider}>{p}</option>
            </select>
          </div>
          <div>
            <label class="text-sm font-semibold block mb-1">Model</label>
            <select name="selected_model" class="w-full border rounded p-2 text-sm">
              <option :for={m <- @model_options} value={m} selected={m == @selected_model}>{m}</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-sm font-semibold block mb-1">Temperature</label>
              <input type="number" name="temperature" value={@temperature} step="0.1" min="0" max="2" class="w-full border rounded p-2 text-sm" />
            </div>
            <div>
              <label class="text-sm font-semibold block mb-1">Max Tokens</label>
              <input type="number" name="max_tokens" value={@max_tokens} step="256" min="1" class="w-full border rounded p-2 text-sm" />
            </div>
          </div>
          <div>
            <label class="text-sm font-semibold block mb-1">System Prompt</label>
            <textarea name="system_prompt" class="w-full border rounded p-2 text-sm h-32 font-mono">{@system_prompt}</textarea>
          </div>
        </form>
      </div>

      <%!-- Step 3: Tool Selection --%>
      <div :if={@step == 3}>
        <h2 class="text-lg font-semibold mb-2">Step 3: Select Tools</h2>
        <p class="text-xs text-zinc-500 mb-4">Choose which actions your LLM agent can invoke. {MapSet.size(@tool_whitelist)} selected.</p>
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-x-4 gap-y-1 border rounded p-4">
          <div :for={{category, actions} <- @actions_by_category} class="mb-3">
            <h4 class="text-xs font-semibold text-zinc-500 uppercase mb-1">{category}</h4>
            <label :for={a <- actions} class="flex items-center gap-1.5 text-xs py-0.5 cursor-pointer hover:bg-zinc-50 rounded px-1">
              <input type="checkbox" checked={MapSet.member?(@tool_whitelist, a.slug)} phx-click="toggle_tool" phx-value-slug={a.slug} class="rounded border-zinc-300" />
              <span>{a.name}</span>
            </label>
          </div>
        </div>
      </div>

      <%!-- Step 4: Review --%>
      <div :if={@step == 4} class="max-w-lg">
        <h2 class="text-lg font-semibold mb-4">Step 4: Review & Create</h2>
        <div class="border rounded p-4 space-y-3 text-sm">
          <div><span class="font-semibold">Name:</span> {@name}</div>
          <div><span class="font-semibold">Description:</span> {@description}</div>
          <div><span class="font-semibold">Provider:</span> {@selected_provider} / {@selected_model}</div>
          <div><span class="font-semibold">Temperature:</span> {@temperature} | <span class="font-semibold">Max Tokens:</span> {@max_tokens}</div>
          <div><span class="font-semibold">System Prompt:</span> <span class="text-zinc-500 font-mono text-xs">{String.slice(@system_prompt, 0, 100)}{if String.length(@system_prompt) > 100, do: "...", else: ""}</span></div>
          <div><span class="font-semibold">Tools:</span> {MapSet.size(@tool_whitelist)} action(s) whitelisted</div>
        </div>
      </div>

      <%!-- Navigation --%>
      <div class="flex justify-between mt-6">
        <button :if={@step > 1} phx-click="back" class="text-sm text-zinc-600 hover:text-zinc-800">Back</button>
        <span :if={@step == 1}></span>
        <button :if={@step < 4} phx-click="next" class="bg-zinc-800 text-white px-4 py-2 rounded text-sm hover:bg-zinc-700">Next</button>
        <button :if={@step == 4} phx-click="create_agent" class="bg-green-600 text-white px-4 py-2 rounded text-sm hover:bg-green-500">Create Agent</button>
      </div>

      <p class="text-xs text-zinc-400 mt-4">Step {@step} of 4</p>
    </div>
    """
  end
end
