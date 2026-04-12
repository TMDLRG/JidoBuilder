defmodule JidoBuilderWeb.LoginLive do
  @moduledoc """
  Login form for the local single-user authentication flow.
  Submits to `POST /login`, which is handled by
  `JidoBuilderWeb.SessionController`.
  """
  use JidoBuilderWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Sign In")
     |> assign(error: nil), layout: false}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-sm p-6">
      <h1 class="text-lg font-semibold">Sign In</h1>
      <.form for={%{}} as={:user} action="/login" method="post">
        <label class="block mt-4">
          <span class="text-sm">Email</span>
          <input type="email" name="user[email]" required class="mt-1 block w-full" />
        </label>
        <label class="block mt-4">
          <span class="text-sm">Password</span>
          <input type="password" name="user[password]" required class="mt-1 block w-full" />
        </label>
        <button type="submit" class="mt-4 w-full rounded bg-zinc-900 px-3 py-2 text-white">
          Sign in
        </button>
      </.form>
    </main>
    """
  end
end
