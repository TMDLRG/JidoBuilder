defmodule JidoBuilderRuntime.Actions.Tools.WebFetch do
  @moduledoc "Fetch content from a URL via HTTP GET."
  use Jido.Action, name: "web_fetch", description: "Fetch content from a URL via HTTP GET", schema: [
    url: [type: :string, required: true],
    headers: [type: :map, required: false]
  ]

  def run(params, _ctx) do
    url = params[:url] || params["url"]
    headers = params[:headers] || params["headers"] || %{}
    header_list = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

    case Req.get(url, headers: header_list, receive_timeout: 15_000) do
      {:ok, %{status: status, body: body}} ->
        {:ok, %{url: url, status: status, body: truncate(body, 4000)}}
      {:error, reason} ->
        {:ok, %{url: url, error: inspect(reason)}}
    end
  end

  defp truncate(body, max) when is_binary(body) and byte_size(body) > max,
    do: binary_part(body, 0, max) <> "...[truncated]"
  defp truncate(body, _max) when is_binary(body), do: body
  defp truncate(body, max), do: truncate(inspect(body), max)
end

defmodule JidoBuilderRuntime.Actions.Tools.WebScrape do
  @moduledoc "Scrape text content from a web page."
  use Jido.Action, name: "web_scrape", description: "Scrape text content from a web page URL", schema: [
    url: [type: :string, required: true],
    selector: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    url = params[:url] || params["url"]
    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        text = body
          |> String.replace(~r/<script[^>]*>.*?<\/script>/s, "")
          |> String.replace(~r/<style[^>]*>.*?<\/style>/s, "")
          |> String.replace(~r/<[^>]+>/, " ")
          |> String.replace(~r/\s+/, " ")
          |> String.trim()
          |> truncate(4000)
        {:ok, %{url: url, text: text, length: String.length(text)}}
      {:ok, %{status: status}} ->
        {:ok, %{url: url, error: "HTTP #{status}"}}
      {:error, reason} ->
        {:ok, %{url: url, error: inspect(reason)}}
    end
  end

  defp truncate(text, max) when byte_size(text) > max,
    do: binary_part(text, 0, max) <> "...[truncated]"
  defp truncate(text, _max), do: text
end

defmodule JidoBuilderRuntime.Actions.Tools.ApiRestCall do
  @moduledoc "Make a REST API call."
  use Jido.Action, name: "api_rest_call", description: "Make a REST API call with method, URL, headers, body", schema: [
    method: [type: :string, required: true],
    url: [type: :string, required: true],
    headers: [type: :map, required: false],
    body: [type: :map, required: false]
  ]

  def run(params, _ctx) do
    method = (params[:method] || params["method"] || "GET") |> String.downcase() |> String.to_atom()
    url = params[:url] || params["url"]
    headers = params[:headers] || params["headers"] || %{}
    body = params[:body] || params["body"]
    header_list = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

    opts = [headers: header_list, receive_timeout: 30_000]
    opts = if body, do: Keyword.put(opts, :json, body), else: opts

    case Req.request([method: method, url: url] ++ opts) do
      {:ok, %{status: status, body: resp_body}} ->
        {:ok, %{status: status, body: resp_body}}
      {:error, reason} ->
        {:ok, %{error: inspect(reason)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.GraphqlCall do
  @moduledoc "Execute a GraphQL query."
  use Jido.Action, name: "graphql_call", description: "Execute a GraphQL query against an endpoint", schema: [
    url: [type: :string, required: true],
    query: [type: :string, required: true],
    variables: [type: :map, required: false]
  ]

  def run(params, _ctx) do
    url = params[:url] || params["url"]
    query = params[:query] || params["query"]
    variables = params[:variables] || params["variables"] || %{}

    case Req.post(url, json: %{query: query, variables: variables}, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} -> {:ok, %{data: body["data"], errors: body["errors"]}}
      {:ok, %{status: status}} -> {:ok, %{error: "HTTP #{status}"}}
      {:error, reason} -> {:ok, %{error: inspect(reason)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.UrlParse do
  @moduledoc "Parse a URL into components."
  use Jido.Action, name: "url_parse", description: "Parse a URL into host, path, query components", schema: [
    url: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    url = params[:url] || params["url"]
    uri = URI.parse(url)
    {:ok, %{
      scheme: uri.scheme, host: uri.host, port: uri.port,
      path: uri.path, query: uri.query, fragment: uri.fragment
    }}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.DnsLookup do
  @moduledoc "Resolve a hostname to IP addresses."
  use Jido.Action, name: "dns_lookup", description: "Resolve a hostname to IP addresses", schema: [
    hostname: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    hostname = params[:hostname] || params["hostname"]
    case :inet.getaddrs(String.to_charlist(hostname), :inet) do
      {:ok, addrs} ->
        ips = Enum.map(addrs, fn {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}" end)
        {:ok, %{hostname: hostname, addresses: ips}}
      {:error, reason} ->
        {:ok, %{hostname: hostname, error: to_string(reason)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.RssFetch do
  @moduledoc "Fetch and parse an RSS feed."
  use Jido.Action, name: "rss_fetch", description: "Fetch an RSS feed and extract items", schema: [
    url: [type: :string, required: true],
    limit: [type: :integer, required: false]
  ]

  def run(params, _ctx) do
    url = params[:url] || params["url"]
    limit = params[:limit] || params["limit"] || 10

    case Req.get(url, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        items = parse_rss_items(body, limit)
        {:ok, %{url: url, items: items, count: length(items)}}
      {:ok, %{status: status}} ->
        {:ok, %{url: url, error: "HTTP #{status}"}}
      {:error, reason} ->
        {:ok, %{url: url, error: inspect(reason)}}
    end
  end

  defp parse_rss_items(xml, limit) do
    title_regex = ~r/<title[^>]*>(.*?)<\/title>/s
    link_regex = ~r/<link[^>]*>(.*?)<\/link>/s
    titles = Regex.scan(title_regex, xml) |> Enum.map(&List.last/1) |> Enum.drop(1)
    links = Regex.scan(link_regex, xml) |> Enum.map(&List.last/1) |> Enum.drop(1)

    Enum.zip(titles, links)
    |> Enum.take(limit)
    |> Enum.map(fn {title, link} -> %{title: String.trim(title), link: String.trim(link)} end)
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.SearchWeb do
  @moduledoc "Placeholder for web search integration."
  use Jido.Action, name: "search_web", description: "Search the web for a query (placeholder)", schema: [
    query: [type: :string, required: true],
    limit: [type: :integer, required: false]
  ]

  def run(params, _ctx) do
    query = params[:query] || params["query"]
    {:ok, %{query: query, results: [], note: "Web search requires API key configuration"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.OauthRequest do
  @moduledoc "Make an OAuth-authenticated HTTP request."
  use Jido.Action, name: "oauth_request", description: "Make an OAuth-authenticated API request", schema: [
    url: [type: :string, required: true],
    token: [type: :string, required: true],
    method: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    url = params[:url] || params["url"]
    token = params[:token] || params["token"]
    method = (params[:method] || params["method"] || "GET") |> String.downcase() |> String.to_atom()

    case Req.request(method: method, url: url,
      headers: [{"authorization", "Bearer #{token}"}], receive_timeout: 30_000) do
      {:ok, %{status: status, body: body}} -> {:ok, %{status: status, body: body}}
      {:error, reason} -> {:ok, %{error: inspect(reason)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.WebsocketSend do
  @moduledoc "Placeholder for WebSocket message sending."
  use Jido.Action, name: "websocket_send", description: "Send a message via WebSocket (placeholder)", schema: [
    url: [type: :string, required: true],
    message: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    url = params[:url] || params["url"]
    message = params[:message] || params["message"]
    {:ok, %{url: url, message: message, sent: false, note: "WebSocket requires runtime connection"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.SmtpSend do
  @moduledoc "Placeholder for SMTP email sending."
  use Jido.Action, name: "smtp_send", description: "Send an email via SMTP (placeholder)", schema: [
    to: [type: :string, required: true],
    subject: [type: :string, required: true],
    body: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    to = params[:to] || params["to"]
    subject = params[:subject] || params["subject"]
    {:ok, %{to: to, subject: subject, sent: false, note: "SMTP requires server configuration"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.SmsSend do
  @moduledoc "Placeholder for SMS sending."
  use Jido.Action, name: "sms_send", description: "Send an SMS message (placeholder)", schema: [
    to: [type: :string, required: true],
    message: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    to = params[:to] || params["to"]
    {:ok, %{to: to, sent: false, note: "SMS requires provider configuration"}}
  end
end
