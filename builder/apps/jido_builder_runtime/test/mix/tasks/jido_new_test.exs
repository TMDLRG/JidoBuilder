defmodule Mix.Tasks.Jido.NewTest do
  @moduledoc "Story 9.1 — mix jido.new generates project scaffold."
  use ExUnit.Case, async: false

  alias JidoBuilderCore.{Agents, Repo}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})

    {:ok, workspace} =
      Agents.create_workspace(
        %{name: "mix-new-#{System.unique_integer()}", slug: "mix-new-#{System.unique_integer()}"},
        "test"
      )

    tmp_dir = Path.join(System.tmp_dir!(), "jido_new_test_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    %{workspace: workspace, tmp_dir: tmp_dir}
  end

  test "generates project directory with mix.exs", %{workspace: workspace, tmp_dir: tmp_dir} do
    Mix.Tasks.Jido.New.run([tmp_dir, "--workspace-id", to_string(workspace.id)])

    assert File.exists?(tmp_dir)
    assert File.exists?(Path.join(tmp_dir, "mix.exs"))
  end

  test "generated directory includes lib folder", %{workspace: workspace, tmp_dir: tmp_dir} do
    Mix.Tasks.Jido.New.run([tmp_dir, "--workspace-id", to_string(workspace.id)])

    assert File.dir?(Path.join(tmp_dir, "lib"))
  end
end
