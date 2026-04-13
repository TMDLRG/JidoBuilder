defmodule JidoBuilderRuntime.ActionRegistry do
  @moduledoc """
  Registry of all built-in builder action patterns.

  Provides a static catalog of actions available for template routes and
  the action builder page. Each entry includes the module, slug, name,
  description, and category for UI display.
  """

  alias JidoBuilderRuntime.Actions.{
    Echo,
    HttpRequest,
    IncrementCounter,
    JsonTransform,
    LlmChat,
    LogMessage,
    StateMutation,
    TransformData,
    WebhookCall
  }

  alias JidoBuilderRuntime.Actions.Tools
  alias JidoBuilderRuntime.Integrations.{Slack, Email, HttpWebhook}
  alias JidoBuilderRuntime.LLM.MemoryTools

  @actions [
    %{
      slug: "echo",
      module: Echo,
      name: "Echo",
      description: "Returns the inbound message payload",
      category: :utility
    },
    %{
      slug: "increment_counter",
      module: IncrementCounter,
      name: "Increment Counter",
      description: "Increments counter by amount",
      category: :state
    },
    %{
      slug: "log_message",
      module: LogMessage,
      name: "Log Message",
      description: "Appends message payload to log",
      category: :utility
    },
    %{
      slug: "transform_data",
      module: TransformData,
      name: "Transform Data",
      description: "Transforms data via uppercase/reverse/sort",
      category: :transform
    },
    %{
      slug: "http_request",
      module: HttpRequest,
      name: "HTTP Request",
      description: "Sends an HTTP request and returns the response body",
      category: :integration
    },
    %{
      slug: "json_transform",
      module: JsonTransform,
      name: "JSON Transform",
      description: "Transforms JSON data via pick/flatten/merge/filter operations",
      category: :transform
    },
    %{
      slug: "state_mutation",
      module: StateMutation,
      name: "State Mutation",
      description: "Mutates state data via set/delete/merge operations",
      category: :state
    },
    %{
      slug: "webhook_call",
      module: WebhookCall,
      name: "Webhook Call",
      description: "Sends a JSON POST to a webhook endpoint",
      category: :integration
    },
    %{
      slug: "slack_webhook",
      module: Slack,
      name: "Slack Webhook",
      description: "Sends a message to a Slack channel via webhook",
      category: :integration
    },
    %{
      slug: "send_email",
      module: Email,
      name: "Send Email",
      description: "Sends an email notification via SMTP or HTTP endpoint",
      category: :integration
    },
    %{
      slug: "http_webhook",
      module: HttpWebhook,
      name: "HTTP Webhook",
      description: "Sends a generic HTTP webhook with configurable method/headers",
      category: :integration
    },
    # -- File & Data Tools --
    %{slug: "file_read", module: Tools.FileRead, name: "File Read", description: "Read contents of a file by path", category: :file},
    %{slug: "file_write", module: Tools.FileWrite, name: "File Write", description: "Write content to a file path", category: :file},
    %{slug: "file_list", module: Tools.FileList, name: "File List", description: "List files in a directory", category: :file},
    %{slug: "csv_parse", module: Tools.CsvParse, name: "CSV Parse", description: "Parse CSV text into structured rows", category: :data},
    %{slug: "json_parse", module: Tools.JsonParse, name: "JSON Parse", description: "Parse a JSON string into structured data", category: :data},
    %{slug: "xml_parse", module: Tools.XmlParse, name: "XML Parse", description: "Parse XML text and extract tag contents", category: :data},
    %{slug: "pdf_extract", module: Tools.PdfExtract, name: "PDF Extract", description: "Extract text content from a PDF file", category: :data},
    %{slug: "math_calculate", module: Tools.MathCalculate, name: "Math Calculate", description: "Evaluate a mathematical expression", category: :data},
    %{slug: "statistics_compute", module: Tools.StatisticsCompute, name: "Statistics Compute", description: "Compute mean, median, min, max, std dev", category: :data},
    %{slug: "regex_match", module: Tools.RegexMatch, name: "Regex Match", description: "Match a regex pattern against text", category: :data},
    %{slug: "string_transform", module: Tools.StringTransform, name: "String Transform", description: "Transform text: upcase, downcase, trim, reverse", category: :data},
    %{slug: "datetime_compute", module: Tools.DatetimeCompute, name: "Datetime Compute", description: "Get current datetime or compute differences", category: :data},
    %{slug: "hash_compute", module: Tools.HashCompute, name: "Hash Compute", description: "Compute hash (md5, sha256) of text", category: :data},
    %{slug: "base64_encode", module: Tools.Base64Encode, name: "Base64 Encode", description: "Base64 encode text", category: :data},
    %{slug: "base64_decode", module: Tools.Base64Decode, name: "Base64 Decode", description: "Base64 decode text", category: :data},
    # -- Web & API Tools --
    %{slug: "web_fetch", module: Tools.WebFetch, name: "Web Fetch", description: "Fetch content from a URL via HTTP GET", category: :web},
    %{slug: "web_scrape", module: Tools.WebScrape, name: "Web Scrape", description: "Scrape text content from a web page", category: :web},
    %{slug: "api_rest_call", module: Tools.ApiRestCall, name: "REST API Call", description: "Make a REST API call", category: :web},
    %{slug: "graphql_call", module: Tools.GraphqlCall, name: "GraphQL Call", description: "Execute a GraphQL query", category: :web},
    %{slug: "url_parse", module: Tools.UrlParse, name: "URL Parse", description: "Parse a URL into components", category: :web},
    %{slug: "dns_lookup", module: Tools.DnsLookup, name: "DNS Lookup", description: "Resolve a hostname to IP addresses", category: :web},
    %{slug: "rss_fetch", module: Tools.RssFetch, name: "RSS Fetch", description: "Fetch an RSS feed and extract items", category: :web},
    %{slug: "search_web", module: Tools.SearchWeb, name: "Web Search", description: "Search the web for a query", category: :search},
    %{slug: "oauth_request", module: Tools.OauthRequest, name: "OAuth Request", description: "Make an OAuth-authenticated API request", category: :web},
    %{slug: "websocket_send", module: Tools.WebsocketSend, name: "WebSocket Send", description: "Send a message via WebSocket", category: :web},
    %{slug: "smtp_send", module: Tools.SmtpSend, name: "SMTP Send", description: "Send an email via SMTP", category: :notification},
    %{slug: "sms_send", module: Tools.SmsSend, name: "SMS Send", description: "Send an SMS message", category: :notification},
    # -- Code & Dev Tools --
    %{slug: "code_format", module: Tools.CodeFormat, name: "Code Format", description: "Format Elixir source code", category: :code},
    %{slug: "code_lint", module: Tools.CodeLint, name: "Code Lint", description: "Run basic code quality checks", category: :code},
    %{slug: "shell_execute", module: Tools.ShellExecute, name: "Shell Execute", description: "Execute a whitelisted shell command", category: :code},
    %{slug: "git_status", module: Tools.GitStatus, name: "Git Status", description: "Get git status of a repo", category: :code},
    %{slug: "git_diff", module: Tools.GitDiff, name: "Git Diff", description: "Get git diff output", category: :code},
    %{slug: "docker_run", module: Tools.DockerRun, name: "Docker Run", description: "Run a Docker container", category: :code},
    %{slug: "test_run", module: Tools.TestRun, name: "Test Run", description: "Run a test suite", category: :code},
    %{slug: "code_generate", module: Tools.CodeGenerate, name: "Code Generate", description: "Generate Elixir module code from template", category: :code},
    %{slug: "template_render", module: Tools.TemplateRender, name: "Template Render", description: "Render a text template with variables", category: :code},
    %{slug: "markdown_render", module: Tools.MarkdownRender, name: "Markdown Render", description: "Convert Markdown to HTML", category: :code},
    # -- Integration Tools --
    %{slug: "slack_message", module: Tools.SlackMessage, name: "Slack Message", description: "Send a Slack message via webhook", category: :integration},
    %{slug: "slack_channel_list", module: Tools.SlackChannelList, name: "Slack Channels", description: "List Slack channels", category: :integration},
    %{slug: "github_issue", module: Tools.GithubIssue, name: "GitHub Issue", description: "Create or list GitHub issues", category: :integration},
    %{slug: "github_pr", module: Tools.GithubPr, name: "GitHub PR", description: "Create or list GitHub pull requests", category: :integration},
    %{slug: "jira_ticket", module: Tools.JiraTicket, name: "Jira Ticket", description: "Create or query Jira tickets", category: :integration},
    %{slug: "notion_page", module: Tools.NotionPage, name: "Notion Page", description: "Create or read Notion pages", category: :integration},
    %{slug: "google_sheets_read", module: Tools.GoogleSheetsRead, name: "Sheets Read", description: "Read from Google Sheets", category: :integration},
    %{slug: "google_sheets_write", module: Tools.GoogleSheetsWrite, name: "Sheets Write", description: "Write to Google Sheets", category: :integration},
    %{slug: "s3_upload", module: Tools.S3Upload, name: "S3 Upload", description: "Upload a file to S3", category: :integration},
    %{slug: "s3_download", module: Tools.S3Download, name: "S3 Download", description: "Download a file from S3", category: :integration},
    %{slug: "database_query", module: Tools.DatabaseQuery, name: "Database Query", description: "Execute a database query", category: :integration},
    %{slug: "redis_get", module: Tools.RedisGet, name: "Redis Get", description: "Get a value from Redis", category: :integration},
    %{slug: "redis_set", module: Tools.RedisSet, name: "Redis Set", description: "Set a value in Redis", category: :integration},
    # LLM
    %{slug: "llm_chat", module: LlmChat, name: "LLM Chat", description: "Send a message through an LLM with agentic tool-use loop", category: :llm},
    # Memory
    %{slug: "memory_read", module: MemoryTools.MemoryRead, name: "Memory Read", description: "Read a value from agent memory", category: :memory},
    %{slug: "memory_write", module: MemoryTools.MemoryWrite, name: "Memory Write", description: "Write a value to agent memory", category: :memory},
    %{slug: "memory_search", module: MemoryTools.MemorySearch, name: "Memory Search", description: "Search agent memory by pattern", category: :memory}
  ]

  @action_map Map.new(@actions, fn a -> {a.slug, a} end)

  @doc "Returns all registered builder actions."
  @spec list() :: [map()]
  def list, do: @actions

  @doc "Returns actions filtered by category."
  @spec list_by_category(atom()) :: [map()]
  def list_by_category(category) when is_atom(category) do
    Enum.filter(@actions, fn a -> a.category == category end)
  end

  @doc "Returns a single action by slug, or nil."
  @spec get(String.t()) :: map() | nil
  def get(slug) when is_binary(slug), do: Map.get(@action_map, slug)

  @doc "Returns all unique categories."
  @spec categories() :: [atom()]
  def categories, do: @actions |> Enum.map(& &1.category) |> Enum.uniq() |> Enum.sort()
end
