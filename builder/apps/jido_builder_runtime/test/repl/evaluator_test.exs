defmodule JidoBuilderRuntime.Repl.EvaluatorTest do
  @moduledoc "Epic 5.3 — Live REPL evaluator tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Repl.Evaluator

  describe "new/0" do
    test "creates empty evaluator" do
      eval = Evaluator.new()
      assert eval.bindings == []
      assert eval.results == []
      assert eval.cell_count == 0
    end
  end

  describe "eval/3" do
    test "evaluates simple expression" do
      eval = Evaluator.new()
      {:ok, result, _eval} = Evaluator.eval(eval, "1 + 2")
      assert result == 3
    end

    test "persists bindings across cells" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "x = 10")
      {:ok, result, _eval} = Evaluator.eval(eval, "x * 2")
      assert result == 20
    end

    test "tracks cell results" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "1 + 1")
      {:ok, _, eval} = Evaluator.eval(eval, "2 + 2")

      results = Evaluator.results(eval)
      assert length(results) == 2
      assert Enum.all?(results, fn r -> r.status == :ok end)
    end

    test "increments cell count" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "1")
      {:ok, _, eval} = Evaluator.eval(eval, "2")
      assert eval.cell_count == 2
    end

    test "handles errors gracefully" do
      eval = Evaluator.new()
      {:error, reason, eval} = Evaluator.eval(eval, "1 / 0")

      assert is_binary(reason)
      assert eval.cell_count == 1
      [result] = eval.results
      assert result.status == :error
    end

    test "handles syntax errors" do
      eval = Evaluator.new()
      {:error, _reason, _eval} = Evaluator.eval(eval, "def foo(")
    end

    test "respects timeout" do
      eval = Evaluator.new()
      {:error, reason, _eval} = Evaluator.eval(eval, "Process.sleep(5000)", timeout: 100)
      assert String.contains?(reason, "timed out")
    end

    test "can use Jido modules" do
      eval = Evaluator.new()
      {:ok, result, _eval} = Evaluator.eval(eval, "Jido.ActiveInference.GenerativeModel.new(%{a_matrix: [[0.5, 0.5]], b_matrix: [[[0.5, 0.5], [0.5, 0.5]]], c_vector: [0.0], d_vector: [0.5, 0.5]})")
      assert is_struct(result)
    end

    test "complex multi-cell workflow" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "list = [1, 2, 3, 4, 5]")
      {:ok, _, eval} = Evaluator.eval(eval, "sum = Enum.sum(list)")
      {:ok, result, _eval} = Evaluator.eval(eval, "sum / length(list)")
      assert result == 3.0
    end
  end

  describe "bindings/1" do
    test "returns current bindings" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "x = 42")
      bindings = Evaluator.bindings(eval)
      assert Keyword.get(bindings, :x) == 42
    end
  end

  describe "reset/1" do
    test "clears all state" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "x = 1")
      reset = Evaluator.reset(eval)
      assert reset.bindings == []
      assert reset.cell_count == 0
    end
  end

  describe "export/2" do
    test "exports cells as module" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "x = 42")
      {:ok, _, eval} = Evaluator.eval(eval, "y = x + 1")

      export = Evaluator.export(eval, "MyNotebook")
      assert String.contains?(export, "defmodule MyNotebook")
      assert String.contains?(export, "x = 42")
      assert String.contains?(export, "y = x + 1")
    end

    test "skips error cells in export" do
      eval = Evaluator.new()
      {:ok, _, eval} = Evaluator.eval(eval, "x = 1")
      {:error, _, eval} = Evaluator.eval(eval, "1 / 0")
      {:ok, _, eval} = Evaluator.eval(eval, "y = 2")

      export = Evaluator.export(eval)
      refute String.contains?(export, "1 / 0")
    end
  end
end
