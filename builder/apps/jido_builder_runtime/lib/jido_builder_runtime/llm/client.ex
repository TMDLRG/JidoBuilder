defmodule JidoBuilderRuntime.LLM.Client do
  @moduledoc """
  LLM Client abstraction for JidoBuilder.

  Provides a unified interface for interacting with different LLM providers
  (Anthropic, OpenAI, Mock). Dispatches calls to the appropriate provider
  module based on the `:provider` key in the config.

  ## Config

      %{
        provider: :anthropic | :openai | :mock,
        model: "claude-sonnet-4-20250514",
        api_key: "sk-...",
        max_tokens: 1024,
        temperature: 0.7,
        system: "You are a helpful assistant."
      }

  ## Usage

      {:ok, response} = Client.chat(messages, config)
      {:ok, response} = Client.chat_with_tools(messages, tools, config)
      {:ok, stream} = Client.stream(messages, config)
  """

  alias JidoBuilderRuntime.LLM.Providers.{Anthropic, OpenAI, Mock}

  defmodule ToolUse do
    @moduledoc "Represents an LLM tool use request."
    defstruct [:id, :name, :arguments]

    @type t :: %__MODULE__{
            id: String.t() | nil,
            name: String.t(),
            arguments: map()
          }
  end

  defmodule Response do
    @moduledoc "Normalized LLM response."
    defstruct [:role, :content, :tool_use, :usage, :stop_reason, :model]

    @type t :: %__MODULE__{
            role: String.t(),
            content: String.t() | nil,
            tool_use: JidoBuilderRuntime.LLM.Client.ToolUse.t() | nil,
            usage: map() | nil,
            stop_reason: String.t() | nil,
            model: String.t() | nil
          }
  end

  defmodule StreamChunk do
    @moduledoc "A chunk from an LLM streaming response."
    defstruct [:content, :tool_use, :done?]

    @type t :: %__MODULE__{
            content: String.t() | nil,
            tool_use: JidoBuilderRuntime.LLM.Client.ToolUse.t() | nil,
            done?: boolean()
          }
  end

  @type messages :: [%{role: String.t(), content: String.t()}]
  @type config :: map()
  @type tool_schema :: %{name: String.t(), description: String.t(), parameters_schema: map()}

  @doc "Send a chat request to the configured LLM provider."
  @callback chat(messages(), config()) :: {:ok, Response.t()} | {:error, term()}

  @doc "Send a chat request with tool definitions."
  @callback chat_with_tools(messages(), [tool_schema()], config()) ::
              {:ok, Response.t()} | {:error, term()}

  @doc "Send a streaming chat request. Returns an enumerable of StreamChunk."
  @callback stream(messages(), config()) :: {:ok, Enumerable.t()} | {:error, term()}

  # -- Dispatch --

  @doc "Dispatch chat to the configured provider."
  @spec chat(messages(), config()) :: {:ok, Response.t()} | {:error, term()}
  def chat(messages, config) do
    provider = provider_module(config[:provider] || :mock)
    provider.chat(messages, config)
  end

  @doc "Dispatch chat_with_tools to the configured provider."
  @spec chat_with_tools(messages(), [tool_schema()], config()) ::
          {:ok, Response.t()} | {:error, term()}
  def chat_with_tools(messages, tools, config) do
    provider = provider_module(config[:provider] || :mock)
    provider.chat_with_tools(messages, tools, config)
  end

  @doc "Dispatch stream to the configured provider."
  @spec stream(messages(), config()) :: {:ok, Enumerable.t()} | {:error, term()}
  def stream(messages, config) do
    provider = provider_module(config[:provider] || :mock)
    provider.stream(messages, config)
  end

  @doc "Resolve a provider atom to its module."
  @spec provider_module(atom()) :: module()
  def provider_module(:mock), do: Mock
  def provider_module(:anthropic), do: Anthropic
  def provider_module(:openai), do: OpenAI
  def provider_module(module) when is_atom(module), do: module
end
