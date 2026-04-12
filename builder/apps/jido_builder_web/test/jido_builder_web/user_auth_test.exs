defmodule JidoBuilderWeb.UserAuthTest do
  @moduledoc """
  Work Item 7.13 — Local bcrypt single-user auth.

  Five required assertions:
    1. Unauthenticated GET `/` redirects to `/login` with 302.
    2. `/healthz` and `/readyz` remain 200 (excluded from auth).
    3. POST `/login` with correct credentials establishes a session and
       redirects to `/`.
    4. POST `/login` with the wrong password returns 401 and no session.
    5. The `on_mount` hook assigns `:current_user` to a LiveView socket
       when a session is present.
  """
  use JidoBuilderWeb.ConnCase, async: false

  alias JidoBuilderCore.Accounts
  alias JidoBuilderWeb.UserAuth

  @valid_email "owner@example.com"
  @valid_password "correct-horse-battery-staple"
  @wrong_password "definitely-wrong-password"

  setup do
    {:ok, user} =
      Accounts.create_user(%{
        email: @valid_email,
        password: @valid_password
      })

    %{user: user}
  end

  describe "browser pipeline auth" do
    test "unauthenticated GET / redirects to /login with 302", %{conn: conn} do
      conn = get(conn, "/")
      assert conn.status == 302
      assert redirected_to(conn) == "/login"
    end

    test "GET /healthz remains 200 without auth", %{conn: conn} do
      conn = get(conn, "/healthz")
      assert conn.status == 200
      assert conn.resp_body == "ok"
    end

    test "GET /readyz remains 200 without auth", %{conn: conn} do
      conn = get(conn, "/readyz")
      assert conn.status == 200
    end
  end

  describe "POST /login" do
    test "valid credentials set session cookie and redirect to /", %{conn: conn} do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> post("/login", %{"user" => %{"email" => @valid_email, "password" => @valid_password}})

      assert redirected_to(conn) == "/"
      assert get_session(conn, :user_token) != nil
    end

    test "wrong password returns 401 and leaves session empty", %{conn: conn} do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> post("/login", %{"user" => %{"email" => @valid_email, "password" => @wrong_password}})

      assert conn.status == 401
      assert get_session(conn, :user_token) == nil
    end
  end

  describe "on_mount :ensure_authenticated" do
    test "assigns :current_user when user_token is present", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      session = %{"user_token" => token}

      {:cont, socket} =
        UserAuth.on_mount(:ensure_authenticated, %{}, session, %Phoenix.LiveView.Socket{})

      assert socket.assigns.current_user.id == user.id
      assert socket.assigns.current_user.email == @valid_email
    end
  end
end
