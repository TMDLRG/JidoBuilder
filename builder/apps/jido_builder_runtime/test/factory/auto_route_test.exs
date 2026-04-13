defmodule JidoBuilderRuntime.Factory.AutoRouteTest do
  @moduledoc "Epic 4.5 — Auto-route generation tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Factory.AutoRoute
  alias JidoBuilderRuntime.Actions.Echo

  describe "generate/2" do
    test "generates routes from action modules" do
      routes = AutoRoute.generate([Echo])

      assert length(routes) == 1
      [route] = routes
      assert route.signal == "agent.echo"
      assert route.target == "echo"
    end

    test "uses custom prefix" do
      routes = AutoRoute.generate([Echo], prefix: "bot")

      [route] = routes
      assert route.signal == "bot.echo"
    end

    test "handles multiple modules" do
      routes = AutoRoute.generate([Echo, Echo])
      assert length(routes) == 2
    end
  end

  describe "generate_from_slugs/2" do
    test "resolves known slugs" do
      routes = AutoRoute.generate_from_slugs(["echo"])

      assert length(routes) == 1
      [route] = routes
      assert route.signal == "agent.echo"
    end

    test "skips unknown slugs" do
      routes = AutoRoute.generate_from_slugs(["echo", "nonexistent"])
      assert length(routes) == 1
    end

    test "respects custom prefix" do
      routes = AutoRoute.generate_from_slugs(["echo"], prefix: "custom")
      [route] = routes
      assert route.signal == "custom.echo"
    end
  end
end
