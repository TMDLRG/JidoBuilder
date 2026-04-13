defmodule JidoBuilderWeb.MCP.SseController do
  @moduledoc """
  MCP SSE transport per MCP 2024-11-05 spec.

  GET /mcp/sse  — Opens an SSE stream, sends an `endpoint` event with the messages URL.
  POST /mcp/messages?session_id=X — Accepts JSON-RPC, routes response back.
  """
  use JidoBuilderWeb, :controller

  alias JidoBuilderWeb.MCP.SseSessionStore

  @doc "SSE endpoint: creates session and sends endpoint event."
  def sse(conn, _params) do
    session_id = generate_session_id()
    SseSessionStore.register(session_id, conn.assigns.workspace_id)

    message_url = "/mcp/messages?session_id=#{session_id}"

    conn
    |> put_resp_content_type("text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> put_resp_header("connection", "keep-alive")
    |> send_resp(200, sse_event("endpoint", message_url))
  end

  @doc "Message endpoint: accepts JSON-RPC for an active SSE session."
  def messages(conn, %{"session_id" => session_id} = _params) do
    case SseSessionStore.get(session_id) do
      nil ->
        conn |> put_status(404) |> json(%{error: "Session not found"})

      %{workspace_id: workspace_id} ->
        body = conn.body_params
        method = body["method"]
        id = body["id"]
        params = Map.get(body, "params", %{})

        result = dispatch(method, params, workspace_id)

        case result do
          {:ok, data} ->
            json(conn, %{jsonrpc: "2.0", id: id, result: data})

          {:error, code, message} ->
            json(conn, %{jsonrpc: "2.0", id: id, error: %{code: code, message: message}})
        end
    end
  end

  def messages(conn, _params) do
    conn |> put_status(400) |> json(%{error: "Missing session_id parameter"})
  end

  # Delegate to the existing MCP controller dispatch logic
  defp dispatch("initialize", _params, _workspace_id) do
    {:ok, %{
      protocolVersion: "2024-11-05",
      capabilities: %{tools: %{listChanged: false}},
      serverInfo: %{name: "jido-builder", version: "1.0.0"}
    }}
  end

  defp dispatch(method, params, workspace_id) do
    # Reuse existing MCP controller dispatch via internal call
    alias JidoBuilderWeb.MCP.ToolRegistry

    case method do
      "tools/list" ->
        {:ok, %{tools: ToolRegistry.list_for_mcp()}}

      "tools/call" ->
        case params do
          %{"name" => tool_name, "arguments" => arguments} ->
            case ToolRegistry.get(tool_name) do
              nil -> {:error, -32602, "Unknown tool: #{tool_name}"}
              tool ->
                context = %{workspace_id: workspace_id}
                case tool.handler.call(arguments, context) do
                  {:ok, result} ->
                    {:ok, %{content: [%{type: "text", text: format_result(result)}], isError: false}}
                  {:error, message} ->
                    {:ok, %{content: [%{type: "text", text: "Error: #{inspect(message)}"}], isError: true}}
                end
            end
          _ -> {:error, -32602, "Missing required params: name, arguments"}
        end

      "notifications/initialized" ->
        {:ok, %{}}

      _ ->
        {:error, -32601, "Method not found"}
    end
  end

  defp format_result(result) when is_binary(result), do: result
  defp format_result(result) when is_map(result), do: Jason.encode!(result, pretty: true)
  defp format_result(result) when is_list(result), do: Jason.encode!(result, pretty: true)
  defp format_result(result), do: inspect(result)

  defp sse_event(event, data) do
    "event: #{event}\ndata: #{data}\n\n"
  end

  defp generate_session_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
