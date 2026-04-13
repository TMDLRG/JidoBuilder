defmodule JidoBuilderRuntime.Actions.Tools.SlackMessage do
  @moduledoc "Send a message to Slack via webhook."
  use Jido.Action, name: "slack_message", description: "Send a message to a Slack channel via webhook URL", schema: [
    webhook_url: [type: :string, required: true],
    text: [type: :string, required: true],
    channel: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    url = params[:webhook_url] || params["webhook_url"]
    text = params[:text] || params["text"]
    body = %{text: text}
    body = if params[:channel], do: Map.put(body, :channel, params[:channel]), else: body

    case Req.post(url, json: body, receive_timeout: 10_000) do
      {:ok, %{status: 200}} -> {:ok, %{sent: true, channel: params[:channel]}}
      {:ok, %{status: s}} -> {:ok, %{sent: false, error: "HTTP #{s}"}}
      {:error, r} -> {:ok, %{sent: false, error: inspect(r)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.SlackChannelList do
  @moduledoc "Placeholder for listing Slack channels."
  use Jido.Action, name: "slack_channel_list", description: "List Slack channels (requires API token)", schema: [
    token: [type: :string, required: true]
  ]

  def run(_params, _ctx) do
    {:ok, %{channels: [], note: "Requires Slack API token and OAuth scope"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.GithubIssue do
  @moduledoc "Create or list GitHub issues."
  use Jido.Action, name: "github_issue", description: "Create or list GitHub issues", schema: [
    action: [type: :string, required: true],
    repo: [type: :string, required: true],
    token: [type: :string, required: true],
    title: [type: :string, required: false],
    body: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    action = params[:action] || params["action"]
    repo = params[:repo] || params["repo"]
    token = params[:token] || params["token"]
    headers = [{"authorization", "Bearer #{token}"}, {"accept", "application/vnd.github+json"}]
    base_url = "https://api.github.com/repos/#{repo}/issues"

    case action do
      "list" ->
        case Req.get(base_url, headers: headers, receive_timeout: 15_000) do
          {:ok, %{status: 200, body: issues}} ->
            items = Enum.take(issues, 10) |> Enum.map(fn i -> %{number: i["number"], title: i["title"], state: i["state"]} end)
            {:ok, %{issues: items, count: length(items)}}
          {:ok, %{status: s}} -> {:ok, %{error: "HTTP #{s}"}}
          {:error, r} -> {:ok, %{error: inspect(r)}}
        end
      "create" ->
        title = params[:title] || params["title"]
        body = params[:body] || params["body"] || ""
        case Req.post(base_url, json: %{title: title, body: body}, headers: headers) do
          {:ok, %{status: 201, body: issue}} -> {:ok, %{number: issue["number"], url: issue["html_url"]}}
          {:ok, %{status: s}} -> {:ok, %{error: "HTTP #{s}"}}
          {:error, r} -> {:ok, %{error: inspect(r)}}
        end
      _ -> {:ok, %{error: "Unknown action: #{action}"}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.GithubPr do
  @moduledoc "Placeholder for GitHub PR operations."
  use Jido.Action, name: "github_pr", description: "Create or list GitHub pull requests", schema: [
    action: [type: :string, required: true],
    repo: [type: :string, required: true],
    token: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{action: params[:action] || params["action"], note: "GitHub PR operations placeholder"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.JiraTicket do
  @moduledoc "Placeholder for Jira ticket operations."
  use Jido.Action, name: "jira_ticket", description: "Create or query Jira tickets (placeholder)", schema: [
    action: [type: :string, required: true],
    project: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{action: params[:action] || params["action"], project: params[:project] || params["project"], note: "Requires Jira API configuration"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.NotionPage do
  @moduledoc "Placeholder for Notion page operations."
  use Jido.Action, name: "notion_page", description: "Create or read Notion pages (placeholder)", schema: [
    action: [type: :string, required: true],
    token: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{action: params[:action] || params["action"], note: "Requires Notion integration token"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.GoogleSheetsRead do
  @moduledoc "Placeholder for Google Sheets read."
  use Jido.Action, name: "google_sheets_read", description: "Read data from Google Sheets (placeholder)", schema: [
    spreadsheet_id: [type: :string, required: true],
    range: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{spreadsheet_id: params[:spreadsheet_id] || params["spreadsheet_id"], range: params[:range] || params["range"], data: [], note: "Requires Google API credentials"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.GoogleSheetsWrite do
  @moduledoc "Placeholder for Google Sheets write."
  use Jido.Action, name: "google_sheets_write", description: "Write data to Google Sheets (placeholder)", schema: [
    spreadsheet_id: [type: :string, required: true],
    range: [type: :string, required: true],
    values: [type: {:list, :any}, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{spreadsheet_id: params[:spreadsheet_id] || params["spreadsheet_id"], written: false, note: "Requires Google API credentials"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.S3Upload do
  @moduledoc "Placeholder for S3 file upload."
  use Jido.Action, name: "s3_upload", description: "Upload a file to S3 (placeholder)", schema: [
    bucket: [type: :string, required: true],
    key: [type: :string, required: true],
    content: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{bucket: params[:bucket] || params["bucket"], key: params[:key] || params["key"], uploaded: false, note: "Requires AWS credentials"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.S3Download do
  @moduledoc "Placeholder for S3 file download."
  use Jido.Action, name: "s3_download", description: "Download a file from S3 (placeholder)", schema: [
    bucket: [type: :string, required: true],
    key: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{bucket: params[:bucket] || params["bucket"], key: params[:key] || params["key"], content: nil, note: "Requires AWS credentials"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.DatabaseQuery do
  @moduledoc "Placeholder for database query execution."
  use Jido.Action, name: "database_query", description: "Execute a database query (placeholder)", schema: [
    query: [type: :string, required: true],
    database: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    {:ok, %{query: params[:query] || params["query"], rows: [], note: "Requires database connection configuration"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.RedisGet do
  @moduledoc "Placeholder for Redis GET."
  use Jido.Action, name: "redis_get", description: "Get a value from Redis by key (placeholder)", schema: [
    key: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    {:ok, %{key: params[:key] || params["key"], value: nil, note: "Requires Redis connection"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.RedisSet do
  @moduledoc "Placeholder for Redis SET."
  use Jido.Action, name: "redis_set", description: "Set a value in Redis (placeholder)", schema: [
    key: [type: :string, required: true],
    value: [type: :string, required: true],
    ttl: [type: :integer, required: false]
  ]

  def run(params, _ctx) do
    {:ok, %{key: params[:key] || params["key"], set: false, note: "Requires Redis connection"}}
  end
end
