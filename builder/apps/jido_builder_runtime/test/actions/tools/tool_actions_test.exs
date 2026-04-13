defmodule JidoBuilderRuntime.Actions.Tools.ToolActionsTest do
  @moduledoc "Epic 3.1-3.4 — All 50 tool actions compilation and basic run tests."
  use ExUnit.Case, async: true

  alias JidoBuilderRuntime.Actions.Tools

  # All 50 action modules
  @file_actions [Tools.FileRead, Tools.FileWrite, Tools.FileList]
  @data_actions [Tools.CsvParse, Tools.JsonParse, Tools.XmlParse, Tools.PdfExtract]
  @math_actions [
    Tools.MathCalculate, Tools.StatisticsCompute, Tools.RegexMatch,
    Tools.StringTransform, Tools.DatetimeCompute, Tools.HashCompute,
    Tools.Base64Encode, Tools.Base64Decode
  ]
  @web_actions [
    Tools.WebFetch, Tools.WebScrape, Tools.ApiRestCall, Tools.GraphqlCall,
    Tools.UrlParse, Tools.DnsLookup, Tools.RssFetch, Tools.SearchWeb,
    Tools.OauthRequest, Tools.WebsocketSend, Tools.SmtpSend, Tools.SmsSend
  ]
  @code_actions [
    Tools.CodeFormat, Tools.CodeLint, Tools.ShellExecute, Tools.GitStatus,
    Tools.GitDiff, Tools.DockerRun, Tools.TestRun, Tools.CodeGenerate,
    Tools.TemplateRender, Tools.MarkdownRender
  ]
  @integration_actions [
    Tools.SlackMessage, Tools.SlackChannelList, Tools.GithubIssue, Tools.GithubPr,
    Tools.JiraTicket, Tools.NotionPage, Tools.GoogleSheetsRead, Tools.GoogleSheetsWrite,
    Tools.S3Upload, Tools.S3Download, Tools.DatabaseQuery, Tools.RedisGet, Tools.RedisSet
  ]

  @all_actions @file_actions ++ @data_actions ++ @math_actions ++ @web_actions ++ @code_actions ++ @integration_actions

  describe "all actions compile and have metadata" do
    test "all 50 actions have name/0" do
      for mod <- @all_actions do
        assert is_binary(mod.name()), "#{inspect(mod)} missing name/0"
      end
    end

    test "all actions have description/0" do
      for mod <- @all_actions do
        assert is_binary(mod.description()), "#{inspect(mod)} missing description/0"
      end
    end

    test "all actions have schema/0" do
      for mod <- @all_actions do
        assert is_list(mod.schema()), "#{inspect(mod)} missing schema/0"
      end
    end

    test "total action count is 50" do
      assert length(@all_actions) == 50
    end

    test "all action names are unique" do
      names = Enum.map(@all_actions, & &1.name())
      assert length(names) == length(Enum.uniq(names))
    end

    test "all convert to LLM tool schemas" do
      for mod <- @all_actions do
        tool = Jido.Action.Tool.to_tool(mod)
        assert is_binary(tool.name)
        assert is_binary(tool.description)
        assert is_map(tool.parameters_schema)
      end
    end
  end

  describe "File & Data actions" do
    test "CsvParse parses CSV text" do
      {:ok, result} = Jido.Exec.run(Tools.CsvParse, %{content: "a,b,c\n1,2,3"}, %{})
      assert result.row_count == 2
    end

    test "JsonParse parses JSON" do
      {:ok, result} = Jido.Exec.run(Tools.JsonParse, %{content: ~s({"key":"value"})}, %{})
      assert result.data["key"] == "value"
    end

    test "XmlParse extracts tag content" do
      {:ok, result} = Jido.Exec.run(Tools.XmlParse,
        %{content: "<item>hello</item><item>world</item>", tag: "item"}, %{})
      assert result.count == 2
    end

    test "StatisticsCompute computes stats" do
      {:ok, result} = Jido.Exec.run(Tools.StatisticsCompute,
        %{values: [1.0, 2.0, 3.0, 4.0, 5.0]}, %{})
      assert result.mean == 3.0
      assert result.min == 1.0
      assert result.max == 5.0
    end

    test "RegexMatch finds matches" do
      {:ok, result} = Jido.Exec.run(Tools.RegexMatch,
        %{text: "foo123bar456", pattern: "\\d+"}, %{})
      assert result.count == 2
    end

    test "StringTransform upcases" do
      {:ok, result} = Jido.Exec.run(Tools.StringTransform,
        %{text: "hello", operation: "upcase"}, %{})
      assert result.result == "HELLO"
    end

    test "DatetimeCompute returns now" do
      {:ok, result} = Jido.Exec.run(Tools.DatetimeCompute, %{operation: "now"}, %{})
      assert result.datetime != nil
    end

    test "HashCompute returns sha256" do
      {:ok, result} = Jido.Exec.run(Tools.HashCompute, %{text: "hello"}, %{})
      assert String.length(result.hash) == 64
    end

    test "Base64 encode/decode roundtrip" do
      {:ok, encoded} = Jido.Exec.run(Tools.Base64Encode, %{text: "hello"}, %{})
      {:ok, decoded} = Jido.Exec.run(Tools.Base64Decode, %{text: encoded.encoded}, %{})
      assert decoded.decoded == "hello"
    end

    test "FileList lists files" do
      {:ok, result} = Jido.Exec.run(Tools.FileList, %{path: ".", pattern: "mix.exs"}, %{})
      assert is_list(result.files)
    end
  end

  describe "Web & API actions" do
    test "UrlParse extracts components" do
      {:ok, result} = Jido.Exec.run(Tools.UrlParse,
        %{url: "https://example.com:8080/path?q=1"}, %{})
      assert result.host == "example.com"
      assert result.port == 8080
      assert result.path == "/path"
    end

    test "SearchWeb returns placeholder" do
      {:ok, result} = Jido.Exec.run(Tools.SearchWeb, %{query: "test"}, %{})
      assert result.results == []
    end
  end

  describe "Code & Dev actions" do
    test "CodeFormat formats elixir code" do
      {:ok, result} = Jido.Exec.run(Tools.CodeFormat,
        %{code: "def foo(  x  ) do   x+1   end"}, %{})
      assert result.formatted != nil
    end

    test "CodeLint detects issues" do
      {:ok, result} = Jido.Exec.run(Tools.CodeLint,
        %{code: "IO.inspect(x) # TODO fix"}, %{})
      assert result.issue_count >= 2
    end

    test "CodeGenerate generates action module" do
      {:ok, result} = Jido.Exec.run(Tools.CodeGenerate,
        %{module_name: "MyApp.NewAction", type: "action"}, %{})
      assert String.contains?(result.code, "use Jido.Action")
    end

    test "TemplateRender substitutes variables" do
      {:ok, result} = Jido.Exec.run(Tools.TemplateRender,
        %{template: "Hello {{name}}, you are {{age}}", variables: %{"name" => "Alice", "age" => "30"}}, %{})
      assert result.rendered == "Hello Alice, you are 30"
    end

    test "MarkdownRender converts to HTML" do
      {:ok, result} = Jido.Exec.run(Tools.MarkdownRender,
        %{markdown: "# Title\n**bold** text"}, %{})
      assert String.contains?(result.html, "<h1>")
      assert String.contains?(result.html, "<strong>")
    end
  end

  describe "Integration actions" do
    test "SlackChannelList returns placeholder" do
      {:ok, result} = Jido.Exec.run(Tools.SlackChannelList, %{token: "test"}, %{})
      assert result.channels == []
    end

    test "GithubPr returns placeholder" do
      {:ok, result} = Jido.Exec.run(Tools.GithubPr, %{action: "list", repo: "owner/repo", token: "t"}, %{})
      assert result.note != nil
    end

    test "RedisGet returns placeholder" do
      {:ok, result} = Jido.Exec.run(Tools.RedisGet, %{key: "test"}, %{})
      assert result.value == nil
    end

    test "DatabaseQuery returns placeholder" do
      {:ok, result} = Jido.Exec.run(Tools.DatabaseQuery, %{query: "SELECT 1"}, %{})
      assert result.rows == []
    end
  end
end
