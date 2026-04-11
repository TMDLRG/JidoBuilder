defmodule JidoBuilderWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint JidoBuilderWeb.Endpoint
      use Phoenix.ConnTest
      import Phoenix.LiveViewTest
      unquote(JidoBuilderWeb.verified_routes())
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(JidoBuilderCore.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(JidoBuilderCore.Repo, {:shared, self()})
    end

    if Process.whereis(JidoBuilder.PubSub) == nil do
      start_supervised!({Phoenix.PubSub, name: JidoBuilder.PubSub})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
