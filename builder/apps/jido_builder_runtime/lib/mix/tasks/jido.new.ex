defmodule Mix.Tasks.Jido.New do
  @moduledoc """
  Generates a standalone Jido project from a workspace.

  ## Usage

      mix jido.new /path/to/project --workspace-id 1

  Creates a project directory with mix.exs, config, lib/agents/, and lib/workflows/
  based on the templates and workflows in the specified workspace.
  """
  use Mix.Task

  @shortdoc "Generate a standalone Jido project from a workspace"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, _} =
      OptionParser.parse(args, strict: [workspace_id: :integer])

    target_dir =
      case positional do
        [dir | _] -> dir
        [] -> Mix.raise("Usage: mix jido.new /path/to/project --workspace-id N")
      end

    workspace_id = opts[:workspace_id] || 1

    {:ok, files} = JidoBuilderRuntime.Exporter.export_project(workspace_id)

    File.mkdir_p!(target_dir)
    File.mkdir_p!(Path.join(target_dir, "lib"))
    File.mkdir_p!(Path.join(target_dir, "lib/agents"))
    File.mkdir_p!(Path.join(target_dir, "lib/workflows"))
    File.mkdir_p!(Path.join(target_dir, "config"))

    Enum.each(files, fn {path, content} ->
      full_path = Path.join(target_dir, path)
      File.mkdir_p!(Path.dirname(full_path))
      File.write!(full_path, content)
      Mix.shell().info("  created #{path}")
    end)

    Mix.shell().info("\nProject generated at #{target_dir}")
  end
end
