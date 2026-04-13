defmodule JidoBuilderRuntime.LLM.Providers.Anthropic do
  @moduledoc """
  Anthropic Claude API provider.

  Requires `:api_key` in config. Uses Req for HTTP requests.

  ## Config

      %{
        provider: :anthropic,
        model: "claude-sonnet-4-20250514",
        api_key: System.get_env("ANTHROPIC_API_KEY"),
        max_tokens: 1024,
        temperature: 0.7,
        system: "You are a helpful assistant."
      }
  """

  @behaviour JidoBuilderRuntime.LLM.Client

  alias JidoBuilderRuntime.LLM.Client.{Response, ToolUse, StreamChunk}

  @api_url "https://api.anthropic.com/v1/messages"
  @api_version "2023-06-01"

  @impl true
  def chat(messages, config) do
    body = build_request_body(messages, config)
    do_request(body, config)
  end

  @impl true
  def chat_with_tools(messages, tools, config) do
    body =
      build_request_body(messages, config)
      |> Map.put("tools", Enum.map(tools, &format_tool/1))

    do_request(body, config)
  end

  @impl true
  def stream(messages, config) do
    body =
      build_request_body(messages, config)
      |> Map.put("stream", true)

    case do_stream_request(body, config) do
      {:ok, stream} -> {:ok, stream}
      error -> error
    end
  end

  # -- Private --

  defp build_request_body(messages, config) do
    {system_messages, user_messages} =
      Enum.split_with(messages, fn m -> m[:role] == "system" || m["role"] == "system" end)

    system_text =
      case system_messages do
        [] -> config[:system]
        msgs -> Enum.map_join(msgs, "\n", fn m -> m[:content] || m["content"] end)
      end

    body = %{
      "model" => config[:model] || "claude-sonnet-4-20250514",
      "max_tokens" => config[:max_tokens] || 1024,
      "messages" => Enum.map(user_messages, &format_message/1)
    }

    body =
      if system_text, do: Map.put(body, "system", system_text), else: body

    if config[:temperature],
      do: Map.put(body, "temperature", config[:temperature]),
      else: body
  end

  defp format_message(%{tool_use: %ToolUse{} = tu} = msg) do
    text_block = if msg[:content], do: [%{"type" => "text", "text" => msg[:content]}], else: []

    tool_block = %{
      "type" => "tool_use",
      "id" => tu.id,
      "name" => tu.name,
      "input" => tu.arguments || %{}
    }

    %{"role" => "assistant", "content" => text_block ++ [tool_block]}
  end

  defp format_message(%{tool_use_id: tool_use_id} = msg) when is_binary(tool_use_id) do
    result_block = %{
      "type" => "tool_result",
      "tool_use_id" => tool_use_id,
      "content" => msg[:content] || ""
    }

    result_block =
      if msg[:is_error], do: Map.put(result_block, "is_error", true), else: result_block

    %{"role" => "user", "content" => [result_block]}
  end

  defp format_message(msg) do
    %{
      "role" => msg[:role] || msg["role"],
      "content" => msg[:content] || msg["content"]
    }
  end

  defp format_tool(tool) do
    %{
      "name" => tool[:name] || tool.name,
      "description" => tool[:description] || tool.description,
      "input_schema" => tool[:parameters_schema] || tool.parameters_schema
    }
  end

  defp do_request(body, config) do
    case Req.post(@api_url,
           json: body,
           headers: headers(config),
           receive_timeout: config[:timeout] || 60_000
         ) do
      {:ok, %{status: 200, body: resp_body}} ->
        {:ok, parse_response(resp_body)}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, %{status: status, body: resp_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_stream_request(body, config) do
    # Streaming implementation — returns enumerable of chunks
    # For now, fall back to non-streaming and chunk the result
    case do_request(Map.delete(body, "stream"), config) do
      {:ok, response} ->
        chunks =
          Stream.concat(
            [%StreamChunk{content: response.content || "", done?: false}],
            [%StreamChunk{content: "", done?: true}]
          )

        {:ok, chunks}

      error ->
        error
    end
  end

  defp parse_response(body) do
    content_blocks = body["content"] || []

    {text, tool_use} =
      Enum.reduce(content_blocks, {nil, nil}, fn block, {t, tu} ->
        case block["type"] do
          "text" -> {block["text"], tu}
          "tool_use" ->
            {t, %ToolUse{
              id: block["id"],
              name: block["name"],
              arguments: block["input"] || %{}
            }}
          _ -> {t, tu}
        end
      end)

    %Response{
      role: "assistant",
      content: text,
      tool_use: tool_use,
      usage: body["usage"],
      stop_reason: body["stop_reason"],
      model: body["model"]
    }
  end

  defp headers(config) do
    [
      {"x-api-key", config[:api_key]},
      {"anthropic-version", @api_version},
      {"content-type", "application/json"}
    ]
  end
end
