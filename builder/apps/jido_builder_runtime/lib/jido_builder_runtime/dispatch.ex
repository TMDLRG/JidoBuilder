defmodule JidoBuilderRuntime.Dispatch do
  @moduledoc """
  Resolves template route rows into executable action modules.

  Route actions are strict allow-listed by action slug via
  `Jido.Discovery.get_action_by_slug/1`.
  """

  import Ecto.Query

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Templates.TemplateRoute
  alias JidoBuilderRuntime.Error

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  @spec resolve_route(pos_integer(), String.t(), [String.t()]) ::
          result(%{module: module(), opts: map()})
  def resolve_route(template_id, signal_type, enabled_action_slugs \\ [])
      when is_integer(template_id) and is_binary(signal_type) and is_list(enabled_action_slugs) do
    with {:ok, route} <- fetch_route(template_id, signal_type),
         :ok <- ensure_allowed(route.action, enabled_action_slugs),
         {:ok, module} <- resolve_action_module(route.action) do
      {:ok, %{module: module, opts: route.opts || %{}}}
    end
  end

  @spec resolve_module_by_slug(String.t(), [String.t()]) :: result(module())
  def resolve_module_by_slug(slug, enabled_action_slugs \\ []) when is_binary(slug) do
    with :ok <- ensure_allowed(slug, enabled_action_slugs),
         {:ok, module} <- resolve_action_module(slug) do
      {:ok, module}
    end
  end

  defp fetch_route(template_id, signal_type) do
    TemplateRoute
    |> where([r], r.template_id == ^template_id and r.signal == ^signal_type)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil ->
        {:error,
         Error.new(:route_not_found, "no matching route for signal", %{
           template_id: template_id,
           signal: signal_type
         })}

      %TemplateRoute{} = route ->
        {:ok, route}
    end
  end

  defp ensure_allowed(_slug, []), do: :ok

  defp ensure_allowed(slug, enabled_action_slugs) do
    if slug in enabled_action_slugs do
      :ok
    else
      {:error,
       Error.new(:action_not_allowed, "action slug is not enabled for template", %{
         action_slug: slug
       })}
    end
  end

  defp resolve_action_module(slug) do
    case Jido.Discovery.get_action_by_slug(slug) do
      %{module: module} when is_atom(module) ->
        {:ok, module}

      _ ->
        {:error, Error.new(:unknown_action_slug, "unknown action slug", %{action_slug: slug})}
    end
  end
end
