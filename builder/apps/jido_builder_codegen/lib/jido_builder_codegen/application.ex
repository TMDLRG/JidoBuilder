defmodule JidoBuilderCodegen.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {JidoBuilderCodegen.CompileQueue, name: JidoBuilderCodegen.CompileQueue}
    ]

    opts = [strategy: :one_for_one, name: JidoBuilderCodegen.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
