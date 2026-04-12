defmodule JidoBuilderWeb.SessionController do
  @moduledoc """
  Handles POST `/login` (credential submission) and DELETE `/logout`
  (session teardown) for the local single-user login.
  """
  use JidoBuilderWeb, :controller

  alias JidoBuilderCore.Accounts
  alias JidoBuilderWeb.UserAuth

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(401, "invalid email or password")

      user ->
        UserAuth.log_in_user(conn, user)
    end
  end

  def delete(conn, _params) do
    UserAuth.log_out_user(conn)
  end
end
