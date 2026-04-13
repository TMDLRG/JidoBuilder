defmodule JidoBuilderRuntime.Actions.HttpRequest do
  @moduledoc "Execute HTTP requests (GET/POST/PUT/DELETE) and return the response."
  use Jido.Action,
    name: "http_request",
    description: "Sends an HTTP request and returns the response body",
    schema: [
      method: [type: :string, required: true],
      url: [type: :string, required: true],
      headers: [type: :map, default: %{}],
      body: [type: :any, default: nil],
      timeout: [type: :integer, default: 10_000]
    ]

  @spec run(map(), map()) :: {:ok, map()} | {:error, map()}
  def run(params, _context) do
    method = normalize_method(get_param(params, :method, "GET"))
    url = get_param(params, :url)
    headers = get_param(params, :headers, %{}) |> Map.to_list()
    body = get_param(params, :body)
    timeout = get_param(params, :timeout, 10_000)

    request_opts = [
      method: method,
      url: url,
      headers: headers,
      receive_timeout: timeout,
      retry: false
    ]

    request_opts = if body, do: Keyword.put(request_opts, :body, encode_body(body)), else: request_opts

    case Req.request(request_opts) do
      {:ok, %Req.Response{status: status, body: resp_body}} ->
        {:ok, %{status: status, body: resp_body, url: url, method: to_string(method)}}

      {:error, %{reason: reason}} ->
        {:error, %{code: :http_error, url: url, reason: inspect(reason)}}

      {:error, reason} ->
        {:error, %{code: :http_error, url: url, reason: inspect(reason)}}
    end
  end

  defp normalize_method(m) when is_binary(m), do: m |> String.downcase() |> String.to_atom()
  defp normalize_method(m) when is_atom(m), do: m

  defp encode_body(body) when is_map(body), do: Jason.encode!(body)
  defp encode_body(body) when is_binary(body), do: body
  defp encode_body(body), do: inspect(body)

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, to_string(key)) || default
  end
end
