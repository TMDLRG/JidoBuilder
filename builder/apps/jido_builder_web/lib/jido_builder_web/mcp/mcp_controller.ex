defmodule JidoBuilderWeb.MCP.McpController do
  @moduledoc """
  MCP server endpoint. Handles JSON-RPC 2.0 requests for the MCP protocol.
  """
  use JidoBuilderWeb, :controller

  alias JidoBuilderWeb.MCP.ToolRegistry

  @protocol_version "2024-11-05"

  def handle(conn, %{"method" => method, "id" => id} = request) do
    params = Map.get(request, "params", %{})
    workspace_id = conn.assigns.workspace_id

    result = dispatch(method, params, workspace_id)

    case result do
      {:ok, data} ->
        json(conn, %{jsonrpc: "2.0", id: id, result: data})

      {:error, code, message} ->
        json(conn, %{jsonrpc: "2.0", id: id, error: %{code: code, message: message}})
    end
  end

  def handle(conn, _params) do
    json(conn, %{jsonrpc: "2.0", id: nil, error: %{code: -32600, message: "Invalid request"}})
  end

  defp dispatch("initialize", _params, _workspace_id) do
    {:ok, %{
      protocolVersion: @protocol_version,
      capabilities: %{
        tools: %{listChanged: false}
      },
      serverInfo: %{
        name: "jido-builder",
        version: "1.0.0"
      }
    }}
  end

  defp dispatch("tools/list", _params, _workspace_id) do
    {:ok, %{tools: ToolRegistry.list_for_mcp()}}
  end

  defp dispatch("tools/call", %{"name" => tool_name, "arguments" => arguments}, workspace_id) do
    case ToolRegistry.get(tool_name) do
      nil ->
        {:error, -32602, "Unknown tool: #{tool_name}"}

      tool ->
        context = %{workspace_id: workspace_id}

        case tool.handler.call(arguments, context) do
          {:ok, result} ->
            {:ok, %{
              content: [%{type: "text", text: format_result(result)}],
              isError: false
            }}

          {:error, message} ->
            {:ok, %{
              content: [%{type: "text", text: "Error: #{inspect(message)}"}],
              isError: true
            }}
        end
    end
  end

  defp dispatch("tools/call", _params, _workspace_id) do
    {:error, -32602, "Missing required params: name, arguments"}
  end

  defp dispatch("notifications/initialized", _params, _workspace_id) do
    {:ok, %{}}
  end

  defp dispatch(_method, _params, _workspace_id) do
    {:error, -32601, "Method not found"}
  end

  defp format_result(result) when is_binary(result), do: result
  defp format_result(result) when is_map(result), do: Jason.encode!(result, pretty: true)
  defp format_result(result) when is_list(result), do: Jason.encode!(result, pretty: true)
  defp format_result(result), do: inspect(result)
end
