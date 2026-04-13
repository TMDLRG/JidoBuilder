defmodule JidoBuilderRuntime.Integrations.Email do
  @moduledoc "Email integration action via HTTP endpoint."
  use Jido.Action,
    name: "send_email",
    description: "Sends an email notification via SMTP or HTTP endpoint",
    schema: [
      to: [type: :string, required: true],
      subject: [type: :string, required: true],
      body: [type: :string, required: true],
      from: [type: :string, default: "noreply@jidobuilder.dev"],
      endpoint_url: [type: :string]
    ]

  @doc "Validate required fields."
  def validate(params) do
    cond do
      !get_param(params, :to) -> {:error, "to is required"}
      !get_param(params, :subject) -> {:error, "subject is required"}
      !get_param(params, :body) -> {:error, "body is required"}
      true -> :ok
    end
  end

  @doc "Build an email message map."
  def build_message(params) do
    %{
      to: get_param(params, :to),
      from: get_param(params, :from, "noreply@jidobuilder.dev"),
      subject: get_param(params, :subject),
      body: get_param(params, :body)
    }
  end

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    case validate(params) do
      {:error, msg} ->
        {:error, %{code: :validation_error, message: msg}}

      :ok ->
        message = build_message(params)
        endpoint = get_param(params, :endpoint_url)

        if endpoint do
          case Req.post(endpoint, json: message, receive_timeout: 10_000, retry: false) do
            {:ok, %{status: status}} when status in 200..299 ->
              {:ok, %{status: "sent", to: message.to}}

            {:ok, %{status: status}} ->
              {:error, %{code: :email_error, status: status}}

            {:error, reason} ->
              {:error, %{code: :email_error, reason: inspect(reason)}}
          end
        else
          {:ok, %{status: "queued", to: message.to, message: message}}
        end
    end
  end

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, to_string(key)) || default
  end
end
