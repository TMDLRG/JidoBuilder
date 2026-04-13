defmodule JidoBuilderRuntime.ActiveInference.PresetModels do
  @moduledoc """
  Pre-built Active Inference generative models for common scenarios.

  These presets demonstrate Active Inference principles and serve as
  starting points for custom agent development.
  """

  alias JidoBuilderRuntime.ActiveInference.ModelBuilder

  @doc """
  Forager agent — seeks food while avoiding predators.

  2 states: :safe_with_food, :danger
  2 observations: :food_visible, :predator_visible
  2 actions: :forage, :hide
  """
  @spec forager() :: Jido.ActiveInference.GenerativeModel.t()
  def forager do
    ModelBuilder.new()
    |> ModelBuilder.set_states([:safe_with_food, :danger])
    |> ModelBuilder.set_observations([:food_visible, :predator_visible])
    |> ModelBuilder.set_actions([:forage, :hide])
    |> ModelBuilder.set_likelihood(:food_visible, :safe_with_food, 0.9)
    |> ModelBuilder.set_likelihood(:food_visible, :danger, 0.1)
    |> ModelBuilder.set_likelihood(:predator_visible, :safe_with_food, 0.1)
    |> ModelBuilder.set_likelihood(:predator_visible, :danger, 0.9)
    |> ModelBuilder.set_transition(:forage, :safe_with_food, :safe_with_food, 0.7)
    |> ModelBuilder.set_transition(:forage, :safe_with_food, :danger, 0.3)
    |> ModelBuilder.set_transition(:forage, :danger, :safe_with_food, 0.2)
    |> ModelBuilder.set_transition(:forage, :danger, :danger, 0.8)
    |> ModelBuilder.set_transition(:hide, :safe_with_food, :safe_with_food, 0.5)
    |> ModelBuilder.set_transition(:hide, :safe_with_food, :danger, 0.5)
    |> ModelBuilder.set_transition(:hide, :danger, :safe_with_food, 0.6)
    |> ModelBuilder.set_transition(:hide, :danger, :danger, 0.4)
    |> ModelBuilder.set_preference(:food_visible, 2.0)
    |> ModelBuilder.set_preference(:predator_visible, -3.0)
    |> ModelBuilder.set_policies([[:forage, :forage], [:forage, :hide], [:hide, :forage], [:hide, :hide]])
    |> ModelBuilder.build()
  end

  @doc """
  Thermostat agent — maintains comfortable temperature.

  3 states: :cold, :comfortable, :hot
  3 observations: :cold_reading, :normal_reading, :hot_reading
  2 actions: :heat, :cool
  """
  @spec thermostat() :: Jido.ActiveInference.GenerativeModel.t()
  def thermostat do
    ModelBuilder.new()
    |> ModelBuilder.set_states([:cold, :comfortable, :hot])
    |> ModelBuilder.set_observations([:cold_reading, :normal_reading, :hot_reading])
    |> ModelBuilder.set_actions([:heat, :cool])
    |> ModelBuilder.set_likelihood(:cold_reading, :cold, 0.8)
    |> ModelBuilder.set_likelihood(:cold_reading, :comfortable, 0.15)
    |> ModelBuilder.set_likelihood(:cold_reading, :hot, 0.05)
    |> ModelBuilder.set_likelihood(:normal_reading, :cold, 0.15)
    |> ModelBuilder.set_likelihood(:normal_reading, :comfortable, 0.7)
    |> ModelBuilder.set_likelihood(:normal_reading, :hot, 0.15)
    |> ModelBuilder.set_likelihood(:hot_reading, :cold, 0.05)
    |> ModelBuilder.set_likelihood(:hot_reading, :comfortable, 0.15)
    |> ModelBuilder.set_likelihood(:hot_reading, :hot, 0.8)
    |> ModelBuilder.set_transition(:heat, :cold, :cold, 0.3)
    |> ModelBuilder.set_transition(:heat, :cold, :comfortable, 0.6)
    |> ModelBuilder.set_transition(:heat, :cold, :hot, 0.1)
    |> ModelBuilder.set_transition(:heat, :comfortable, :cold, 0.1)
    |> ModelBuilder.set_transition(:heat, :comfortable, :comfortable, 0.5)
    |> ModelBuilder.set_transition(:heat, :comfortable, :hot, 0.4)
    |> ModelBuilder.set_transition(:heat, :hot, :cold, 0.05)
    |> ModelBuilder.set_transition(:heat, :hot, :comfortable, 0.25)
    |> ModelBuilder.set_transition(:heat, :hot, :hot, 0.7)
    |> ModelBuilder.set_transition(:cool, :cold, :cold, 0.7)
    |> ModelBuilder.set_transition(:cool, :cold, :comfortable, 0.25)
    |> ModelBuilder.set_transition(:cool, :cold, :hot, 0.05)
    |> ModelBuilder.set_transition(:cool, :comfortable, :cold, 0.4)
    |> ModelBuilder.set_transition(:cool, :comfortable, :comfortable, 0.5)
    |> ModelBuilder.set_transition(:cool, :comfortable, :hot, 0.1)
    |> ModelBuilder.set_transition(:cool, :hot, :cold, 0.1)
    |> ModelBuilder.set_transition(:cool, :hot, :comfortable, 0.6)
    |> ModelBuilder.set_transition(:cool, :hot, :hot, 0.3)
    |> ModelBuilder.set_preference(:cold_reading, -1.0)
    |> ModelBuilder.set_preference(:normal_reading, 3.0)
    |> ModelBuilder.set_preference(:hot_reading, -1.0)
    |> ModelBuilder.set_policies([[:heat, :heat], [:heat, :cool], [:cool, :heat], [:cool, :cool]])
    |> ModelBuilder.build()
  end

  @doc """
  Trader agent — buy low, sell high with market state inference.

  2 states: :bull_market, :bear_market
  2 observations: :price_up, :price_down
  2 actions: :buy, :sell
  """
  @spec trader() :: Jido.ActiveInference.GenerativeModel.t()
  def trader do
    ModelBuilder.new()
    |> ModelBuilder.set_states([:bull_market, :bear_market])
    |> ModelBuilder.set_observations([:price_up, :price_down])
    |> ModelBuilder.set_actions([:buy, :sell])
    |> ModelBuilder.set_likelihood(:price_up, :bull_market, 0.75)
    |> ModelBuilder.set_likelihood(:price_up, :bear_market, 0.3)
    |> ModelBuilder.set_likelihood(:price_down, :bull_market, 0.25)
    |> ModelBuilder.set_likelihood(:price_down, :bear_market, 0.7)
    |> ModelBuilder.set_transition(:buy, :bull_market, :bull_market, 0.8)
    |> ModelBuilder.set_transition(:buy, :bull_market, :bear_market, 0.2)
    |> ModelBuilder.set_transition(:buy, :bear_market, :bull_market, 0.3)
    |> ModelBuilder.set_transition(:buy, :bear_market, :bear_market, 0.7)
    |> ModelBuilder.set_transition(:sell, :bull_market, :bull_market, 0.6)
    |> ModelBuilder.set_transition(:sell, :bull_market, :bear_market, 0.4)
    |> ModelBuilder.set_transition(:sell, :bear_market, :bull_market, 0.4)
    |> ModelBuilder.set_transition(:sell, :bear_market, :bear_market, 0.6)
    |> ModelBuilder.set_preference(:price_up, 2.0)
    |> ModelBuilder.set_preference(:price_down, -1.0)
    |> ModelBuilder.set_policies([[:buy, :buy], [:buy, :sell], [:sell, :buy], [:sell, :sell]])
    |> ModelBuilder.build()
  end

  @doc """
  T-maze agent — classic Active Inference demonstration.

  4 states: :center, :left_arm, :right_arm, :cue_location
  3 observations: :neutral, :reward, :punishment
  3 actions: :go_left, :go_right, :stay
  """
  @spec t_maze() :: Jido.ActiveInference.GenerativeModel.t()
  def t_maze do
    ModelBuilder.new()
    |> ModelBuilder.set_states([:center, :left_arm, :right_arm, :cue_location])
    |> ModelBuilder.set_observations([:neutral, :reward, :punishment])
    |> ModelBuilder.set_actions([:go_left, :go_right, :stay])
    |> ModelBuilder.set_likelihood(:neutral, :center, 0.8)
    |> ModelBuilder.set_likelihood(:neutral, :left_arm, 0.1)
    |> ModelBuilder.set_likelihood(:neutral, :right_arm, 0.1)
    |> ModelBuilder.set_likelihood(:neutral, :cue_location, 0.6)
    |> ModelBuilder.set_likelihood(:reward, :center, 0.1)
    |> ModelBuilder.set_likelihood(:reward, :left_arm, 0.8)
    |> ModelBuilder.set_likelihood(:reward, :right_arm, 0.1)
    |> ModelBuilder.set_likelihood(:reward, :cue_location, 0.2)
    |> ModelBuilder.set_likelihood(:punishment, :center, 0.1)
    |> ModelBuilder.set_likelihood(:punishment, :left_arm, 0.1)
    |> ModelBuilder.set_likelihood(:punishment, :right_arm, 0.8)
    |> ModelBuilder.set_likelihood(:punishment, :cue_location, 0.2)
    # Transitions for go_left
    |> ModelBuilder.set_transition(:go_left, :center, :left_arm, 0.9)
    |> ModelBuilder.set_transition(:go_left, :center, :center, 0.1)
    |> ModelBuilder.set_transition(:go_left, :left_arm, :left_arm, 0.9)
    |> ModelBuilder.set_transition(:go_left, :right_arm, :right_arm, 0.9)
    |> ModelBuilder.set_transition(:go_left, :cue_location, :center, 0.9)
    # Transitions for go_right
    |> ModelBuilder.set_transition(:go_right, :center, :right_arm, 0.9)
    |> ModelBuilder.set_transition(:go_right, :center, :center, 0.1)
    |> ModelBuilder.set_transition(:go_right, :left_arm, :left_arm, 0.9)
    |> ModelBuilder.set_transition(:go_right, :right_arm, :right_arm, 0.9)
    |> ModelBuilder.set_transition(:go_right, :cue_location, :center, 0.9)
    # Transitions for stay
    |> ModelBuilder.set_transition(:stay, :center, :center, 0.9)
    |> ModelBuilder.set_transition(:stay, :left_arm, :left_arm, 0.9)
    |> ModelBuilder.set_transition(:stay, :right_arm, :right_arm, 0.9)
    |> ModelBuilder.set_transition(:stay, :cue_location, :cue_location, 0.9)
    |> ModelBuilder.set_preference(:neutral, 0.0)
    |> ModelBuilder.set_preference(:reward, 3.0)
    |> ModelBuilder.set_preference(:punishment, -3.0)
    |> ModelBuilder.set_policies([
      [:go_left, :stay],
      [:go_right, :stay],
      [:stay, :go_left],
      [:stay, :go_right]
    ])
    |> ModelBuilder.build()
  end

  @doc "List all available preset models."
  @spec list() :: [%{name: String.t(), description: String.t(), function: atom()}]
  def list do
    [
      %{name: "Forager", description: "Seeks food while avoiding predators", function: :forager},
      %{name: "Thermostat", description: "Maintains comfortable temperature", function: :thermostat},
      %{name: "Trader", description: "Buy low, sell high market inference", function: :trader},
      %{name: "T-Maze", description: "Classic Active Inference demonstration", function: :t_maze}
    ]
  end
end
