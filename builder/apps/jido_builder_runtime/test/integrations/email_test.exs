defmodule JidoBuilderRuntime.Integrations.EmailTest do
  @moduledoc "Story 8.2 — Email integration action."
  use ExUnit.Case, async: false

  alias JidoBuilderRuntime.Integrations.Email

  test "validates required fields" do
    assert {:error, _} = Email.validate(%{})
    assert {:error, _} = Email.validate(%{to: "test@example.com"})
    assert :ok = Email.validate(%{to: "test@example.com", subject: "Test", body: "Hello"})
  end

  test "builds email message map" do
    params = %{to: "user@example.com", subject: "Alert", body: "Agent stopped"}
    msg = Email.build_message(params)

    assert msg.to == "user@example.com"
    assert msg.subject == "Alert"
    assert msg.body == "Agent stopped"
  end
end
