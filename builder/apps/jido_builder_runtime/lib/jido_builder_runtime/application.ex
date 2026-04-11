defmodule JidoBuilderRuntime.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Jido.Discovery.init_async()

    children = [
      JidoBuilderRuntime.Jido,
      JidoBuilderRuntime.TelemetryBridge
    ]

    opts = [strategy: :one_for_one, name: JidoBuilderRuntime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
