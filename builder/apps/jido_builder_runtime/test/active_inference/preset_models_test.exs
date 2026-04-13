defmodule JidoBuilderRuntime.ActiveInference.PresetModelsTest do
  @moduledoc "Epic 1.5 — Preset models tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.ActiveInference.PresetModels
  alias Jido.ActiveInference.{GenerativeModel, BeliefState, FreeEnergy}

  describe "forager/0" do
    test "returns a valid generative model" do
      model = PresetModels.forager()

      assert %GenerativeModel{} = model
      assert model.num_states == 2
      assert model.num_observations == 2
      assert model.num_actions == 2
      assert model.policies != nil
    end

    test "forager prefers food over predators" do
      model = PresetModels.forager()
      belief = BeliefState.new(model)

      # Observe food_visible (idx 0)
      updated = BeliefState.update(belief, model, 0)
      [p_safe, _p_danger] = updated.posterior
      assert p_safe > 0.5
    end
  end

  describe "thermostat/0" do
    test "returns a valid 3-state model" do
      model = PresetModels.thermostat()

      assert %GenerativeModel{} = model
      assert model.num_states == 3
      assert model.num_observations == 3
      assert model.num_actions == 2
    end

    test "thermostat prefers normal temperature" do
      model = PresetModels.thermostat()
      # C vector should have highest preference for normal_reading (idx 1)
      assert Enum.at(model.c_vector, 1) > Enum.at(model.c_vector, 0)
      assert Enum.at(model.c_vector, 1) > Enum.at(model.c_vector, 2)
    end
  end

  describe "trader/0" do
    test "returns a valid generative model" do
      model = PresetModels.trader()

      assert %GenerativeModel{} = model
      assert model.num_states == 2
      assert model.num_observations == 2
    end

    test "evaluates policies with EFE" do
      model = PresetModels.trader()
      belief = BeliefState.new(model)

      efes = FreeEnergy.expected_free_energy(belief, model)
      assert length(efes) == 4
      assert Enum.all?(efes, &is_float/1)
    end
  end

  describe "t_maze/0" do
    test "returns a valid 4-state model" do
      model = PresetModels.t_maze()

      assert %GenerativeModel{} = model
      assert model.num_states == 4
      assert model.num_observations == 3
      assert model.num_actions == 3
    end

    test "t_maze strongly prefers reward over punishment" do
      model = PresetModels.t_maze()
      # C vector: [neutral, reward, punishment]
      assert Enum.at(model.c_vector, 1) > Enum.at(model.c_vector, 2)
    end
  end

  describe "list/0" do
    test "returns all preset models" do
      presets = PresetModels.list()

      assert length(presets) == 4
      names = Enum.map(presets, & &1.name)
      assert "Forager" in names
      assert "Thermostat" in names
      assert "Trader" in names
      assert "T-Maze" in names
    end
  end
end
