defmodule JidoBuilderWeb.UserAuth do
  @moduledoc """
  Authentication plug and LiveView `on_mount` hook for the local
  single-user login introduced in Work Item 7.13.
  """
  use JidoBuilderWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias JidoBuilderCore.Accounts

  @session_key :user_token

  @doc """
  Plug: fetches the user associated with the current session (if any)
  and assigns it to `conn.assigns.current_user`.
  """
  def fetch_current_user(conn, _opts) do
    token = get_session(conn, @session_key)
    user = token && Accounts.get_user_by_session_token(token)
    assign(conn, :current_user, user)
  end

  @doc """
  Plug: redirects unauthenticated requests to `/login`.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> redirect(to: "/login")
      |> halt()
    end
  end

  @doc """
  Logs the user in: rotates the session, stores the token, and
  redirects back to `/`.
  """
  def log_in_user(conn, user) do
    token = Accounts.generate_user_session_token(user)

    conn
    |> renew_session()
    |> put_session(@session_key, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> redirect(to: "/")
  end

  @doc """
  Logs the user out: revokes the session token and clears the session.
  """
  def log_out_user(conn) do
    token = get_session(conn, @session_key)
    token && Accounts.delete_user_session_token(token)

    conn
    |> renew_session()
    |> redirect(to: "/login")
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  # -- LiveView on_mount hooks --------------------------------------------

  @doc """
  LiveView `on_mount` hook.

    * `:ensure_authenticated` — halts the mount with a redirect when no
      session user is present; otherwise assigns `:current_user`.
    * `:mount_current_user` — best-effort assign, used by public pages.
  """
  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(session, socket)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: "/login")}
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(session, socket)}
  end

  defp mount_current_user(session, socket) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      case session do
        %{"user_token" => token} -> Accounts.get_user_by_session_token(token)
        _ -> nil
      end
    end)
  end
end
