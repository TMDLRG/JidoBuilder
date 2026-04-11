defmodule JidoBuilderCore.Repo.Migrations.CreateBuilderCoreTables do
  use Ecto.Migration

  def change do
    create table(:workspaces) do
      add :name, :text, null: false
      add :slug, :text, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:workspaces, [:slug])

    create table(:partitions) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :key, :text, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:partitions, [:workspace_id, :key])

    create table(:templates) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :partition_id, references(:partitions, on_delete: :nilify_all)
      add :name, :text, null: false
      add :slug, :text, null: false
      add :description, :text
      add :version, :text, null: false
      add :status, :text, null: false
      add :config, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:templates, [:workspace_id, :slug])

    create table(:template_routes) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :signal, :text, null: false
      add :target, :text, null: false
      add :action, :text, null: false
      add :opts, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:template_state_fields) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :field_name, :text, null: false
      add :field_type, :text, null: false
      add :required, :boolean, null: false, default: false
      add :default_value, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:template_schedules) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :cron, :text, null: false
      add :timezone, :text
      add :enabled, :boolean, null: false, default: true
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:templates_plugins) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :module, :text, null: false
      add :config, :map, null: false, default: %{}
      add :enabled, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create table(:templates_sensors) do
      add :template_id, references(:templates, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :module, :text, null: false
      add :config, :map, null: false, default: %{}
      add :enabled, :boolean, null: false, default: true

      timestamps(type: :utc_datetime_usec)
    end

    create table(:agent_instances) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :partition_id, references(:partitions, on_delete: :nilify_all)
      add :template_id, references(:templates, on_delete: :nilify_all)
      add :name, :text, null: false
      add :status, :text, null: false
      add :runtime_pid, :text
      add :state, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :last_seen_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create table(:signal_logs) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :agent_instance_id, references(:agent_instances, on_delete: :nilify_all)
      add :template_id, references(:templates, on_delete: :nilify_all)
      add :direction, :text, null: false
      add :signal_type, :text, null: false
      add :payload, :map, null: false, default: %{}
      add :correlation_id, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create table(:directive_logs) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :agent_instance_id, references(:agent_instances, on_delete: :nilify_all)
      add :directive_type, :text, null: false
      add :status, :text, null: false
      add :payload, :map, null: false, default: %{}
      add :correlation_id, :text

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create table(:integrations) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :provider, :text, null: false
      add :status, :text, null: false
      add :config, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:secrets) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :integration_id, references(:integrations, on_delete: :nilify_all)
      add :name, :text, null: false
      add :encrypted_value, :text, null: false
      add :key_id, :text
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:workflows) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :description, :text
      add :status, :text, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:workflow_steps) do
      add :workflow_id, references(:workflows, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :step_order, :integer, null: false
      add :kind, :text, null: false
      add :config, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:pod_topologies) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :name, :text, null: false
      add :strategy, :text, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:pod_nodes) do
      add :pod_topology_id, references(:pod_topologies, on_delete: :delete_all), null: false
      add :agent_instance_id, references(:agent_instances, on_delete: :nilify_all)
      add :name, :text, null: false
      add :role, :text, null: false
      add :position, :integer, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:generated_modules) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :template_id, references(:templates, on_delete: :nilify_all)
      add :workflow_id, references(:workflows, on_delete: :nilify_all)
      add :module_name, :text, null: false
      add :source_hash, :text, null: false
      add :file_path, :text
      add :compiled_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:generated_modules, [:module_name])

    create table(:snapshots) do
      add :workspace_id, references(:workspaces, on_delete: :delete_all), null: false
      add :agent_instance_id, references(:agent_instances, on_delete: :delete_all), null: false
      add :hibernate_metadata, :map, null: false, default: %{}
      add :thaw_metadata, :map, null: false, default: %{}
      add :captured_at, :utc_datetime_usec, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create table(:audit_events) do
      add :workspace_id, references(:workspaces, on_delete: :nilify_all)
      add :actor, :text
      add :action, :text, null: false
      add :entity_type, :text, null: false
      add :entity_id, :text, null: false
      add :metadata, :map, null: false, default: %{}
      add :occurred_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end
  end
end
