defmodule JidoBuilderCore.WorkflowsEdgesTest do
  use ExUnit.Case, async: true

  alias JidoBuilderCore.Workflows.WorkflowEdge

  test "workflow edge changeset validates required fields" do
    changeset = WorkflowEdge.changeset(%WorkflowEdge{}, %{})
    refute changeset.valid?
    assert %{workflow_id: ["can't be blank"]} = errors_on(changeset)
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
