defmodule JidoBuilderWeb.MCP.Tools.ActiveInferenceTool do
  @moduledoc "MCP tool: jido_active_inference — create models, update beliefs, evaluate policies."

  alias JidoBuilderRuntime.ActiveInference.PresetModels
  alias Jido.ActiveInference.{BeliefState, FreeEnergy}

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}

  def call(%{"action" => "presets"}, _ctx) do
    {:ok, PresetModels.list()}
  end

  def call(%{"action" => "create_model", "preset" => preset}, _ctx) do
    model = case preset do
      "forager" -> PresetModels.forager()
      "thermostat" -> PresetModels.thermostat()
      "trader" -> PresetModels.trader()
      "t_maze" -> PresetModels.t_maze()
      _ -> nil
    end

    if model do
      {:ok, %{
        preset: preset,
        num_states: model.num_states,
        num_observations: model.num_observations,
        num_actions: model.num_actions,
        policies: length(model.policies || []),
        created: true
      }}
    else
      {:error, "Unknown preset: #{preset}"}
    end
  end

  def call(%{"action" => "evaluate", "preset" => preset, "observation" => obs}, _ctx) do
    model = case preset do
      "forager" -> PresetModels.forager()
      "thermostat" -> PresetModels.thermostat()
      "trader" -> PresetModels.trader()
      "t_maze" -> PresetModels.t_maze()
      _ -> nil
    end

    if model do
      belief = BeliefState.new(model)
      updated = BeliefState.update(belief, model, obs)
      efes = FreeEnergy.expected_free_energy(updated, model)
      best_idx = efes |> Enum.with_index() |> Enum.min_by(&elem(&1, 0)) |> elem(1)

      {:ok, %{
        posterior: updated.posterior,
        entropy: BeliefState.entropy(updated),
        surprise: BeliefState.surprise(belief, model, obs),
        efe_scores: efes,
        best_policy_index: best_idx,
        best_policy: Enum.at(model.policies, best_idx)
      }}
    else
      {:error, "Unknown preset: #{preset}"}
    end
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_active_inference — Active Inference operations

    Actions:
      presets                          — List available preset models
      create_model {preset}            — Create a model from preset
      evaluate {preset, observation}   — Update beliefs and evaluate policies
      help                             — Show this help
    """
  end
end
