defmodule JidoBuilderRuntime.Factory.ComposerTest do
  @moduledoc "Epic 4.1 — Template Composition Engine tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Factory.Composer

  defp template_a do
    %{
      name: "agent_a",
      routes: [
        %{signal: "user.query", action: "Echo", opts: %{}},
        %{signal: "data.transform", action: "TransformData", opts: %{}}
      ],
      state_fields: [
        %{field_name: "counter", field_type: "integer"},
        %{field_name: "status", field_type: "string"}
      ],
      plugins: [%{name: "memory", module: "Jido.Memory.Plugin"}],
      config: %{max_retries: 3}
    }
  end

  defp template_b do
    %{
      name: "agent_b",
      routes: [
        %{signal: "api.call", action: "HttpRequest", opts: %{}},
        %{signal: "slack.send", action: "SlackMessage", opts: %{}}
      ],
      state_fields: [
        %{field_name: "last_response", field_type: "map"},
        %{field_name: "error_count", field_type: "integer"}
      ],
      plugins: [%{name: "thread", module: "Jido.Thread.Plugin"}],
      config: %{timeout: 5000}
    }
  end

  describe "compose/2" do
    test "merges two templates" do
      {:ok, composed} = Composer.compose([template_a(), template_b()], name: "merged")

      assert composed.name == "merged"
      assert length(composed.routes) == 4
      assert length(composed.state_fields) == 4
      assert length(composed.plugins) == 2
    end

    test "merges configs" do
      {:ok, composed} = Composer.compose([template_a(), template_b()])

      assert composed.config[:max_retries] == 3
      assert composed.config[:timeout] == 5000
    end

    test "deduplicates routes by signal+action" do
      dup_a = template_a()
      dup_b = %{template_b() | routes: template_a().routes ++ template_b().routes}

      # Force through conflicts since duplicates are expected
      {:ok, composed} = Composer.compose([dup_a, dup_b], force: true)
      assert length(composed.routes) == 4
    end

    test "deduplicates state fields by name" do
      dup_b = %{template_b() | state_fields: template_a().state_fields ++ template_b().state_fields}

      {:ok, composed} = Composer.compose([template_a(), dup_b])
      assert length(composed.state_fields) == 4
    end

    test "tracks source templates" do
      {:ok, composed} = Composer.compose([template_a(), template_b()])
      assert "agent_a" in composed.source_templates
      assert "agent_b" in composed.source_templates
    end

    test "rejects empty list" do
      assert {:error, _} = Composer.compose([])
    end

    test "detects field type conflicts" do
      conflict_b = %{template_b() |
        state_fields: [%{field_name: "counter", field_type: "string"}]
      }

      {:error, {:conflicts, conflicts}} = Composer.compose([template_a(), conflict_b])
      assert length(conflicts) > 0
    end

    test "force ignores conflicts" do
      conflict_b = %{template_b() |
        state_fields: [%{field_name: "counter", field_type: "string"}]
      }

      {:ok, composed} = Composer.compose([template_a(), conflict_b], force: true)
      assert length(composed.conflicts) > 0
    end
  end

  describe "detect_conflicts/2" do
    test "finds duplicate signals" do
      routes = [
        %{signal: "user.query", action: "A"},
        %{signal: "user.query", action: "B"}
      ]

      conflicts = Composer.detect_conflicts(routes, [])
      assert length(conflicts) == 1
      assert List.first(conflicts).type == :route_conflict
    end
  end
end
