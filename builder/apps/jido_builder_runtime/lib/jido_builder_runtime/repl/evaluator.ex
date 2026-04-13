defmodule JidoBuilderRuntime.Repl.Evaluator do
  @moduledoc """
  Sandboxed code evaluator for the Notebook editor.

  Evaluates Elixir code strings with binding persistence across cells,
  timeout protection, and Jido module access.
  """

  @default_timeout 10_000

  defstruct [
    bindings: [],
    env: nil,
    results: [],
    cell_count: 0
  ]

  @type t :: %__MODULE__{
          bindings: keyword(),
          env: Macro.Env.t() | nil,
          results: [map()],
          cell_count: non_neg_integer()
        }

  @doc "Create a new evaluator with empty bindings."
  @spec new() :: t()
  def new do
    %__MODULE__{
      bindings: [],
      env: __ENV__,
      results: [],
      cell_count: 0
    }
  end

  @doc """
  Evaluate a code cell.

  Returns `{:ok, result, updated_evaluator}` or `{:error, reason, evaluator}`.
  Bindings persist across calls.
  """
  @spec eval(t(), String.t(), keyword()) :: {:ok, term(), t()} | {:error, term(), t()}
  def eval(%__MODULE__{} = evaluator, code, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    task = Task.async(fn ->
      try do
        {result, new_bindings} = Code.eval_string(code, evaluator.bindings)
        {:ok, result, new_bindings}
      rescue
        e -> {:error, Exception.message(e)}
      catch
        kind, reason -> {:error, "#{kind}: #{inspect(reason)}"}
      end
    end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, {:ok, result, new_bindings}} ->
        cell_result = %{
          cell: evaluator.cell_count + 1,
          code: code,
          result: inspect(result),
          status: :ok
        }

        updated = %{evaluator |
          bindings: new_bindings,
          results: evaluator.results ++ [cell_result],
          cell_count: evaluator.cell_count + 1
        }

        {:ok, result, updated}

      {:ok, {:error, reason}} ->
        cell_result = %{
          cell: evaluator.cell_count + 1,
          code: code,
          error: reason,
          status: :error
        }

        updated = %{evaluator |
          results: evaluator.results ++ [cell_result],
          cell_count: evaluator.cell_count + 1
        }

        {:error, reason, updated}

      nil ->
        cell_result = %{
          cell: evaluator.cell_count + 1,
          code: code,
          error: "Evaluation timed out after #{timeout}ms",
          status: :timeout
        }

        updated = %{evaluator |
          results: evaluator.results ++ [cell_result],
          cell_count: evaluator.cell_count + 1
        }

        {:error, "Evaluation timed out", updated}
    end
  end

  @doc "Get the current bindings."
  @spec bindings(t()) :: keyword()
  def bindings(%__MODULE__{bindings: b}), do: b

  @doc "Get all cell results."
  @spec results(t()) :: [map()]
  def results(%__MODULE__{results: r}), do: r

  @doc "Reset the evaluator to a clean state."
  @spec reset(t()) :: t()
  def reset(%__MODULE__{}), do: new()

  @doc "Export all code cells as a single module string."
  @spec export(t(), String.t()) :: String.t()
  def export(%__MODULE__{results: results}, module_name \\ "Notebook.Export") do
    code_cells =
      results
      |> Enum.filter(fn r -> r.status == :ok end)
      |> Enum.map(fn r -> r.code end)
      |> Enum.join("\n\n")

    """
    defmodule #{module_name} do
      @moduledoc "Exported from JidoBuilder Notebook"

    #{indent(code_cells, 2)}
    end
    """
    |> String.trim()
  end

  defp indent(text, spaces) do
    prefix = String.duplicate(" ", spaces)
    text
    |> String.split("\n")
    |> Enum.map_join("\n", fn line ->
      if String.trim(line) == "", do: "", else: prefix <> line
    end)
  end
end
