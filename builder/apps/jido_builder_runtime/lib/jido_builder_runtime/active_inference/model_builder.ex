defmodule JidoBuilderRuntime.ActiveInference.ModelBuilder do
  @moduledoc """
  UI-friendly builder for Active Inference generative models.

  Provides a step-by-step API for constructing POMDP models that
  can be used with the Active Inference strategy.

  ## Example

      model = ModelBuilder.new()
      |> ModelBuilder.set_states([:safe, :danger])
      |> ModelBuilder.set_observations([:green, :red])
      |> ModelBuilder.set_actions([:stay, :move])
      |> ModelBuilder.set_likelihood(:green, :safe, 0.8)
      |> ModelBuilder.set_likelihood(:red, :danger, 0.9)
      |> ModelBuilder.set_transition(:stay, :safe, :safe, 0.9)
      |> ModelBuilder.set_transition(:move, :safe, :danger, 0.7)
      |> ModelBuilder.set_preference(:green, 2.0)
      |> ModelBuilder.set_preference(:red, -2.0)
      |> ModelBuilder.build()
  """

  alias Jido.ActiveInference.GenerativeModel

  defstruct [
    :states,
    :observations,
    :actions,
    :likelihood,
    :transitions,
    :preferences,
    :priors,
    :policies
  ]

  @type t :: %__MODULE__{}

  @doc "Create a new model builder."
  @spec new() :: t()
  def new do
    %__MODULE__{
      states: [],
      observations: [],
      actions: [],
      likelihood: %{},
      transitions: %{},
      preferences: %{},
      priors: %{},
      policies: nil
    }
  end

  @doc "Set the hidden state names."
  @spec set_states(t(), [atom()]) :: t()
  def set_states(%__MODULE__{} = builder, states) when is_list(states) do
    %{builder | states: states}
  end

  @doc "Set the observation names."
  @spec set_observations(t(), [atom()]) :: t()
  def set_observations(%__MODULE__{} = builder, observations) when is_list(observations) do
    %{builder | observations: observations}
  end

  @doc "Set the action names."
  @spec set_actions(t(), [atom()]) :: t()
  def set_actions(%__MODULE__{} = builder, actions) when is_list(actions) do
    %{builder | actions: actions}
  end

  @doc "Set likelihood: P(observation | state)."
  @spec set_likelihood(t(), atom(), atom(), float()) :: t()
  def set_likelihood(%__MODULE__{} = builder, observation, state, probability) do
    key = {observation, state}
    %{builder | likelihood: Map.put(builder.likelihood, key, probability)}
  end

  @doc "Set transition: P(next_state | current_state, action)."
  @spec set_transition(t(), atom(), atom(), atom(), float()) :: t()
  def set_transition(%__MODULE__{} = builder, action, from_state, to_state, probability) do
    key = {action, from_state, to_state}
    %{builder | transitions: Map.put(builder.transitions, key, probability)}
  end

  @doc "Set preference over an observation (log-preference)."
  @spec set_preference(t(), atom(), float()) :: t()
  def set_preference(%__MODULE__{} = builder, observation, value) do
    %{builder | preferences: Map.put(builder.preferences, observation, value)}
  end

  @doc "Set prior belief about a state."
  @spec set_prior(t(), atom(), float()) :: t()
  def set_prior(%__MODULE__{} = builder, state, probability) do
    %{builder | priors: Map.put(builder.priors, state, probability)}
  end

  @doc "Set the policy space (list of action-name sequences)."
  @spec set_policies(t(), [[atom()]]) :: t()
  def set_policies(%__MODULE__{} = builder, policies) when is_list(policies) do
    %{builder | policies: policies}
  end

  @doc "Build the GenerativeModel from the builder specification."
  @spec build(t()) :: GenerativeModel.t() | {:error, String.t()}
  def build(%__MODULE__{} = builder) do
    with :ok <- validate_builder(builder) do
      num_states = length(builder.states)
      num_obs = length(builder.observations)
      num_actions = length(builder.actions)

      a_matrix = build_a_matrix(builder, num_obs, num_states)
      b_matrix = build_b_matrix(builder, num_states, num_actions)
      c_vector = build_c_vector(builder, num_obs)
      d_vector = build_d_vector(builder, num_states)

      model = GenerativeModel.new(%{
        a_matrix: a_matrix,
        b_matrix: b_matrix,
        c_vector: c_vector,
        d_vector: d_vector
      })

      case {builder.policies, model} do
        {nil, model} ->
          # Auto-generate all single-step policies
          policies = for a <- 0..(num_actions - 1), do: [a]
          GenerativeModel.with_policies(model, policies)

        {named_policies, model} ->
          # Convert named policies to indices
          action_idx = fn name -> Enum.find_index(builder.actions, &(&1 == name)) end
          indexed = Enum.map(named_policies, fn seq ->
            Enum.map(seq, action_idx)
          end)
          GenerativeModel.with_policies(model, indexed)
      end
    end
  end

  # -- Private --

  defp validate_builder(%__MODULE__{states: s, observations: o, actions: a}) do
    cond do
      length(s) == 0 -> {:error, "States must be non-empty"}
      length(o) == 0 -> {:error, "Observations must be non-empty"}
      length(a) == 0 -> {:error, "Actions must be non-empty"}
      true -> :ok
    end
  end

  defp build_a_matrix(builder, num_obs, num_states) do
    for obs_idx <- 0..(num_obs - 1) do
      obs_name = Enum.at(builder.observations, obs_idx)
      for state_idx <- 0..(num_states - 1) do
        state_name = Enum.at(builder.states, state_idx)
        Map.get(builder.likelihood, {obs_name, state_name}, 1.0 / num_obs)
      end
    end
  end

  defp build_b_matrix(builder, num_states, num_actions) do
    for action_idx <- 0..(num_actions - 1) do
      action_name = Enum.at(builder.actions, action_idx)
      for to_idx <- 0..(num_states - 1) do
        to_name = Enum.at(builder.states, to_idx)
        for from_idx <- 0..(num_states - 1) do
          from_name = Enum.at(builder.states, from_idx)
          Map.get(builder.transitions, {action_name, from_name, to_name}, 1.0 / num_states)
        end
      end
    end
  end

  defp build_c_vector(builder, num_obs) do
    for obs_idx <- 0..(num_obs - 1) do
      obs_name = Enum.at(builder.observations, obs_idx)
      Map.get(builder.preferences, obs_name, 0.0)
    end
  end

  defp build_d_vector(builder, num_states) do
    for state_idx <- 0..(num_states - 1) do
      state_name = Enum.at(builder.states, state_idx)
      Map.get(builder.priors, state_name, 1.0 / num_states)
    end
  end
end
