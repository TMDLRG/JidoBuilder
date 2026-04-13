defmodule JidoBuilderRuntime.ActiveInference.ModelBuilderTest do
  @moduledoc "Epic 1.5 — Model builder tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.ActiveInference.ModelBuilder
  alias Jido.ActiveInference.GenerativeModel

  describe "builder pipeline" do
    test "builds a valid generative model from named components" do
      model =
        ModelBuilder.new()
        |> ModelBuilder.set_states([:safe, :danger])
        |> ModelBuilder.set_observations([:green, :red])
        |> ModelBuilder.set_actions([:stay, :move])
        |> ModelBuilder.set_likelihood(:green, :safe, 0.8)
        |> ModelBuilder.set_likelihood(:green, :danger, 0.2)
        |> ModelBuilder.set_likelihood(:red, :safe, 0.2)
        |> ModelBuilder.set_likelihood(:red, :danger, 0.8)
        |> ModelBuilder.set_transition(:stay, :safe, :safe, 0.9)
        |> ModelBuilder.set_transition(:stay, :safe, :danger, 0.1)
        |> ModelBuilder.set_transition(:stay, :danger, :safe, 0.1)
        |> ModelBuilder.set_transition(:stay, :danger, :danger, 0.9)
        |> ModelBuilder.set_transition(:move, :safe, :safe, 0.3)
        |> ModelBuilder.set_transition(:move, :safe, :danger, 0.7)
        |> ModelBuilder.set_transition(:move, :danger, :safe, 0.7)
        |> ModelBuilder.set_transition(:move, :danger, :danger, 0.3)
        |> ModelBuilder.set_preference(:green, 2.0)
        |> ModelBuilder.set_preference(:red, -2.0)
        |> ModelBuilder.build()

      assert %GenerativeModel{} = model
      assert model.num_states == 2
      assert model.num_observations == 2
      assert model.num_actions == 2
      assert model.policies != nil
    end

    test "auto-generates single-step policies when none specified" do
      model =
        ModelBuilder.new()
        |> ModelBuilder.set_states([:a, :b])
        |> ModelBuilder.set_observations([:x, :y])
        |> ModelBuilder.set_actions([:act1, :act2])
        |> ModelBuilder.build()

      assert %GenerativeModel{} = model
      # Auto policies: [[0], [1]]
      assert length(model.policies) == 2
      assert model.planning_horizon == 1
    end

    test "converts named policies to indices" do
      model =
        ModelBuilder.new()
        |> ModelBuilder.set_states([:a, :b])
        |> ModelBuilder.set_observations([:x, :y])
        |> ModelBuilder.set_actions([:act1, :act2])
        |> ModelBuilder.set_policies([[:act1, :act2], [:act2, :act1]])
        |> ModelBuilder.build()

      assert model.policies == [[0, 1], [1, 0]]
      assert model.planning_horizon == 2
    end

    test "rejects empty states" do
      result =
        ModelBuilder.new()
        |> ModelBuilder.set_states([])
        |> ModelBuilder.set_observations([:x])
        |> ModelBuilder.set_actions([:a])
        |> ModelBuilder.build()

      assert {:error, _} = result
    end

    test "uses uniform defaults for unset probabilities" do
      model =
        ModelBuilder.new()
        |> ModelBuilder.set_states([:a, :b])
        |> ModelBuilder.set_observations([:x, :y])
        |> ModelBuilder.set_actions([:act1])
        |> ModelBuilder.build()

      assert %GenerativeModel{} = model
      # With uniform defaults, should still be a valid model
      assert model.num_states == 2
    end

    test "set_prior biases initial beliefs" do
      model =
        ModelBuilder.new()
        |> ModelBuilder.set_states([:a, :b])
        |> ModelBuilder.set_observations([:x, :y])
        |> ModelBuilder.set_actions([:act1])
        |> ModelBuilder.set_prior(:a, 0.9)
        |> ModelBuilder.set_prior(:b, 0.1)
        |> ModelBuilder.build()

      assert %GenerativeModel{} = model
      [p_a, p_b] = model.d_vector
      assert p_a > p_b
    end
  end
end
