defmodule JidoBuilderRuntime.Actions.Tools.CodeFormat do
  @moduledoc "Format Elixir code."
  use Jido.Action, name: "code_format", description: "Format Elixir source code", schema: [
    code: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    code = params[:code] || params["code"]
    try do
      formatted = Code.format_string!(code) |> IO.iodata_to_binary()
      {:ok, %{formatted: formatted}}
    rescue
      e -> {:ok, %{error: Exception.message(e)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.CodeLint do
  @moduledoc "Basic code quality checks."
  use Jido.Action, name: "code_lint", description: "Run basic code quality checks on Elixir code", schema: [
    code: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    code = params[:code] || params["code"]
    issues = []
    issues = if String.length(code) > 500, do: issues ++ ["Function may be too long"], else: issues
    issues = if String.contains?(code, "IO.inspect"), do: issues ++ ["Contains IO.inspect debug call"], else: issues
    issues = if String.contains?(code, "TODO"), do: issues ++ ["Contains TODO comment"], else: issues
    {:ok, %{issues: issues, issue_count: length(issues), clean?: length(issues) == 0}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.ShellExecute do
  @moduledoc "Execute a shell command (sandboxed)."
  use Jido.Action, name: "shell_execute", description: "Execute a whitelisted shell command", schema: [
    command: [type: :string, required: true],
    args: [type: {:list, :string}, required: false]
  ]

  @allowed_commands ~w(echo date whoami hostname pwd ls dir cat head tail wc grep find)

  def run(params, _ctx) do
    command = params[:command] || params["command"]
    args = params[:args] || params["args"] || []
    base_cmd = command |> String.split(" ") |> List.first()

    if base_cmd in @allowed_commands do
      case System.cmd(command, args, stderr_to_stdout: true) do
        {output, 0} -> {:ok, %{command: command, output: String.trim(output), exit_code: 0}}
        {output, code} -> {:ok, %{command: command, output: String.trim(output), exit_code: code}}
      end
    else
      {:ok, %{error: "Command '#{base_cmd}' not in whitelist", allowed: @allowed_commands}}
    end
  rescue
    e -> {:ok, %{error: Exception.message(e)}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.GitStatus do
  @moduledoc "Get git repository status."
  use Jido.Action, name: "git_status", description: "Get git status of the current or specified repo", schema: [
    path: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    path = params[:path] || params["path"] || "."
    case System.cmd("git", ["status", "--porcelain"], cd: path, stderr_to_stdout: true) do
      {output, 0} ->
        changes = String.split(output, "\n", trim: true)
        {:ok, %{path: path, changes: changes, clean?: length(changes) == 0}}
      {output, _} ->
        {:ok, %{path: path, error: String.trim(output)}}
    end
  rescue
    e -> {:ok, %{error: Exception.message(e)}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.GitDiff do
  @moduledoc "Get git diff output."
  use Jido.Action, name: "git_diff", description: "Get git diff for staged or unstaged changes", schema: [
    path: [type: :string, required: false],
    staged: [type: :boolean, required: false]
  ]

  def run(params, _ctx) do
    path = params[:path] || params["path"] || "."
    staged = params[:staged] || params["staged"] || false
    args = if staged, do: ["diff", "--staged"], else: ["diff"]

    case System.cmd("git", args, cd: path, stderr_to_stdout: true) do
      {output, 0} -> {:ok, %{diff: String.trim(output), lines: length(String.split(output, "\n"))}}
      {output, _} -> {:ok, %{error: String.trim(output)}}
    end
  rescue
    e -> {:ok, %{error: Exception.message(e)}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.DockerRun do
  @moduledoc "Placeholder for Docker container execution."
  use Jido.Action, name: "docker_run", description: "Run a Docker container (placeholder)", schema: [
    image: [type: :string, required: true],
    command: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    image = params[:image] || params["image"]
    {:ok, %{image: image, status: "placeholder", note: "Docker execution requires runtime configuration"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.TestRun do
  @moduledoc "Placeholder for running test suites."
  use Jido.Action, name: "test_run", description: "Run a test suite (placeholder)", schema: [
    path: [type: :string, required: false],
    pattern: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    path = params[:path] || params["path"] || "test/"
    {:ok, %{path: path, status: "placeholder", note: "Test execution requires runtime sandbox"}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.CodeGenerate do
  @moduledoc "Generate code from a template."
  use Jido.Action, name: "code_generate", description: "Generate Elixir module code from template", schema: [
    module_name: [type: :string, required: true],
    type: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    module_name = params[:module_name] || params["module_name"]
    type = params[:type] || params["type"]

    code = case type do
      "action" -> """
      defmodule #{module_name} do
        use Jido.Action, name: "#{Macro.underscore(module_name)}", description: "TODO", schema: []

        def run(_params, _ctx), do: {:ok, %{}}
      end
      """
      "genserver" -> """
      defmodule #{module_name} do
        use GenServer

        def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
        def init(opts), do: {:ok, opts}
      end
      """
      _ -> "defmodule #{module_name} do\nend"
    end

    {:ok, %{module_name: module_name, type: type, code: String.trim(code)}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.TemplateRender do
  @moduledoc "Render a text template with variable substitution."
  use Jido.Action, name: "template_render", description: "Render a text template with variable substitution", schema: [
    template: [type: :string, required: true],
    variables: [type: :any, required: false]
  ]

  def run(params, _ctx) do
    template = params[:template] || params["template"]
    variables = params[:variables] || params["variables"] || %{}

    rendered = Enum.reduce(variables, template, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", to_string(value))
    end)

    {:ok, %{rendered: rendered}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.MarkdownRender do
  @moduledoc "Convert Markdown to HTML."
  use Jido.Action, name: "markdown_render", description: "Convert Markdown text to HTML", schema: [
    markdown: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    markdown = params[:markdown] || params["markdown"]
    # Simple markdown conversion
    html = markdown
      |> String.replace(~r/^### (.+)$/m, "<h3>\\1</h3>")
      |> String.replace(~r/^## (.+)$/m, "<h2>\\1</h2>")
      |> String.replace(~r/^# (.+)$/m, "<h1>\\1</h1>")
      |> String.replace(~r/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
      |> String.replace(~r/\*(.+?)\*/, "<em>\\1</em>")
      |> String.replace(~r/`(.+?)`/, "<code>\\1</code>")
    {:ok, %{html: html}}
  end
end
