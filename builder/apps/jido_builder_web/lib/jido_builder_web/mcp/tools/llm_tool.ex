defmodule JidoBuilderWeb.MCP.Tools.LlmTool do
  @moduledoc "MCP tool: jido_llm — configure LLM provider, manage conversations."

  def call(%{"action" => "help"}, _ctx), do: {:ok, help_text()}

  def call(%{"action" => "providers"}, _ctx) do
    {:ok, [
      %{name: "anthropic", models: ["claude-sonnet-4-20250514", "claude-haiku-4-5-20251001"]},
      %{name: "openai", models: ["gpt-4", "gpt-4o", "gpt-3.5-turbo"]},
      %{name: "mock", models: ["mock-model-v1"]}
    ]}
  end

  def call(%{"action" => "configure"} = args, _ctx) do
    config = %{
      provider: args["provider"] || "mock",
      model: args["model"] || "mock-model-v1",
      temperature: args["temperature"] || 0.7,
      max_tokens: args["max_tokens"] || 1024,
      system: args["system"]
    }
    {:ok, %{configured: true, config: config}}
  end

  def call(%{"action" => "chat", "message" => message} = args, _ctx) do
    provider = args["provider"] || "mock"
    model = args["model"] || "mock-model-v1"
    {:ok, %{
      provider: provider,
      model: model,
      message: message,
      response: "LLM chat requires runtime agent context. Use jido_agent dispatch instead.",
      note: "Configure LLM via template and dispatch signals to the agent."
    }}
  end

  def call(_, _), do: {:ok, help_text()}

  defp help_text do
    """
    jido_llm — LLM configuration and management

    Actions:
      providers              — List available LLM providers and models
      configure {provider, model, ...} — Configure an LLM connection
      chat {message}         — Send a chat message (requires agent context)
      help                   — Show this help
    """
  end
end
