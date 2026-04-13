defmodule JidoBuilderWeb.Live.ChatInteractiveTest do
  @moduledoc "Verify Agent Chat page sends messages and gets responses via LlmChat action."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "chat page has a form with phx-submit", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/agents/test-agent/chat")
    assert html =~ ~s(phx-submit="send_message")
  end

  test "sending a message shows user message and loading state", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/agents/test-agent/chat")
    html = render_submit(lv, "send_message", %{"message" => "Hello"})
    # User message should appear immediately
    assert html =~ "Hello"
    # Loading indicator should appear (async dispatch in progress)
    assert html =~ "thinking..."
  end

  test "chat page shows provider info", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/agents/test-agent/chat")
    assert html =~ "LLM Config"
  end

  test "after async dispatch, mock response appears", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/agents/test-agent/chat")
    render_submit(lv, "send_message", %{"message" => "Hello"})

    # Wait for the async handle_info to process
    # The mock provider responds synchronously, so processing should be fast
    :timer.sleep(500)
    html = render(lv)

    assert html =~ "Hello"
    # The LlmChat action with mock provider returns "Mock response"
    assert html =~ "Mock response"
  end
end
