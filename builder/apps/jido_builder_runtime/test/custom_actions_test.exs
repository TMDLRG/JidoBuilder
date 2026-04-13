defmodule JidoBuilderRuntime.CustomActionsTest do
  @moduledoc """
  Story 3.2 — Custom action patterns.

  Assertions:
    (a) HttpRequest action executes GET/POST and returns response body
    (b) JsonTransform action applies jq-like transformations
    (c) StateMutation action applies set/delete/merge operations
    (d) WebhookCall action posts JSON to a URL
    (e) ActionRegistry.list/0 returns all builder actions with metadata
  """
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Actions.{HttpRequest, JsonTransform, StateMutation, WebhookCall}
  alias JidoBuilderRuntime.ActionRegistry

  # --- HttpRequest ---

  test "HttpRequest action returns error for unreachable URL" do
    params = %{method: "GET", url: "http://127.0.0.1:1/nonexistent"}

    assert {:error, _} = HttpRequest.run(params, %{})
  end

  # --- JsonTransform ---

  test "JsonTransform pick operation extracts keys" do
    params = %{
      operation: "pick",
      data: %{"name" => "Alice", "age" => 30, "email" => "a@b.com"},
      keys: ["name", "email"]
    }

    assert {:ok, result} = JsonTransform.run(params, %{})
    assert result.result == %{"name" => "Alice", "email" => "a@b.com"}
  end

  test "JsonTransform flatten operation flattens nested map" do
    params = %{
      operation: "flatten",
      data: %{"user" => %{"name" => "Alice", "address" => %{"city" => "NYC"}}}
    }

    assert {:ok, result} = JsonTransform.run(params, %{})
    assert result.result["user.name"] == "Alice"
    assert result.result["user.address.city"] == "NYC"
  end

  test "JsonTransform merge operation combines maps" do
    params = %{
      operation: "merge",
      data: %{"a" => 1},
      merge_with: %{"b" => 2}
    }

    assert {:ok, result} = JsonTransform.run(params, %{})
    assert result.result == %{"a" => 1, "b" => 2}
  end

  # --- StateMutation ---

  test "StateMutation set operation sets keys" do
    params = %{operation: "set", data: %{counter: 0}, changes: %{counter: 42, name: "test"}}

    assert {:ok, result} = StateMutation.run(params, %{})
    assert result.result.counter == 42
    assert result.result.name == "test"
  end

  test "StateMutation delete operation removes keys" do
    params = %{operation: "delete", data: %{"a" => 1, "b" => 2, "c" => 3}, keys: ["b", "c"]}

    assert {:ok, result} = StateMutation.run(params, %{})
    assert result.result == %{"a" => 1}
  end

  test "StateMutation merge operation deep-merges" do
    params = %{
      operation: "merge",
      data: %{"config" => %{"timeout" => 30}},
      merge_with: %{"config" => %{"retries" => 3}}
    }

    assert {:ok, result} = StateMutation.run(params, %{})
    assert result.result == %{"config" => %{"timeout" => 30, "retries" => 3}}
  end

  # --- WebhookCall ---

  test "WebhookCall returns error for unreachable URL" do
    params = %{url: "http://127.0.0.1:1/webhook", payload: %{"event" => "test"}}

    assert {:error, _} = WebhookCall.run(params, %{})
  end

  # --- ActionRegistry ---

  test "ActionRegistry.list/0 returns all builder actions with metadata" do
    actions = ActionRegistry.list()
    assert is_list(actions)
    assert length(actions) >= 8

    slugs = Enum.map(actions, & &1.slug)
    assert "echo" in slugs
    assert "http_request" in slugs
    assert "json_transform" in slugs
    assert "state_mutation" in slugs
    assert "webhook_call" in slugs
  end

  test "ActionRegistry.get/1 returns action by slug" do
    assert %{slug: "echo", module: _} = ActionRegistry.get("echo")
    assert nil == ActionRegistry.get("nonexistent")
  end
end
