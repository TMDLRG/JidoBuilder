defmodule JidoBuilderWeb.ActiveInferenceLive do
  @moduledoc "Active Inference model visualization and belief state display."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.ActiveInference.PresetModels
  alias Jido.ActiveInference.{BeliefState, FreeEnergy}

  @impl true
  def mount(_params, _session, socket) do
    presets = PresetModels.list()

    {:ok,
     assign(socket,
       page_title: "Active Inference",
       presets: presets,
       selected: nil,
       model: nil,
       belief: nil,
       belief_data: [],
       policy_data: [],
       step_count: 0
     )}
  end

  @impl true
  def handle_event("select_preset", %{"name" => name}, socket) do
    preset = Enum.find(socket.assigns.presets, &(&1.name == name))

    if preset do
      model = apply(PresetModels, preset.function, [])
      belief = BeliefState.new(model)
      {belief_data, policy_data} = compute_visualization(belief, model)

      {:noreply,
       socket
       |> assign(
         selected: name,
         model: model,
         belief: belief,
         belief_data: belief_data,
         policy_data: policy_data,
         step_count: 0
       )
       |> push_event("update_beliefs", %{beliefs: belief_data})
       |> push_event("update_policies", %{policies: policy_data})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("observe", %{"obs" => obs_str}, socket) do
    obs_idx = String.to_integer(obs_str)
    model = socket.assigns.model
    belief = socket.assigns.belief

    updated_belief = BeliefState.update(belief, model, obs_idx)
    {belief_data, policy_data} = compute_visualization(updated_belief, model)

    {:noreply,
     socket
     |> assign(
       belief: updated_belief,
       belief_data: belief_data,
       policy_data: policy_data,
       step_count: socket.assigns.step_count + 1
     )
     |> push_event("update_beliefs", %{beliefs: belief_data})
     |> push_event("update_policies", %{policies: policy_data})}
  end

  defp compute_visualization(belief, model) do
    belief_data = belief.posterior

    efes = FreeEnergy.expected_free_energy(belief, model)

    policy_data =
      model.policies
      |> Enum.zip(efes)
      |> Enum.map(fn {actions, efe} ->
        %{actions: Enum.map(actions, &to_string/1), efe: efe}
      end)
      |> Enum.sort_by(& &1.efe)

    {belief_data, policy_data}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Active Inference</.page_header>
    <div class="grid grid-cols-3 gap-4 mt-4">
      <div class="col-span-1">
        <h3 class="text-sm font-semibold mb-2">Preset Models</h3>
        <div
          :for={p <- @presets}
          phx-click="select_preset"
          phx-value-name={p.name}
          class={"p-2 border rounded mb-2 cursor-pointer transition-colors #{if @selected == p.name, do: "bg-blue-50 border-blue-300 ring-1 ring-blue-200", else: "hover:bg-zinc-50"}"}
        >
          <div class="font-medium text-sm">{p.name}</div>
          <div class="text-xs text-zinc-500">{p.description}</div>
        </div>

        <div :if={@model} class="mt-4 p-3 border rounded bg-zinc-50 text-xs space-y-1">
          <h4 class="font-semibold text-sm mb-2">Model Info</h4>
          <div>States: {@model.num_states}</div>
          <div>Observations: {@model.num_observations}</div>
          <div>Actions: {@model.num_actions}</div>
          <div>Policies: {length(@model.policies)}</div>
          <div>Steps: {@step_count}</div>
        </div>

        <div :if={@model} class="mt-4">
          <h4 class="text-sm font-semibold mb-2">Observe</h4>
          <div class="flex flex-wrap gap-1">
            <button
              :for={obs_idx <- 0..(@model.num_observations - 1)}
              phx-click="observe"
              phx-value-obs={obs_idx}
              class="bg-emerald-600 hover:bg-emerald-700 text-white text-xs px-2 py-1 rounded transition-colors"
            >
              Obs {obs_idx}
            </button>
          </div>
        </div>
      </div>
      <div class="col-span-2 space-y-4">
        <div class="p-4 border rounded">
          <h3 class="text-sm font-semibold mb-2">Belief State</h3>
          <div id="belief-viz" phx-hook="BeliefVisualizer" data-beliefs={Jason.encode!(@belief_data)} phx-update="ignore">
            <p :if={@belief_data == []} class="text-sm text-zinc-400">Select a preset to visualize beliefs</p>
          </div>
        </div>
        <div class="p-4 border rounded">
          <h3 class="text-sm font-semibold mb-2">Policy Evaluation (Expected Free Energy)</h3>
          <div id="policy-tree" phx-hook="PolicyTree" data-policies={Jason.encode!(@policy_data)} phx-update="ignore">
            <p :if={@policy_data == []} class="text-sm text-zinc-400">Select a preset to evaluate policies</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.LlmConfigLive do
  @moduledoc "LLM provider setup and system prompt editor."
  use JidoBuilderWeb, :live_view

  @providers ["anthropic", "openai", "mock"]
  @models_by_provider %{
    "anthropic" => ["claude-sonnet-4-20250514", "claude-haiku-4-5-20251001"],
    "openai" => ["gpt-4", "gpt-4o", "gpt-3.5-turbo"],
    "mock" => ["mock-model-v1"]
  }

  @impl true
  def mount(_params, _session, socket) do
    provider = "anthropic"

    {:ok,
     assign(socket,
       page_title: "LLM Config",
       providers: @providers,
       selected_provider: provider,
       model_options: @models_by_provider[provider],
       selected_model: hd(@models_by_provider[provider]),
       temperature: "0.7",
       max_tokens: "1024",
       system_prompt: "",
       saved: false
     )}
  end

  @impl true
  def handle_event("validate", %{"config" => params}, socket) do
    provider = params["provider"] || socket.assigns.selected_provider
    model_options = @models_by_provider[provider] || []
    selected_model = if params["model"] in model_options, do: params["model"], else: hd(model_options)

    {:noreply,
     assign(socket,
       selected_provider: provider,
       model_options: model_options,
       selected_model: selected_model,
       temperature: params["temperature"] || socket.assigns.temperature,
       max_tokens: params["max_tokens"] || socket.assigns.max_tokens,
       system_prompt: params["system_prompt"] || socket.assigns.system_prompt,
       saved: false
     )}
  end

  def handle_event("save_config", _params, socket) do
    {:noreply, assign(socket, saved: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>LLM Configuration</.page_header>

    <div :if={@saved} class="p-3 bg-green-50 border border-green-200 rounded text-sm text-green-800 mt-4">
      Configuration saved successfully
    </div>

    <form phx-change="validate" class="mt-4 space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div class="p-4 border rounded space-y-3">
          <div>
            <label class="text-sm font-semibold block mb-1">Provider</label>
            <select name="config[provider]" class="w-full border rounded p-2 text-sm">
              <option :for={p <- @providers} value={p} selected={p == @selected_provider}>{p}</option>
            </select>
          </div>
          <div>
            <label class="text-sm font-semibold block mb-1">Model</label>
            <select name="config[model]" class="w-full border rounded p-2 text-sm">
              <option :for={m <- @model_options} value={m} selected={m == @selected_model}>{m}</option>
            </select>
          </div>
          <div>
            <label class="text-sm font-semibold block mb-1">Temperature</label>
            <input type="number" name="config[temperature]" value={@temperature} step="0.1" min="0" max="2" class="w-full border rounded p-2 text-sm" />
          </div>
          <div>
            <label class="text-sm font-semibold block mb-1">Max Tokens</label>
            <input type="number" name="config[max_tokens]" value={@max_tokens} step="256" min="1" max="128000" class="w-full border rounded p-2 text-sm" />
          </div>
        </div>
        <div class="p-4 border rounded">
          <label class="text-sm font-semibold block mb-1">System Prompt</label>
          <textarea name="config[system_prompt]" class="w-full border rounded p-2 text-sm h-48 font-mono" placeholder="You are a helpful assistant...">{@system_prompt}</textarea>
        </div>
      </div>
      <button type="button" phx-click="save_config" class="bg-blue-600 hover:bg-blue-700 text-white text-sm px-4 py-2 rounded transition-colors">
        Save Configuration
      </button>
    </form>
    """
  end
end

defmodule JidoBuilderWeb.FactoryLive do
  @moduledoc "Agent composition wizard and team builder."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Skills.SolutionCatalog
  alias JidoBuilderRuntime.Factory.TeamDeployer

  @impl true
  def mount(_params, _session, socket) do
    solutions = SolutionCatalog.list()
    {:ok, assign(socket, page_title: "Agent Factory", solutions: solutions, deploy_result: nil)}
  end

  @impl true
  def handle_event("deploy_solution", %{"slug" => slug}, socket) do
    solution = SolutionCatalog.get(slug)

    {:ok, plan} = TeamDeployer.plan(solution)
    {:ok, deployed} = TeamDeployer.deploy(plan)

    {:noreply,
     assign(socket,
       deploy_result: %{status: :deployed, name: solution.name, agent_count: deployed.agent_count}
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agent Factory</.page_header>

    <div :if={@deploy_result} class={"p-3 rounded mb-4 text-sm #{if @deploy_result.status == :deployed, do: "bg-green-50 text-green-800 border border-green-200", else: "bg-red-50 text-red-800 border border-red-200"}"}>
      <span :if={@deploy_result.status == :deployed}>
        {@deploy_result.name} deployed — {@deploy_result.agent_count} agents created
      </span>
      <span :if={@deploy_result.status == :error}>
        Deploy failed: {@deploy_result.error}
      </span>
    </div>

    <div class="grid grid-cols-2 gap-4 mt-4">
      <div :for={s <- @solutions} class="p-4 border rounded">
        <div class="flex justify-between items-start">
          <div>
            <h3 class="font-semibold text-sm">{s.name}</h3>
            <p class="text-xs text-zinc-500 mt-1">{s.description}</p>
          </div>
          <button phx-click="deploy_solution" phx-value-slug={s.slug} class="bg-blue-600 hover:bg-blue-700 text-white text-xs px-3 py-1 rounded transition-colors shrink-0">
            Deploy
          </button>
        </div>
        <div class="mt-2 text-xs">
          <span class="bg-blue-100 text-blue-700 px-2 py-0.5 rounded">{s.category}</span>
        </div>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.SolutionsLive do
  @moduledoc "Solution catalog with one-click deploy."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Skills.SolutionCatalog
  alias JidoBuilderRuntime.Factory.TeamDeployer

  @impl true
  def mount(_params, _session, socket) do
    solutions = SolutionCatalog.list()
    {:ok, assign(socket, page_title: "Solutions", solutions: solutions, deploy_result: nil)}
  end

  @impl true
  def handle_event("deploy", %{"slug" => slug}, socket) do
    solution = SolutionCatalog.get(slug)

    {:ok, plan} = TeamDeployer.plan(solution)
    {:ok, deployed} = TeamDeployer.deploy(plan)

    {:noreply,
     assign(socket,
       deploy_result: %{
         status: :deployed,
         name: solution.name,
         agent_count: deployed.agent_count
       }
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Solutions</.page_header>

    <div :if={@deploy_result} class={"p-3 rounded mb-4 text-sm #{if @deploy_result.status == :deployed, do: "bg-green-50 text-green-800 border border-green-200", else: "bg-red-50 text-red-800 border border-red-200"}"}>
      <span :if={@deploy_result.status == :deployed}>
        {@deploy_result.name} deployed successfully — {@deploy_result.agent_count} agents created
      </span>
      <span :if={@deploy_result.status == :error}>
        Failed to deploy {@deploy_result.name}: {@deploy_result.error}
      </span>
    </div>

    <div class="space-y-3 mt-4">
      <div :for={s <- @solutions} class="p-4 border rounded flex justify-between items-center">
        <div>
          <div class="font-semibold text-sm">{s.name}</div>
          <div class="text-xs text-zinc-500">{s.description}</div>
        </div>
        <button phx-click="deploy" phx-value-slug={s.slug} class="bg-blue-600 hover:bg-blue-700 text-white text-xs px-3 py-1 rounded transition-colors">Deploy</button>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.TemplateLibraryLive do
  @moduledoc "Browsable/searchable template marketplace."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.ActionRegistry
  alias JidoBuilderRuntime.Skills.SkillRegistry

  @impl true
  def mount(_params, _session, socket) do
    actions = ActionRegistry.list()
    skills = SkillRegistry.list()
    categories = ActionRegistry.categories()

    {:ok,
     assign(socket,
       page_title: "Template Library",
       actions: actions,
       skills: skills,
       categories: categories,
       filtered_actions: actions,
       filtered_skills: skills,
       query: "",
       tab: "actions",
       category: nil
     )}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, socket |> assign(query: query) |> apply_filters()}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, tab: tab)}
  end

  def handle_event("filter_category", %{"cat" => "all"}, socket) do
    {:noreply, socket |> assign(category: nil) |> apply_filters()}
  end

  def handle_event("filter_category", %{"cat" => cat}, socket) do
    {:noreply, socket |> assign(category: String.to_existing_atom(cat)) |> apply_filters()}
  end

  defp apply_filters(socket) do
    q = String.downcase(socket.assigns.query)
    cat = socket.assigns.category

    filtered_actions =
      socket.assigns.actions
      |> then(fn actions ->
        if cat, do: Enum.filter(actions, &(&1.category == cat)), else: actions
      end)
      |> then(fn actions ->
        if q == "", do: actions, else: Enum.filter(actions, fn a ->
          String.contains?(String.downcase(a.name), q) or
            String.contains?(String.downcase(a.slug), q)
        end)
      end)

    filtered_skills =
      socket.assigns.skills
      |> then(fn skills ->
        if q == "", do: skills, else: Enum.filter(skills, fn s ->
          String.contains?(String.downcase(s.name), q) or
            Enum.any?(s.action_slugs, &String.contains?(&1, q))
        end)
      end)

    assign(socket, filtered_actions: filtered_actions, filtered_skills: filtered_skills)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Template Library</.page_header>
    <div class="mt-4">
      <div class="flex items-center gap-4 mb-4">
        <button
          :for={tab <- ["actions", "skills"]}
          phx-click="switch_tab"
          phx-value-tab={tab}
          class={"text-sm font-semibold px-3 py-1 rounded transition-colors #{if @tab == tab, do: "bg-blue-600 text-white", else: "bg-zinc-200 text-zinc-700 hover:bg-zinc-300"}"}
        >
          {if tab == "actions", do: "#{length(@actions)} Actions", else: "#{length(@skills)} Skills"}
        </button>
      </div>

      <form phx-change="search" class="mb-4">
        <input type="text" name="q" value={@query} placeholder="Search actions or skills..." class="w-full border rounded p-2 text-sm" phx-debounce="200" />
      </form>

      <div :if={@tab == "actions"} class="mb-3 flex flex-wrap gap-1">
        <button phx-click="filter_category" phx-value-cat="all" class={"text-xs px-2 py-1 rounded #{if @category == nil, do: "bg-blue-600 text-white", else: "bg-zinc-200 text-zinc-700"}"}>All</button>
        <button
          :for={cat <- @categories}
          phx-click="filter_category"
          phx-value-cat={cat}
          class={"text-xs px-2 py-1 rounded #{if @category == cat, do: "bg-blue-600 text-white", else: "bg-zinc-200 text-zinc-700"}"}
        >
          {cat}
        </button>
      </div>

      <div :if={@tab == "actions"} class="grid grid-cols-4 gap-2">
        <div :for={a <- @filtered_actions} class="action-card p-2 border rounded text-xs hover:bg-zinc-50 transition-colors">
          <div class="font-medium">{a.name}</div>
          <div class="text-zinc-500">{a.category}</div>
        </div>
      </div>

      <div :if={@tab == "skills"} class="space-y-3">
        <div :for={s <- @filtered_skills} class="p-4 border rounded">
          <div class="flex justify-between">
            <div>
              <div class="font-semibold text-sm">{s.name}</div>
              <div class="text-xs text-zinc-500">{s.description}</div>
            </div>
            <span class="bg-purple-100 text-purple-700 text-xs px-2 py-0.5 rounded h-fit">{s.category}</span>
          </div>
          <div class="mt-2 flex gap-1 flex-wrap">
            <span :for={slug <- s.action_slugs} class="bg-zinc-100 text-xs px-1.5 py-0.5 rounded">{slug}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.NotebookLive do
  @moduledoc "LiveBook-style code + run editor."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Repl.Evaluator

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Notebook", cells: [], eval: Evaluator.new())}
  end

  @impl true
  def handle_event("run_cell", %{"code" => code}, socket) when byte_size(code) > 0 do
    eval = socket.assigns.eval

    case Evaluator.eval(eval, code) do
      {:ok, result, updated_eval} ->
        {:noreply,
         socket
         |> assign(eval: updated_eval, cells: Evaluator.results(updated_eval))
         |> push_event("cell_result", %{
           result: inspect(result),
           status: "ok",
           cell: updated_eval.cell_count
         })}

      {:error, reason, updated_eval} ->
        {:noreply,
         socket
         |> assign(eval: updated_eval, cells: Evaluator.results(updated_eval))
         |> push_event("cell_result", %{
           result: reason,
           status: "error",
           cell: updated_eval.cell_count
         })}
    end
  end

  def handle_event("run_cell", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Notebook</.page_header>
    <div class="mt-4 space-y-3">
      <div id="code-editor" phx-hook="CodeEditor" class="p-4 border rounded bg-zinc-50">
        <textarea class="w-full border rounded p-2 text-sm font-mono h-24" placeholder="# Write Elixir code here..."></textarea>
        <button data-action="run" class="mt-2 bg-green-600 text-white text-xs px-3 py-1 rounded">Run Cell</button>
      </div>
      <div :for={cell <- @cells} class={"p-3 border rounded text-sm font-mono #{if cell.status == :ok, do: "bg-green-50", else: "bg-red-50"}"}>
        <div class="text-zinc-500 text-xs">Cell {cell.cell}</div>
        <div class="text-xs text-zinc-400 mb-1 font-mono">{cell.code}</div>
        <div class={"font-medium #{if cell.status == :ok, do: "text-green-800", else: "text-red-700"}"}>
          {if cell.status == :ok, do: inspect(cell.result), else: cell.error}
        </div>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.SkillsManagerLive do
  @moduledoc "Skills management page."
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    skills = JidoBuilderRuntime.Skills.SkillRegistry.list()
    {:ok, assign(socket, page_title: "Skills Manager", skills: skills)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Skills Manager</.page_header>
    <div class="space-y-3 mt-4">
      <div :for={s <- @skills} class="p-4 border rounded">
        <div class="flex justify-between">
          <div>
            <div class="font-semibold text-sm"><%= s.name %></div>
            <div class="text-xs text-zinc-500"><%= s.description %></div>
          </div>
          <span class="bg-purple-100 text-purple-700 text-xs px-2 py-0.5 rounded h-fit"><%= s.category %></span>
        </div>
        <div class="mt-2 flex gap-1">
          <span :for={action <- s.action_slugs} class="bg-zinc-100 text-xs px-1.5 py-0.5 rounded"><%= action %></span>
        </div>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.AgentChatLive do
  @moduledoc "LLM agent conversation UI."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.LLM.Providers.Mock
  alias JidoBuilderRuntime.LLM.Conversation

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Agent Chat",
       messages: [],
       input: "",
       conversation: Conversation.new(system: "You are a helpful Jido agent.")
     )}
  end

  @impl true
  def handle_event("update_input", %{"message" => msg}, socket) do
    {:noreply, assign(socket, input: msg)}
  end

  def handle_event("send_message", %{"message" => msg}, socket) when byte_size(msg) > 0 do
    conv = socket.assigns.conversation
    messages = socket.assigns.messages

    # Add user message
    conv = Conversation.add_user(conv, msg)
    messages = messages ++ [%{role: "user", content: msg}]

    # Get LLM response via Mock provider
    case Mock.chat(Conversation.to_messages(conv), Mock.default_config()) do
      {:ok, response} ->
        conv = Conversation.add_assistant(conv, response.content)
        messages = messages ++ [%{role: "assistant", content: response.content}]

        {:noreply,
         socket
         |> assign(messages: messages, conversation: conv, input: "")
         |> push_event("add_message", %{role: "user", content: msg})
         |> push_event("add_message", %{role: "assistant", content: response.content})}

      {:error, _reason} ->
        {:noreply, assign(socket, messages: messages, conversation: conv, input: "")}
    end
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Agent Chat</.page_header>
    <div class="mt-4 flex flex-col h-96">
      <div id="chat-stream" phx-hook="ChatStream" class="flex-1 overflow-y-auto border rounded p-3 space-y-2 mb-3">
        <div :for={msg <- @messages} class={"p-2 rounded text-sm #{if msg.role == "user", do: "bg-blue-50 ml-8", else: "bg-zinc-50 mr-8"}"}>
          <span class="text-xs font-semibold">{msg.role}</span>
          <p>{msg.content}</p>
        </div>
        <p :if={@messages == []} class="text-zinc-400 text-sm text-center">Start a conversation...</p>
      </div>
      <form phx-submit="send_message" phx-change="update_input" class="flex gap-2">
        <input type="text" name="message" value={@input} class="flex-1 border rounded px-3 py-2 text-sm" placeholder="Type a message..." autocomplete="off" />
        <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded text-sm transition-colors">Send</button>
      </form>
    </div>
    """
  end
end
