defmodule JidoBuilderRuntime.DynamicAgent do
  @moduledoc """
  Template-backed runtime agent.

  This agent keeps runtime state/config and delegates signal dispatch resolution
  to `JidoBuilderRuntime.Dispatch` using DB route rows.
  """

  use Jido.Agent,
    name: "builder_dynamic_agent",
    description: "Template-driven runtime agent",
    schema: [
      template_id: [type: :integer, required: true],
      enabled_action_slugs: [type: {:list, :string}, default: []],
      runtime_state: [type: :map, default: %{}]
    ]

  alias JidoBuilderCore.Templates.Template
  alias JidoBuilderCore.Repo
  alias JidoBuilderRuntime.{Dispatch, DynamicPlugin, DynamicSensor, Error}

  @spec from_template(pos_integer(), map()) :: {:ok, t()} | {:error, Error.t()}
  def from_template(template_id, attrs \\ %{}) when is_integer(template_id) and is_map(attrs) do
    with %Template{} <-
           Repo.get(Template, template_id) ||
             {:error,
              Error.new(:template_not_found, "template not found", %{template_id: template_id})},
         {:ok, action_slugs} <- action_slug_allow_list(template_id),
         {:ok, plugins} <- DynamicPlugin.mounts_for_template(template_id),
         {:ok, sensors} <- DynamicSensor.mounts_for_template(template_id) do
      new_attrs =
        attrs
        |> Map.put(:template_id, template_id)
        |> Map.put_new(:enabled_action_slugs, action_slugs)
        |> Map.put_new(:runtime_state, %{plugins: plugins, sensors: sensors})

      __MODULE__.new(new_attrs)
      |> case do
        {:ok, agent} ->
          {:ok, agent}

        {:error, reason} ->
          {:error,
           Error.new(:agent_build_failed, "unable to build dynamic agent", %{
             reason: inspect(reason)
           })}
      end
    else
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  @spec dispatch_action(t(), String.t()) :: {:ok, module()} | {:error, Error.t()}
  def dispatch_action(
        %__MODULE__{template_id: template_id, enabled_action_slugs: slugs},
        signal_type
      ) do
    with {:ok, %{module: module}} <- Dispatch.resolve_route(template_id, signal_type, slugs) do
      {:ok, module}
    end
  end

  defp action_slug_allow_list(template_id) do
    import Ecto.Query
    alias JidoBuilderCore.Templates.TemplateRoute

    slugs =
      TemplateRoute
      |> where([r], r.template_id == ^template_id)
      |> select([r], r.action)
      |> Repo.all()
      |> Enum.uniq()

    {:ok, slugs}
  end
end
