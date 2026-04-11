defmodule JidoBuilderCore.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JidoBuilderCore.Repo
    ]

    opts = [strategy: :one_for_one, name: JidoBuilderCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
