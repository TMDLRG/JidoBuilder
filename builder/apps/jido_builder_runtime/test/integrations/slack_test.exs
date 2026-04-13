defmodule JidoBuilderRuntime.Integrations.SlackTest do
  @moduledoc "Story 8.2 — Slack integration action."
  use ExUnit.Case, async: false

  alias JidoBuilderRuntime.Integrations.Slack

  test "builds correct Slack webhook payload" do
    params = %{
      webhook_url: "https://hooks.slack.com/services/T000/B000/xxx",
      channel: "#general",
      text: "Hello from JidoBuilder!"
    }

    payload = Slack.build_payload(params)

    assert payload["text"] == "Hello from JidoBuilder!"
    assert payload["channel"] == "#general"
  end

  test "validates required fields" do
    assert {:error, _} = Slack.validate(%{})
    assert :ok = Slack.validate(%{webhook_url: "https://hooks.slack.com/test", text: "hello"})
  end
end
