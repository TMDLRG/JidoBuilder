defmodule JidoBuilderRuntime.WorkflowStrategiesTest do
  use ExUnit.Case, async: false

  alias JidoBuilderRuntime.WorkflowStrategies.{Action, Condition, Emit, Transform}

  describe "Transform strategy" do
    test "merge operation combines value into state" do
      step = %{config: %{"operation" => "merge", "value" => %{"x" => 1, "y" => 2}}}
      state = %{existing: true}

      assert {:ok, result} = Transform.execute(step, state)
      assert result[:x] == 1
      assert result[:y] == 2
    end

    test "filter operation keeps only specified keys" do
      step = %{config: %{"operation" => "filter", "keys" => [:a, :b]}}
      state = %{a: 1, b: 2, c: 3}

      assert {:ok, result} = Transform.execute(step, state)
      assert result == %{a: 1, b: 2}
    end

    test "defaults to merge when no operation specified" do
      step = %{config: %{"value" => %{"default" => true}}}
      state = %{}

      assert {:ok, result} = Transform.execute(step, state)
      assert result[:default] == true
    end
  end

  describe "Condition strategy" do
    test "returns condition_met: true when field matches expected" do
      step = %{config: %{"field" => "status", "expected" => "active"}}
      state = %{"status" => "active"}

      assert {:ok, %{condition_met: true}} = Condition.execute(step, state)
    end

    test "returns condition_met: false when field does not match" do
      step = %{config: %{"field" => "status", "expected" => "active"}}
      state = %{"status" => "inactive"}

      assert {:ok, %{condition_met: false}} = Condition.execute(step, state)
    end

    test "returns condition_met: false when field is missing" do
      step = %{config: %{"field" => "missing_field", "expected" => "value"}}
      state = %{}

      assert {:ok, %{condition_met: false}} = Condition.execute(step, state)
    end
  end

  describe "Action strategy" do
    test "executes a resolved action module and returns result" do
      # Echo action is a real module that returns {:ok, %{echo: params}}
      step = %{
        config: %{
          "action_module" => "Elixir.JidoBuilderRuntime.Actions.Echo",
          "params" => %{"message" => "hello"}
        }
      }

      state = %{}

      assert {:ok, result} = Action.execute(step, state)
      assert result[:echo] == "hello"
    end

    test "returns error for invalid action module" do
      step = %{config: %{"action_module" => "Elixir.NonExistent.Module"}}
      state = %{}

      assert {:error, _} = Action.execute(step, state)
    end
  end

  describe "Emit strategy" do
    test "returns signal data for downstream processing" do
      step = %{
        config: %{
          "signal_type" => "notify.user",
          "payload" => %{"user_id" => 42}
        }
      }

      state = %{context: "test"}

      assert {:ok, result} = Emit.execute(step, state)
      assert result[:emitted_signal_type] == "notify.user"
      assert result[:emitted_payload] == %{"user_id" => 42}
    end
  end
end
