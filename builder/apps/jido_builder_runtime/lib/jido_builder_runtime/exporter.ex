defmodule JidoBuilderRuntime.Exporter do
  @moduledoc """
  Story 9.1-9.2 — Export agents and workflows as standalone Elixir modules.
  """

  alias JidoBuilderCore.{Repo, Templates, Workflows}
  alias JidoBuilderCore.Templates.Template
  alias JidoBuilderRuntime.ActionRegistry

  @doc """
  Exports a single agent template as a self-contained Elixir module string.
  """
  @spec export_agent(pos_integer()) :: {:ok, String.t()} | {:error, term()}
  def export_agent(template_id) do
    case Repo.get(Template, template_id) do
      nil ->
        {:error, :template_not_found}

      template ->
        routes = Templates.list_routes(template_id)
        code = generate_agent_module(template, routes)
        {:ok, code}
    end
  end

  @doc """
  Exports a workflow as a standalone Elixir module string.
  """
  @spec export_workflow(pos_integer()) :: {:ok, String.t()} | {:error, term()}
  def export_workflow(workflow_id) do
    case Workflows.get_workflow(workflow_id) do
      nil ->
        {:error, :workflow_not_found}

      workflow ->
        steps = Workflows.list_workflow_steps(workflow_id)
        code = generate_workflow_module(workflow, steps)
        {:ok, code}
    end
  end

  @doc """
  Exports a full project scaffold as a map of file paths to contents.
  """
  @spec export_project(pos_integer()) :: {:ok, map()} | {:error, term()}
  def export_project(workspace_id) do
    templates = Templates.list_templates(workspace_id)
    workflows = Workflows.list_workflows(workspace_id)

    files = %{
      "mix.exs" => generate_mix_exs(workspace_id),
      "config/config.exs" => generate_config(),
      "lib/application.ex" => generate_application()
    }

    agent_files =
      Enum.reduce(templates, %{}, fn t, acc ->
        routes = Templates.list_routes(t.id)
        filename = "lib/agents/#{Macro.underscore(t.slug)}.ex"
        Map.put(acc, filename, generate_agent_module(t, routes))
      end)

    workflow_files =
      Enum.reduce(workflows, %{}, fn w, acc ->
        steps = Workflows.list_workflow_steps(w.id)
        filename = "lib/workflows/#{Macro.underscore(w.name)}.ex"
        Map.put(acc, filename, generate_workflow_module(w, steps))
      end)

    {:ok, Map.merge(files, Map.merge(agent_files, workflow_files))}
  end

  defp generate_agent_module(template, routes) do
    route_lines =
      Enum.map(routes, fn r ->
        ~s|    {"#{r.signal}", #{action_module_name(r.action)}}|
      end)
      |> Enum.join(",\n")

    """
    defmodule MyApp.Agents.#{Macro.camelize(template.slug)} do
      @moduledoc \"\"\"
      #{template.description || template.name}

      Exported from JidoBuilder template: #{template.name} v#{template.version}
      \"\"\"

      use Jido.Agent,
        name: "#{template.slug}",
        description: "#{template.description || template.name}"

      @routes [
    #{route_lines}
      ]

      def signal_routes(_agent), do: @routes
    end
    """
  end

  defp generate_workflow_module(workflow, steps) do
    step_lines =
      Enum.map(steps, fn s ->
        ~s|      %{name: "#{s.name}", kind: "#{s.kind}", config: #{inspect(s.config || %{})}}|
      end)
      |> Enum.join(",\n")

    """
    defmodule MyApp.Workflows.#{Macro.camelize(workflow.name)} do
      @moduledoc \"\"\"
      #{workflow.description || workflow.name}

      Exported from JidoBuilder workflow: #{workflow.name}
      \"\"\"

      def steps do
        [
    #{step_lines}
        ]
      end

      def execute(initial_state \\\\ %{}) do
        Enum.reduce(steps(), {:ok, initial_state}, fn step, acc ->
          case acc do
            {:ok, state} -> execute_step(step, state)
            error -> error
          end
        end)
      end

      defp execute_step(%{kind: "transform"} = step, state) do
        {:ok, Map.merge(state, step.config)}
      end

      defp execute_step(_step, state), do: {:ok, state}
    end
    """
  end

  defp generate_mix_exs(_workspace_id) do
    """
    defmodule MyApp.MixProject do
      use Mix.Project

      def project do
        [
          app: :my_app,
          version: "0.1.0",
          elixir: "~> 1.17",
          deps: deps()
        ]
      end

      def application do
        [extra_applications: [:logger], mod: {MyApp.Application, []}]
      end

      defp deps do
        [{:jido, "~> 2.2"}]
      end
    end
    """
  end

  defp generate_config do
    """
    import Config
    config :logger, level: :info
    """
  end

  defp generate_application do
    """
    defmodule MyApp.Application do
      use Application

      def start(_type, _args) do
        children = [MyApp.Jido]
        Supervisor.start_link(children, strategy: :one_for_one)
      end
    end
    """
  end

  defp action_module_name(slug) when is_binary(slug) do
    case ActionRegistry.get(slug) do
      %{module: mod} -> inspect(mod)
      _ -> "MyApp.Actions.#{Macro.camelize(slug)}"
    end
  end
end
