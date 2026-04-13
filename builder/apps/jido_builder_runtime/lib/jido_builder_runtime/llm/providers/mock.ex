defmodule JidoBuilderRuntime.LLM.Providers.Mock do
  @moduledoc """
  Deterministic mock LLM provider for testing.

  Returns configurable responses without making any API calls.
  Useful for unit tests, integration tests, and development.

  ## Config Options

  - `:mock_response` — Static text to return (default: "Mock response")
  - `:mock_tool_use` — `%{name: "tool", arguments: %{}}` to simulate tool use
  - `:mock_error` — Return an error instead of success
  - `:mock_latency_ms` — Simulate response latency
  """

  @behaviour JidoBuilderRuntime.LLM.Client

  alias JidoBuilderRuntime.LLM.Client.{Response, ToolUse, StreamChunk}

  @doc "Returns default mock config."
  @spec default_config() :: map()
  def default_config do
    %{
      provider: :mock,
      model: "mock-model-v1",
      mock_response: "Mock response",
      mock_tool_use: nil,
      mock_error: nil,
      mock_latency_ms: 0
    }
  end

  @impl true
  def chat(messages, config) do
    maybe_simulate_latency(config)

    case config[:mock_error] do
      nil ->
        {:ok, build_text_response(config, messages)}

      error ->
        {:error, error}
    end
  end

  @impl true
  def chat_with_tools(messages, _tools, config) do
    maybe_simulate_latency(config)

    case config[:mock_error] do
      nil ->
        case config[:mock_tool_use] do
          nil ->
            {:ok, build_text_response(config, messages)}

          tool_use when is_map(tool_use) ->
            {:ok, build_tool_use_response(config, tool_use)}
        end

      error ->
        {:error, error}
    end
  end

  @impl true
  def stream(_messages, config) do
    case config[:mock_error] do
      nil ->
        text = config[:mock_response] || "Mock response"

        stream =
          text
          |> String.graphemes()
          |> Stream.chunk_every(3)
          |> Stream.map(fn chars ->
            %StreamChunk{content: Enum.join(chars, ""), done?: false}
          end)
          |> Stream.concat([%StreamChunk{content: "", done?: true}])

        {:ok, stream}

      error ->
        {:error, error}
    end
  end

  # -- Private --

  defp build_text_response(config, _messages) do
    %Response{
      role: "assistant",
      content: config[:mock_response] || "Mock response",
      tool_use: nil,
      usage: %{input_tokens: 10, output_tokens: 5},
      stop_reason: "end_turn",
      model: config[:model] || "mock-model-v1"
    }
  end

  defp build_tool_use_response(config, tool_use) do
    %Response{
      role: "assistant",
      content: nil,
      tool_use: %ToolUse{
        id: "mock_tool_#{System.unique_integer([:positive])}",
        name: tool_use[:name] || tool_use["name"],
        arguments: tool_use[:arguments] || tool_use["arguments"] || %{}
      },
      usage: %{input_tokens: 15, output_tokens: 8},
      stop_reason: "tool_use",
      model: config[:model] || "mock-model-v1"
    }
  end

  defp maybe_simulate_latency(config) do
    case config[:mock_latency_ms] do
      ms when is_integer(ms) and ms > 0 -> Process.sleep(ms)
      _ -> :ok
    end
  end
end
