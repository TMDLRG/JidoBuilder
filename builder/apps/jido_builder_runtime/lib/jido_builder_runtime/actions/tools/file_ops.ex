defmodule JidoBuilderRuntime.Actions.Tools.FileRead do
  @moduledoc "Read contents of a file."
  use Jido.Action, name: "file_read", description: "Read contents of a file by path", schema: [
    path: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    path = params[:path] || params["path"]
    case File.read(path) do
      {:ok, content} -> {:ok, %{path: path, content: content, size: byte_size(content)}}
      {:error, reason} -> {:ok, %{path: path, error: to_string(reason)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.FileWrite do
  @moduledoc "Write contents to a file."
  use Jido.Action, name: "file_write", description: "Write content to a file path", schema: [
    path: [type: :string, required: true],
    content: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    path = params[:path] || params["path"]
    content = params[:content] || params["content"]
    case File.write(path, content) do
      :ok -> {:ok, %{path: path, written: true, size: byte_size(content)}}
      {:error, reason} -> {:ok, %{path: path, error: to_string(reason)}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.FileList do
  @moduledoc "List files in a directory."
  use Jido.Action, name: "file_list", description: "List files in a directory", schema: [
    path: [type: :string, required: true],
    pattern: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    path = params[:path] || params["path"]
    pattern = params[:pattern] || params["pattern"] || "*"
    full_pattern = Path.join(path, pattern)
    files = Path.wildcard(full_pattern) |> Enum.map(&Path.basename/1)
    {:ok, %{path: path, files: files, count: length(files)}}
  end
end
