defmodule JidoBuilderRuntime.CircuitBreakerTest do
  @moduledoc "Story 7.3 — Circuit Breaker tests (DD TDD: written before implementation)."
  use ExUnit.Case, async: false

  alias JidoBuilderRuntime.CircuitBreaker

  setup do
    # Ensure the ETS table is clean for each test
    key = {:cb_test, "agent-#{System.unique_integer([:positive])}"}
    CircuitBreaker.reset(key)
    %{key: key}
  end

  describe "breaker opens after N consecutive failures" do
    test "stays closed under threshold", %{key: key} do
      for _ <- 1..4 do
        CircuitBreaker.record_failure(key)
      end

      assert CircuitBreaker.state(key) == :closed
    end

    test "opens after 5 consecutive failures", %{key: key} do
      for _ <- 1..5 do
        CircuitBreaker.record_failure(key)
      end

      assert CircuitBreaker.state(key) == :open
    end
  end

  describe "open breaker rejects calls immediately" do
    test "allow?/1 returns false when open", %{key: key} do
      for _ <- 1..5, do: CircuitBreaker.record_failure(key)
      assert CircuitBreaker.state(key) == :open
      assert CircuitBreaker.allow?(key) == false
    end
  end

  describe "half-open breaker allows single probe" do
    test "transitions to half_open after timeout", %{key: key} do
      # Use a very short timeout for testing
      for _ <- 1..5, do: CircuitBreaker.record_failure(key, timeout_ms: 1)
      assert CircuitBreaker.state(key) == :open

      # Sleep past the timeout
      Process.sleep(5)

      assert CircuitBreaker.state(key) == :half_open
      assert CircuitBreaker.allow?(key) == true
    end
  end

  describe "successful probe closes breaker" do
    test "recording success in half_open transitions to closed", %{key: key} do
      for _ <- 1..5, do: CircuitBreaker.record_failure(key, timeout_ms: 1)
      Process.sleep(5)

      assert CircuitBreaker.state(key) == :half_open

      CircuitBreaker.record_success(key)
      assert CircuitBreaker.state(key) == :closed
    end

    test "recording failure in half_open transitions back to open", %{key: key} do
      for _ <- 1..5, do: CircuitBreaker.record_failure(key, timeout_ms: 1)
      Process.sleep(5)

      assert CircuitBreaker.state(key) == :half_open

      CircuitBreaker.record_failure(key)
      assert CircuitBreaker.state(key) == :open
    end
  end
end
