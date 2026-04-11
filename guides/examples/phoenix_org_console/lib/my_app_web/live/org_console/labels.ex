defmodule MyAppWeb.OrgConsole.Labels do
  @moduledoc """
  Translates human-friendly labels to Jido-native terminology when advanced mode is enabled.
  """

  @type key ::
          :team
          | :agent
          | :assignment
          | :workflow
          | :schedule
          | :watcher
          | :department
          | :pod
          | :signal

  @labels %{
    team: {"Team", "Pod"},
    agent: {"Employee", "Agent"},
    assignment: {"Assignment", "Directive"},
    workflow: {"Workflow", "Instruction Flow"},
    schedule: {"Schedule", "Cron"},
    watcher: {"Monitor", "Sensor"},
    department: {"Department", "Topology Group"},
    pod: {"Pod", "Pod"},
    signal: {"Update", "Signal"}
  }

  @spec text(key(), boolean()) :: String.t()
  def text(key, advanced? \\ false) do
    {plain, advanced} = Map.fetch!(@labels, key)

    if advanced?, do: advanced, else: plain
  end
end
