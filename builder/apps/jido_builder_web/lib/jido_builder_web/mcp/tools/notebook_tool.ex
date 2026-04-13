defmodule JidoBuilderWeb.MCP.Tools.NotebookTool do
  @moduledoc "MCP tool: jido_notebook — create, run cells, export."

  alias JidoBuilderRuntime.Repl.Evaluator

  # Keep a process-local evaluator for the MCP session
  @eval_key :mcp_notebook_evaluator

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}

  def call(%{"action" => "create"} = args, _ctx) do
    name = args["name"] || "Untitled Notebook"
    Process.put(@eval_key, Evaluator.new())
    {:ok, %{name: name, created: true, cells: 0}}
  end

  def call(%{"action" => "run_cell", "code" => code}, _ctx) do
    eval = Process.get(@eval_key) || Evaluator.new()

    case Evaluator.eval(eval, code, timeout: 10_000) do
      {:ok, result, updated} ->
        Process.put(@eval_key, updated)
        {:ok, %{cell: updated.cell_count, result: inspect(result), status: "ok"}}

      {:error, reason, updated} ->
        Process.put(@eval_key, updated)
        {:ok, %{cell: updated.cell_count, error: reason, status: "error"}}
    end
  end

  def call(%{"action" => "list_cells"}, _ctx) do
    eval = Process.get(@eval_key) || Evaluator.new()
    {:ok, %{cells: Evaluator.results(eval), count: eval.cell_count}}
  end

  def call(%{"action" => "export"} = args, _ctx) do
    eval = Process.get(@eval_key) || Evaluator.new()
    module_name = args["module_name"] || "Notebook.Export"
    {:ok, %{code: Evaluator.export(eval, module_name)}}
  end

  def call(%{"action" => "reset"}, _ctx) do
    Process.put(@eval_key, Evaluator.new())
    {:ok, %{reset: true}}
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_notebook — Interactive notebook operations

    Actions:
      create {name}           — Create a new notebook session
      run_cell {code}         — Execute an Elixir code cell
      list_cells              — List all cell results
      export {module_name}    — Export cells as an Elixir module
      reset                   — Reset the notebook session
      help                    — Show this help
    """
  end
end
