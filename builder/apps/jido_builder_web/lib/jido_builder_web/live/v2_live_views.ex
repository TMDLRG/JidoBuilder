defmodule JidoBuilderWeb.ActiveInferenceLive do
  @moduledoc "Active Inference model visualization, belief updates, and agent integration."
  use JidoBuilderWeb, :live_view

  import Ecto.Query

  alias JidoBuilderRuntime.ActiveInference.PresetModels
  alias Jido.ActiveInference.{BeliefState, FreeEnergy}
  alias JidoBuilderCore.{Repo, Templates, Templates.TemplateGenerativeModel}
  alias JidoBuilderRuntime.Roster

  @impl true
  def mount(_params, _session, socket) do
    presets = PresetModels.list()
    templates = Templates.list_templates(1)

    {:ok,
     assign(socket,
       page_title: "Active Inference",
       presets: presets,
       templates: templates,
       selected: nil,
       model: nil,
       belief: nil,
       belief_data: [],
       policy_data: [],
       step_count: 0,
       selected_template_id: nil,
       attach_result: nil,
       hire_result: nil
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

  def handle_event("select_template", %{"template_id" => id}, socket) do
    tid = case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end

    {:noreply, assign(socket, selected_template_id: tid)}
  end

  def handle_event("attach_model", _params, socket) do
    model = socket.assigns.model
    template_id = socket.assigns.selected_template_id
    preset_name = socket.assigns.selected

    if model && template_id do
      # Serialize the GenerativeModel matrices to DB
      gm_attrs = %{
        template_id: template_id,
        name: preset_name || "Custom Model",
        description: "Active Inference #{preset_name} model",
        matrices: %{
          "a_matrix" => serialize_matrix(model.a_matrix),
          "b_matrices" => serialize_matrix(model.b_matrices),
          "num_states" => model.num_states,
          "num_observations" => model.num_observations,
          "num_actions" => model.num_actions
        },
        preferences: %{"c_vector" => model.c_vector},
        priors: %{"d_vector" => model.d_vector},
        policies: Enum.map(model.policies, fn actions -> %{"actions" => actions} end),
        config: %{"preset" => preset_name, "strategy" => "active_inference"}
      }

      case %TemplateGenerativeModel{} |> TemplateGenerativeModel.changeset(gm_attrs) |> Repo.insert() do
        {:ok, _gm} ->
          {:noreply, assign(socket, attach_result: {:ok, "Model '#{preset_name}' attached to template"})}

        {:error, changeset} ->
          {:noreply, assign(socket, attach_result: {:error, "Failed: #{inspect(changeset.errors)}"})}
      end
    else
      {:noreply, assign(socket, attach_result: {:error, "Select a model and template first"})}
    end
  end

  def handle_event("hire_ai_agent", _params, socket) do
    template_id = socket.assigns.selected_template_id

    if template_id do
      agent_name = "ai-agent-#{System.unique_integer([:positive])}"

      case Roster.hire(1, agent_name, "web", template_id: template_id) do
        {:ok, instance} ->
          {:noreply, assign(socket, hire_result: {:ok, "Agent '#{instance.name}' hired with template ##{template_id}"})}

        {:error, reason} ->
          {:noreply, assign(socket, hire_result: {:error, "Hire failed: #{inspect(reason)}"})}
      end
    else
      {:noreply, assign(socket, hire_result: {:error, "Select a template first"})}
    end
  end

  defp serialize_matrix(matrix) when is_list(matrix), do: matrix
  defp serialize_matrix(matrix), do: inspect(matrix)

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

    <div :if={@model} class="mt-4 p-4 border rounded bg-zinc-50">
      <h3 class="text-sm font-semibold mb-3">Deploy as Agent</h3>
      <div class="flex items-end gap-3">
        <div class="flex-1">
          <label class="text-xs font-medium text-zinc-600 block mb-1">Attach to Template</label>
          <form phx-change="select_template">
            <select name="template_id" class="ui-input text-sm">
              <option value="">Select template...</option>
              <option :for={t <- @templates} value={t.id} selected={t.id == @selected_template_id}>{t.name}</option>
            </select>
          </form>
        </div>
        <button :if={@selected_template_id} phx-click="attach_model" class="bg-blue-600 hover:bg-blue-700 text-white text-xs px-3 py-2 rounded transition-colors">
          Attach Model
        </button>
        <button :if={@selected_template_id} phx-click="hire_ai_agent" class="bg-emerald-600 hover:bg-emerald-700 text-white text-xs px-3 py-2 rounded transition-colors">
          Hire AI Agent
        </button>
      </div>
      <p :if={@attach_result} class={"text-xs mt-2 #{if elem(@attach_result, 0) == :ok, do: "text-green-600", else: "text-red-600"}"}>
        {elem(@attach_result, 1)}
      </p>
      <p :if={@hire_result} class={"text-xs mt-1 #{if elem(@hire_result, 0) == :ok, do: "text-green-600", else: "text-red-600"}"}>
        {elem(@hire_result, 1)}
      </p>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.LlmConfigLive do
  @moduledoc "LLM provider setup, system prompt editor, and tool whitelist selector."
  use JidoBuilderWeb, :live_view

  import Ecto.Query

  alias JidoBuilderRuntime.ActionRegistry

  @providers ["anthropic", "openai", "mock"]
  @models_by_provider %{
    "anthropic" => ["claude-sonnet-4-20250514", "claude-haiku-4-5-20251001"],
    "openai" => ["gpt-4", "gpt-4o", "gpt-3.5-turbo"],
    "mock" => ["mock-model-v1"]
  }

  @impl true
  def mount(_params, _session, socket) do
    alias JidoBuilderCore.{Repo, Templates.TemplateLlmConfig}

    existing = Repo.one(from c in TemplateLlmConfig, order_by: [desc: c.id], limit: 1)

    {provider, model, temp, tokens, prompt, whitelist} =
      case existing do
        %TemplateLlmConfig{} = c ->
          {c.provider, c.model, to_string(c.temperature || 0.7),
           to_string(c.max_tokens || 1024), c.system_prompt || "", c.tool_whitelist || []}
        nil ->
          {"anthropic", "claude-sonnet-4-20250514", "0.7", "1024", "", []}
      end

    actions_by_category =
      ActionRegistry.list()
      |> Enum.reject(fn a -> a.slug == "llm_chat" end)
      |> Enum.group_by(& &1.category)
      |> Enum.sort_by(fn {cat, _} -> to_string(cat) end)

    {:ok,
     assign(socket,
       page_title: "LLM Configuration",
       providers: @providers,
       selected_provider: provider,
       model_options: @models_by_provider[provider] || [],
       selected_model: model,
       temperature: temp,
       max_tokens: tokens,
       system_prompt: prompt,
       tool_whitelist: MapSet.new(whitelist),
       actions_by_category: actions_by_category,
       saved: false
     )}
  end

  @impl true
  def handle_event("validate", %{"config" => params}, socket) do
    provider = params["provider"] || socket.assigns.selected_provider
    model_options = @models_by_provider[provider] || []
    selected_model = if params["model"] in model_options, do: params["model"], else: List.first(model_options)

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

  def handle_event("toggle_tool", %{"slug" => slug}, socket) do
    whitelist = socket.assigns.tool_whitelist

    whitelist =
      if MapSet.member?(whitelist, slug),
        do: MapSet.delete(whitelist, slug),
        else: MapSet.put(whitelist, slug)

    {:noreply, assign(socket, tool_whitelist: whitelist, saved: false)}
  end

  def handle_event("save_config", _params, socket) do
    alias JidoBuilderCore.{Repo, Templates.TemplateLlmConfig}

    attrs = %{
      provider: socket.assigns.selected_provider,
      model: socket.assigns.selected_model,
      temperature: parse_float(socket.assigns.temperature, 0.7),
      max_tokens: parse_int(socket.assigns.max_tokens, 1024),
      system_prompt: socket.assigns.system_prompt,
      tool_whitelist: MapSet.to_list(socket.assigns.tool_whitelist)
    }

    case Repo.one(from c in TemplateLlmConfig, order_by: [desc: c.id], limit: 1) do
      nil ->
        template = Repo.one(from t in JidoBuilderCore.Templates.Template, limit: 1)
        if template do
          %TemplateLlmConfig{template_id: template.id}
          |> TemplateLlmConfig.changeset(attrs)
          |> Repo.insert()
        end

      existing ->
        existing
        |> TemplateLlmConfig.changeset(attrs)
        |> Repo.update()
    end

    {:noreply, assign(socket, saved: true)}
  end

  defp parse_float(val, default) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error -> default
    end
  end
  defp parse_float(_, default), do: default

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> default
    end
  end
  defp parse_int(_, default), do: default

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

      <div class="p-4 border rounded">
        <h3 class="text-sm font-semibold mb-2">Tool Whitelist</h3>
        <p class="text-xs text-zinc-500 mb-3">Select which actions the LLM agent can invoke as tools. {MapSet.size(@tool_whitelist)} selected.</p>
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-x-4 gap-y-1">
          <div :for={{category, actions} <- @actions_by_category} class="mb-3">
            <h4 class="text-xs font-semibold text-zinc-500 uppercase mb-1">{category}</h4>
            <label :for={a <- actions} class="flex items-center gap-1.5 text-xs py-0.5 cursor-pointer hover:bg-zinc-50 rounded px-1">
              <input
                type="checkbox"
                checked={MapSet.member?(@tool_whitelist, a.slug)}
                phx-click="toggle_tool"
                phx-value-slug={a.slug}
                class="rounded border-zinc-300 text-blue-600 focus:ring-blue-500"
              />
              <span>{a.name}</span>
            </label>
          </div>
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
      {:ok, _result, updated_eval} ->
        {:noreply, assign(socket, eval: updated_eval, cells: Evaluator.results(updated_eval))}

      {:error, _reason, updated_eval} ->
        {:noreply, assign(socket, eval: updated_eval, cells: Evaluator.results(updated_eval))}
    end
  end

  def handle_event("run_cell", _params, socket), do: {:noreply, socket}

  def handle_event("run_cell_form", %{"code" => code}, socket) when byte_size(code) > 0 do
    handle_event("run_cell", %{"code" => code}, socket)
  end

  def handle_event("run_cell_form", _params, socket), do: {:noreply, socket}

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, eval: Evaluator.new(), cells: [])}
  end

  def handle_event("export", _params, socket) do
    eval = socket.assigns.eval
    code = Evaluator.export(eval, "NotebookExport")

    {:noreply,
     socket
     |> push_event("download", %{filename: "notebook_export.ex", content: code})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>
      Notebook
      <:actions>
        <div class="flex gap-2">
          <button phx-click="reset" class="ui-btn secondary text-xs" data-confirm="Reset notebook? All cells will be lost.">Reset</button>
          <button :if={@cells != []} phx-click="export" class="ui-btn secondary text-xs">Export Module</button>
        </div>
      </:actions>
    </.page_header>
    <div class="mt-4 space-y-3">
      <form id="notebook-form" phx-submit="run_cell_form" class="p-4 border rounded bg-zinc-50">
        <textarea name="code" id="notebook-code" class="w-full border rounded p-2 text-sm font-mono h-24" placeholder="# Write Elixir code here... Try: Enum.map(1..5, &(&1 * &1))"></textarea>
        <div class="flex items-center gap-3 mt-2">
          <button type="submit" class="bg-green-600 hover:bg-green-700 text-white text-xs px-3 py-1 rounded transition-colors">Run Cell</button>
          <span class="text-xs text-zinc-400">{length(@cells)} cells executed</span>
        </div>
      </form>
      <div :for={cell <- @cells} class={"p-3 border rounded text-sm font-mono #{if cell.status == :ok, do: "bg-green-50", else: "bg-red-50"}"}>
        <div class="flex justify-between">
          <span class="text-zinc-500 text-xs">Cell {cell.cell}</span>
          <span class={"text-xs px-1.5 py-0.5 rounded #{if cell.status == :ok, do: "bg-green-200 text-green-800", else: "bg-red-200 text-red-800"}"}>{cell.status}</span>
        </div>
        <div class="text-xs text-zinc-400 mb-1 font-mono mt-1">{cell.code}</div>
        <div class={"font-medium #{if cell.status == :ok, do: "text-green-800", else: "text-red-700"}"}>
          {if cell.status == :ok, do: inspect(cell.result), else: cell.error}
        </div>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.SkillsManagerLive do
  @moduledoc "Skills management page with CRUD."
  use JidoBuilderWeb, :live_view

  alias JidoBuilderRuntime.Skills.SkillRegistry
  alias JidoBuilderRuntime.ActionRegistry

  @impl true
  def mount(_params, _session, socket) do
    skills = SkillRegistry.list()
    categories = SkillRegistry.categories()
    all_actions = ActionRegistry.list()

    {:ok,
     assign(socket,
       page_title: "Skills Manager",
       skills: skills,
       categories: categories,
       all_actions: all_actions,
       expanded: nil,
       show_create: false
     )}
  end

  @impl true
  def handle_event("toggle_create", _params, socket) do
    {:noreply, assign(socket, show_create: !socket.assigns.show_create)}
  end

  def handle_event("toggle_detail", %{"slug" => slug}, socket) do
    expanded = if socket.assigns.expanded == slug, do: nil, else: slug
    {:noreply, assign(socket, expanded: expanded)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>
      Skills Manager
      <:actions>
        <button phx-click="toggle_create" class={"ui-btn #{if @show_create, do: "secondary", else: "primary"} text-xs"}>
          {if @show_create, do: "Cancel", else: "New Skill"}
        </button>
      </:actions>
    </.page_header>

    <div :if={@show_create} class="mb-4 p-4 border rounded bg-zinc-50">
      <h3 class="text-sm font-semibold mb-2">Create a new skill by composing actions from the library.</h3>
      <p class="text-xs text-zinc-500 mb-3">Skills are named bundles of actions with a system prompt fragment. Use the <.link navigate={~p"/template-library"} class="text-blue-600 hover:underline">Template Library</.link> to browse available actions, then create a skill via the <code class="bg-zinc-200 px-1 rounded">jido_skill</code> MCP tool or the Notebook.</p>
    </div>

    <div class="space-y-3 mt-4">
      <div :for={s <- @skills} class="border rounded overflow-hidden">
        <div phx-click="toggle_detail" phx-value-slug={s.slug} class="p-4 cursor-pointer hover:bg-zinc-50 transition-colors">
          <div class="flex justify-between">
            <div>
              <div class="font-semibold text-sm">{s.name}</div>
              <div class="text-xs text-zinc-500">{s.description}</div>
            </div>
            <span class="bg-purple-100 text-purple-700 text-xs px-2 py-0.5 rounded h-fit">{s.category}</span>
          </div>
          <div class="mt-2 flex gap-1 flex-wrap">
            <span :for={action <- s.action_slugs} class="bg-zinc-100 text-xs px-1.5 py-0.5 rounded">{action}</span>
          </div>
        </div>
        <div :if={@expanded == s.slug} class="bg-zinc-50 border-t p-4 space-y-2">
          <h4 class="text-xs font-semibold">Action Details</h4>
          <div :for={slug <- s.action_slugs} class="text-xs">
            <% action = Enum.find(@all_actions, &(&1.slug == slug)) %>
            <div :if={action} class="flex items-center gap-2 py-1 border-b border-zinc-100">
              <span class="font-mono font-semibold">{action.name}</span>
              <span class="text-zinc-400">{action.description}</span>
              <span class="ml-auto bg-zinc-200 px-1.5 py-0.5 rounded">{action.category}</span>
            </div>
            <div :if={!action} class="text-red-500">Missing action: {slug}</div>
          </div>
          <div :if={s[:system_prompt_fragment]} class="mt-2 pt-2 border-t">
            <span class="text-xs font-semibold">System Prompt Fragment:</span>
            <p class="text-xs text-zinc-600 font-mono mt-1">{s.system_prompt_fragment}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule JidoBuilderWeb.AgentChatLive do
  @moduledoc """
  LLM agent conversation UI — dispatches chat through the LlmChat action
  with agentic tool-use loop, conversation persistence, and thread management.
  """
  use JidoBuilderWeb, :live_view

  import Ecto.Query

  alias JidoBuilderRuntime.LLM.{Conversation, ConversationStore, ToolWhitelist}
  alias JidoBuilderRuntime.Actions.LlmChat

  @impl true
  def mount(_params, _session, socket) do
    {provider_name, llm_config, tool_modules, template_id} = load_agent_config()
    conversation_id = Ecto.UUID.generate()

    # Load existing conversations for this template
    threads = if template_id, do: ConversationStore.list_conversations(template_id), else: []

    {:ok,
     assign(socket,
       page_title: "Agent Chat",
       messages: [],
       input: "",
       loading: false,
       provider_name: provider_name,
       llm_config: llm_config,
       tool_modules: tool_modules,
       template_id: template_id,
       conversation_id: conversation_id,
       threads: threads,
       conversation: Conversation.new(system: llm_config[:system] || "You are a helpful Jido agent.")
     )}
  end

  @impl true
  def handle_event("update_input", %{"message" => msg}, socket) do
    {:noreply, assign(socket, input: msg)}
  end

  def handle_event("send_message", %{"message" => msg}, socket) when byte_size(msg) > 0 do
    messages = socket.assigns.messages ++ [%{role: "user", content: msg}]

    socket =
      socket
      |> assign(messages: messages, input: "", loading: true)

    send(self(), {:dispatch_chat, msg})
    {:noreply, socket}
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  def handle_event("new_conversation", _params, socket) do
    conversation_id = Ecto.UUID.generate()
    threads = if socket.assigns.template_id, do: ConversationStore.list_conversations(socket.assigns.template_id), else: []

    {:noreply,
     assign(socket,
       messages: [],
       conversation_id: conversation_id,
       threads: threads,
       conversation: Conversation.new(system: socket.assigns.llm_config[:system] || "You are a helpful Jido agent.")
     )}
  end

  def handle_event("load_conversation", %{"id" => conv_id}, socket) do
    template_id = socket.assigns.template_id

    if template_id do
      conv = ConversationStore.load_conversation(template_id, conv_id, system: socket.assigns.llm_config[:system])
      display_messages = Enum.map(conv.messages, fn msg -> %{role: msg[:role] || msg.role, content: msg[:content] || msg.content} end)

      {:noreply,
       assign(socket,
         messages: display_messages,
         conversation_id: conv_id,
         conversation: conv
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete_conversation", %{"id" => conv_id}, socket) do
    if socket.assigns.template_id do
      ConversationStore.delete_conversation(socket.assigns.template_id, conv_id)
      threads = ConversationStore.list_conversations(socket.assigns.template_id)

      socket =
        if socket.assigns.conversation_id == conv_id do
          assign(socket,
            messages: [],
            conversation_id: Ecto.UUID.generate(),
            conversation: Conversation.new(system: socket.assigns.llm_config[:system])
          )
        else
          socket
        end

      {:noreply, assign(socket, threads: threads)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:dispatch_chat, msg}, socket) do
    params = %{
      message: msg,
      conversation: socket.assigns.conversation,
      llm_config: socket.assigns.llm_config,
      tool_modules: socket.assigns.tool_modules,
      max_iterations: 10
    }

    case Jido.Exec.run(LlmChat, params, %{}) do
      {:ok, %{reply: reply, conversation: conv, tool_calls: tool_calls}} ->
        tool_msgs =
          Enum.flat_map(tool_calls, fn tc ->
            [%{role: "tool_call", content: "#{tc.tool}(#{inspect_args(tc.arguments)})", tool_data: tc}]
          end)

        assistant_msg = [%{role: "assistant", content: reply}]
        messages = socket.assigns.messages ++ tool_msgs ++ assistant_msg

        # Persist messages
        persist_turn(socket.assigns.template_id, socket.assigns.conversation_id, msg, tool_calls, reply)

        threads = if socket.assigns.template_id, do: ConversationStore.list_conversations(socket.assigns.template_id), else: []

        {:noreply,
         socket
         |> assign(messages: messages, conversation: conv, loading: false, threads: threads)}

      {:error, reason} ->
        error_msg = "Error: #{inspect(reason)}"
        messages = socket.assigns.messages ++ [%{role: "system", content: error_msg}]
        {:noreply, assign(socket, messages: messages, loading: false)}
    end
  end

  defp persist_turn(nil, _conv_id, _msg, _tool_calls, _reply), do: :ok
  defp persist_turn(template_id, conversation_id, user_msg, tool_calls, reply) do
    messages = [%{role: "user", content: user_msg}]

    tool_messages =
      Enum.flat_map(tool_calls, fn tc ->
        [
          %{role: "tool_call", content: "#{tc.tool}(#{inspect_args(tc.arguments)})",
            tool_data: %{"id" => tc[:id], "name" => tc.tool, "arguments" => tc.arguments}},
          %{role: "tool_result", content: tc.result,
            tool_data: %{"tool_use_id" => tc[:id]}}
        ]
      end)

    assistant_messages = [%{role: "assistant", content: reply}]

    ConversationStore.save_messages(
      template_id,
      conversation_id,
      messages ++ tool_messages ++ assistant_messages
    )
  end

  defp inspect_args(args) when is_map(args) do
    args
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v)}" end)
    |> Enum.join(", ")
  end

  defp inspect_args(args), do: inspect(args)

  defp load_agent_config do
    alias JidoBuilderCore.{Repo, Templates.TemplateLlmConfig}

    case Repo.one(from c in TemplateLlmConfig, order_by: [desc: c.id], limit: 1) do
      %TemplateLlmConfig{} = llm_cfg ->
        provider_atom = String.to_existing_atom(llm_cfg.provider)
        api_key = resolve_api_key(llm_cfg.provider, llm_cfg.config)

        config = %{
          provider: provider_atom,
          model: llm_cfg.model,
          api_key: api_key,
          max_tokens: llm_cfg.max_tokens || 1024,
          temperature: llm_cfg.temperature || 0.7,
          system: llm_cfg.system_prompt || "You are a helpful Jido agent."
        }

        provider_name =
          if api_key,
            do: "#{String.capitalize(llm_cfg.provider)} (#{llm_cfg.model})",
            else: "Mock (no API key)"

        config = if api_key, do: config, else: %{config | provider: :mock}
        tool_modules = ToolWhitelist.resolve(llm_cfg.tool_whitelist || [])

        {provider_name, config, tool_modules, llm_cfg.template_id}

      nil ->
        {"Mock (no config)", %{provider: :mock}, [], nil}
    end
  end

  defp resolve_api_key("anthropic", config) do
    get_in(config || %{}, ["api_key"]) || System.get_env("ANTHROPIC_API_KEY")
  end

  defp resolve_api_key("openai", config) do
    get_in(config || %{}, ["api_key"]) || System.get_env("OPENAI_API_KEY")
  end

  defp resolve_api_key(_, _), do: nil

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>
      Agent Chat
      <:actions>
        <button phx-click="new_conversation" class="text-xs bg-zinc-800 text-white px-3 py-1.5 rounded hover:bg-zinc-700 mr-2">New Chat</button>
        <span class="text-xs bg-zinc-200 text-zinc-600 px-2 py-1 rounded">{@provider_name}</span>
      </:actions>
    </.page_header>
    <div class="mt-4 flex gap-4" style="height: calc(100vh - 180px);">
      <%!-- Thread sidebar --%>
      <div :if={@threads != []} class="w-48 shrink-0 border rounded p-2 overflow-y-auto">
        <h3 class="text-xs font-semibold text-zinc-500 uppercase mb-2">Conversations</h3>
        <div :for={t <- @threads} class={"text-xs p-1.5 rounded cursor-pointer mb-1 flex justify-between items-center #{if t.conversation_id == @conversation_id, do: "bg-blue-50 text-blue-700", else: "hover:bg-zinc-50"}"}>
          <span phx-click="load_conversation" phx-value-id={t.conversation_id} class="truncate flex-1">
            {t.message_count} msgs
          </span>
          <button phx-click="delete_conversation" phx-value-id={t.conversation_id} class="text-red-400 hover:text-red-600 ml-1 shrink-0">&times;</button>
        </div>
      </div>

      <%!-- Chat area --%>
      <div class="flex-1 flex flex-col">
        <div id="chat-stream" phx-hook="ChatStream" class="flex-1 overflow-y-auto border rounded p-3 space-y-2 mb-3">
          <div :for={msg <- @messages} class={"p-2 rounded text-sm #{msg_class(msg.role)}"}>
            <span :if={msg.role != "tool_call"} class="text-xs font-semibold">{msg.role}</span>
            <div :if={msg.role == "tool_call"} class="flex items-center gap-2">
              <span class="text-xs font-mono bg-amber-100 text-amber-800 px-1.5 py-0.5 rounded">tool</span>
              <span class="text-xs font-mono">{msg.content}</span>
            </div>
            <p :if={msg.role != "tool_call"} class="mt-1 whitespace-pre-wrap">{msg.content}</p>
          </div>
          <div :if={@loading} class="p-2 rounded text-sm bg-zinc-50 mr-8 animate-pulse">
            <span class="text-xs font-semibold text-zinc-400">thinking...</span>
          </div>
          <p :if={@messages == [] && !@loading} class="text-zinc-400 text-sm text-center mt-8">Start a conversation...</p>
        </div>
        <form phx-submit="send_message" phx-change="update_input" class="flex gap-2">
          <input type="text" name="message" value={@input} class="flex-1 border rounded px-3 py-2 text-sm" placeholder="Type a message..." autocomplete="off" disabled={@loading} />
          <button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded text-sm transition-colors disabled:opacity-50" disabled={@loading}>
            {if @loading, do: "...", else: "Send"}
          </button>
        </form>
        <div class="flex items-center justify-between mt-2">
          <p class="text-xs text-zinc-400">
            Provider: {@provider_name}. Configure in <.link navigate={~p"/llm-config"} class="text-blue-600 hover:underline">LLM Config</.link>.
          </p>
          <p :if={@tool_modules != []} class="text-xs text-zinc-400">
            {length(@tool_modules)} tool(s) available
          </p>
        </div>
      </div>
    </div>
    """
  end

  defp msg_class("user"), do: "bg-blue-50 ml-8"
  defp msg_class("assistant"), do: "bg-zinc-50 mr-8"
  defp msg_class("tool_call"), do: "bg-amber-50 mx-4 border border-amber-200"
  defp msg_class(_), do: "bg-red-50 text-red-700"
end
