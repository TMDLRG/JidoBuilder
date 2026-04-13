defmodule JidoBuilderRuntime.LLM.Providers.OpenAI do
  @moduledoc """
  OpenAI-compatible API provider.

  Works with OpenAI, Azure OpenAI, and any OpenAI-compatible endpoint.

  ## Config

      %{
        provider: :openai,
        model: "gpt-4",
        api_key: System.get_env("OPENAI_API_KEY"),
        base_url: "https://api.openai.com/v1",  # optional
        max_tokens: 1024,
        temperature: 0.7,
        system: "You are a helpful assistant."
      }
  """

  @behaviour JidoBuilderRuntime.LLM.Client

  alias JidoBuilderRuntime.LLM.Client.{Response, ToolUse, StreamChunk}

  @default_base_url "https://api.openai.com/v1"

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

    # Fallback: non-streaming chunked
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

  # -- Private --

  defp build_request_body(messages, config) do
    all_messages =
      case config[:system] do
        nil -> messages
        sys -> [%{"role" => "system", "content" => sys} | messages]
      end

    body = %{
      "model" => config[:model] || "gpt-4",
      "messages" => Enum.map(all_messages, &format_message/1)
    }

    body =
      if config[:max_tokens],
        do: Map.put(body, "max_tokens", config[:max_tokens]),
        else: body

    if config[:temperature],
      do: Map.put(body, "temperature", config[:temperature]),
      else: body
  end

  defp format_message(%{tool_use: %ToolUse{} = tu} = msg) do
    base = %{
      "role" => "assistant",
      "content" => msg[:content],
      "tool_calls" => [
        %{
          "id" => tu.id,
          "type" => "function",
          "function" => %{
            "name" => tu.name,
            "arguments" => Jason.encode!(tu.arguments || %{})
          }
        }
      ]
    }

    base
  end

  defp format_message(%{tool_use_id: tool_use_id} = msg) when is_binary(tool_use_id) do
    %{
      "role" => "tool",
      "tool_call_id" => tool_use_id,
      "content" => msg[:content] || ""
    }
  end

  defp format_message(msg) do
    %{
      "role" => msg[:role] || msg["role"],
      "content" => msg[:content] || msg["content"]
    }
  end

  defp format_tool(tool) do
    %{
      "type" => "function",
      "function" => %{
        "name" => tool[:name] || tool.name,
        "description" => tool[:description] || tool.description,
        "parameters" => tool[:parameters_schema] || tool.parameters_schema
      }
    }
  end

  defp do_request(body, config) do
    base_url = config[:base_url] || @default_base_url
    url = "#{base_url}/chat/completions"

    case Req.post(url,
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

  defp parse_response(body) do
    choice = List.first(body["choices"] || [])
    message = (choice && choice["message"]) || %{}

    tool_calls = message["tool_calls"]

    tool_use =
      case tool_calls do
        [first | _] ->
          %ToolUse{
            id: first["id"],
            name: get_in(first, ["function", "name"]),
            arguments: parse_arguments(get_in(first, ["function", "arguments"]))
          }

        _ ->
          nil
      end

    %Response{
      role: "assistant",
      content: message["content"],
      tool_use: tool_use,
      usage: body["usage"],
      stop_reason: choice && choice["finish_reason"],
      model: body["model"]
    }
  end

  defp parse_arguments(nil), do: %{}

  defp parse_arguments(args) when is_binary(args) do
    case Jason.decode(args) do
      {:ok, parsed} -> parsed
      _ -> %{}
    end
  end

  defp parse_arguments(args) when is_map(args), do: args

  defp headers(config) do
    [
      {"authorization", "Bearer #{config[:api_key]}"},
      {"content-type", "application/json"}
    ]
  end
end
