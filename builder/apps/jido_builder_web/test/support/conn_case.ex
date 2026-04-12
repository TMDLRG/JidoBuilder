defmodule JidoBuilderWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint JidoBuilderWeb.Endpoint
      use Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import JidoBuilderWeb.ConnCase, only: [log_in_user: 1, log_in_user: 2]
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

    conn = Phoenix.ConnTest.build_conn()

    conn =
      if tags[:authenticated] do
        {:ok, user} =
          JidoBuilderCore.Accounts.create_user(%{
            email: "operator-#{System.unique_integer([:positive])}@example.com",
            password: "correct-horse-battery-staple"
          })

        log_in_user(conn, user)
      else
        conn
      end

    {:ok, conn: conn}
  end

  @doc """
  Stores a session `user_token` on `conn` so LiveView and controller
  tests can exercise authenticated routes.
  """
  def log_in_user(conn, user \\ nil) do
    user =
      user ||
        (
          {:ok, u} =
            JidoBuilderCore.Accounts.create_user(%{
              email: "operator-#{System.unique_integer([:positive])}@example.com",
              password: "correct-horse-battery-staple"
            })

          u
        )

    token = JidoBuilderCore.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
