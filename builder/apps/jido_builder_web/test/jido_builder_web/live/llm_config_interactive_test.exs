defmodule JidoBuilderWeb.Live.LlmConfigInteractiveTest do
  @moduledoc "Phase 8.4 — Verify LLM Config page has full form with all fields."
  use JidoBuilderWeb.ConnCase, async: false

  @moduletag :authenticated

  import Phoenix.LiveViewTest

  test "form has phx-change for validation", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/llm-config")
    assert html =~ ~s(phx-change="validate")
  end

  test "form includes model, temperature, and max_tokens fields", %{conn: conn} do
    {:ok, _lv, html} = live(conn, "/llm-config")
    assert html =~ "temperature" or html =~ "Temperature"
    assert html =~ "max_tokens" or html =~ "Max Tokens"
    assert html =~ "model" or html =~ "Model"
  end

  test "changing provider updates available models", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/llm-config")
    html = render_change(lv, "validate", %{"config" => %{"provider" => "openai"}})
    assert html =~ "gpt-4" or html =~ "gpt"
  end

  test "save config shows success", %{conn: conn} do
    {:ok, lv, _html} = live(conn, "/llm-config")
    html = render_click(lv, "save_config", %{})
    assert html =~ "saved" or html =~ "Saved" or html =~ "success" or html =~ "Configuration saved"
  end
end
