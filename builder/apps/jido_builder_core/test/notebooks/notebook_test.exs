defmodule JidoBuilderCore.Notebooks.NotebookTest do
  @moduledoc "Epic 5.2 — Notebook Ecto schema tests."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.Repo
  alias JidoBuilderCore.Notebooks.Notebook
  alias JidoBuilderCore.Agents.Workspace

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    {:ok, workspace} =
      Repo.insert(%Workspace{
        name: "Notebook Workspace",
        slug: "notebook-ws-#{System.unique_integer([:positive])}",
        metadata: %{}
      })

    %{workspace: workspace}
  end

  describe "changeset/2" do
    test "valid changeset", %{workspace: ws} do
      changeset = Notebook.changeset(%Notebook{}, %{
        workspace_id: ws.id,
        name: "My Notebook"
      })
      assert changeset.valid?
    end

    test "invalid without name" do
      changeset = Notebook.changeset(%Notebook{}, %{})
      refute changeset.valid?
    end

    test "persists with cells", %{workspace: ws} do
      cells = [
        %{"type" => "markdown", "content" => "# Hello"},
        %{"type" => "code", "content" => "1 + 1", "output" => "2"},
        %{"type" => "code", "content" => "x = 42", "output" => "42"}
      ]

      {:ok, notebook} =
        %Notebook{}
        |> Notebook.changeset(%{
          workspace_id: ws.id,
          name: "Test Notebook",
          description: "A test notebook",
          cells: cells,
          metadata: %{language: "elixir"}
        })
        |> Repo.insert()

      assert notebook.id != nil
      assert length(notebook.cells) == 3
    end

    test "loads from database", %{workspace: ws} do
      {:ok, notebook} =
        %Notebook{}
        |> Notebook.changeset(%{
          workspace_id: ws.id,
          name: "Loadable Notebook",
          cells: [%{"type" => "code", "content" => "IO.puts(:hello)"}]
        })
        |> Repo.insert()

      loaded = Repo.get!(Notebook, notebook.id)
      assert loaded.name == "Loadable Notebook"
      assert length(loaded.cells) == 1
    end
  end
end
