defmodule JidoBuilderCore.SchemaAndContextTest do
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Audit, Repo, Workflows}
  alias JidoBuilderCore.Agents.Workspace

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ok
  end

  describe "schema changesets" do
    test "workspace changeset enforces required fields" do
      changeset = Workspace.changeset(%Workspace{}, %{})

      refute changeset.valid?
      assert %{name: ["can't be blank"], slug: ["can't be blank"]} = errors_on(changeset)
    end

    test "workspace changeset accepts valid attrs" do
      changeset = Workspace.changeset(%Workspace{}, %{name: "Core", slug: unique_slug()})

      assert changeset.valid?
    end
  end

  describe "context modules" do
    test "agents context writes rows and audit events" do
      {:ok, workspace} = Agents.create_workspace(%{name: "Ctx", slug: unique_slug()}, "tester")

      {:ok, workflow} =
        Workflows.create_workflow(
          %{workspace_id: workspace.id, name: "WF", status: "running", metadata: %{k: "v"}},
          "tester"
        )

      assert workflow.workspace_id == workspace.id
      assert workflow.name == "WF"

      events = Audit.list_audit_events(%{workspace_id: workspace.id})
      actions = Enum.map(events, & &1.action)

      assert "agents.workspaces.create" in actions
      assert "workflows.create" in actions
    end
  end

  describe "audit api" do
    test "audit list is ordered newest first" do
      {:ok, workspace} = Agents.create_workspace(%{name: "Audit", slug: unique_slug()}, "tester")

      {:ok, _wf1} =
        Workflows.create_workflow(%{workspace_id: workspace.id, name: "A", status: "queued"}, "a")

      {:ok, _wf2} =
        Workflows.create_workflow(%{workspace_id: workspace.id, name: "B", status: "queued"}, "b")

      [first, second | _] = Audit.list_audit_events(%{workspace_id: workspace.id})
      assert DateTime.compare(first.occurred_at, second.occurred_at) in [:gt, :eq]
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp unique_slug, do: "ws-#{System.unique_integer([:positive])}"
end
