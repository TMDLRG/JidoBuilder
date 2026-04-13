defmodule JidoBuilderWeb.Live.ChatInteractiveTest do
  @moduledoc "Phase 8.2 — Verify Agent Chat page sends messages and gets responses."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "chat page has a form with phx-submit", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/agents/test-agent/chat")
    assert html =~ ~s(phx-submit="send_message")
  end

  test "sending a message adds it to chat and gets mock response", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/agents/test-agent/chat")
    html = render_submit(lv, "send_message", %{"message" => "Hello"})
    assert html =~ "Hello"
    assert html =~ "Mock response"
  end
end
