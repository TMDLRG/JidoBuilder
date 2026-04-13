defmodule JidoBuilderCore.Templates do
  import Ecto.Query

  alias JidoBuilderCore.Audit
  alias JidoBuilderCore.Repo

  alias JidoBuilderCore.Templates.{
    Template,
    TemplatePlugin,
    TemplateRoute,
    TemplateSchedule,
    TemplateSensor,
    TemplateStateField
  }

  def list_templates(workspace_id) do
    Template |> where([t], t.workspace_id == ^workspace_id) |> Repo.all()
  end

  def list_template_plugins(workspace_id) do
    from(tp in TemplatePlugin,
      join: t in assoc(tp, :template),
      where: t.workspace_id == ^workspace_id
    )
    |> Repo.all()
  end

  def update_plugin(plugin, attrs, actor) do
    plugin
    |> TemplatePlugin.changeset(attrs)
    |> Repo.update()
    |> maybe_audit(actor, "templates.plugins.update")
  end

  def list_template_sensors(workspace_id) do
    from(ts in TemplateSensor,
      join: t in assoc(ts, :template),
      where: t.workspace_id == ^workspace_id
    )
    |> Repo.all()
  end

  def update_sensor(sensor, attrs, actor) do
    sensor
    |> TemplateSensor.changeset(attrs)
    |> Repo.update()
    |> maybe_audit(actor, "templates.sensors.update")
  end

  def list_template_schedules(workspace_id) do
    from(ts in TemplateSchedule,
      join: t in assoc(ts, :template),
      where: t.workspace_id == ^workspace_id
    )
    |> Repo.all()
  end

  def update_schedule(schedule, attrs, actor) do
    schedule
    |> TemplateSchedule.changeset(attrs)
    |> Repo.update()
    |> maybe_audit(actor, "templates.schedules.update")
  end

  def get_template!(id), do: Repo.get!(Template, id)

  def create_template(attrs, actor) do
    %Template{}
    |> Template.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, "templates.create")
  end

  def update_template(template, attrs, actor) do
    template
    |> Template.changeset(attrs)
    |> Repo.update()
    |> maybe_audit(actor, "templates.update")
  end

  def delete_template(template, actor) do
    Repo.delete(template)
    |> maybe_audit(actor, "templates.delete")
  end

  def list_routes(template_id) when is_integer(template_id) do
    TemplateRoute
    |> where([r], r.template_id == ^template_id)
    |> order_by([r], asc: r.signal)
    |> Repo.all()
  end

  def create_route(attrs, actor),
    do: insert_with_audit(TemplateRoute, attrs, actor, "templates.routes.create")

  def create_state_field(attrs, actor),
    do: insert_with_audit(TemplateStateField, attrs, actor, "templates.state_fields.create")

  def create_schedule(attrs, actor),
    do: insert_with_audit(TemplateSchedule, attrs, actor, "templates.schedules.create")

  def create_plugin(attrs, actor),
    do: insert_with_audit(TemplatePlugin, attrs, actor, "templates.plugins.create")

  def create_sensor(attrs, actor),
    do: insert_with_audit(TemplateSensor, attrs, actor, "templates.sensors.create")

  defp insert_with_audit(schema, attrs, actor, action) do
    struct(schema)
    |> schema.changeset(attrs)
    |> Repo.insert()
    |> maybe_audit(actor, action)
  end

  defp maybe_audit({:ok, record} = ok, actor, action) do
    _ = Audit.log(actor, action, record, %{})
    ok
  end

  defp maybe_audit(error, _actor, _action), do: error
end
