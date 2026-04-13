defmodule JidoBuilderRuntime.Actions.Tools.CsvParse do
  @moduledoc "Parse CSV text into rows."
  use Jido.Action, name: "csv_parse", description: "Parse CSV text into structured rows", schema: [
    content: [type: :string, required: true],
    delimiter: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    content = params[:content] || params["content"]
    delimiter = params[:delimiter] || params["delimiter"] || ","
    lines = String.split(content, "\n", trim: true)
    rows = Enum.map(lines, &String.split(&1, delimiter))
    {:ok, %{rows: rows, row_count: length(rows)}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.JsonParse do
  @moduledoc "Parse JSON string to map."
  use Jido.Action, name: "json_parse", description: "Parse a JSON string into structured data", schema: [
    content: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    content = params[:content] || params["content"]
    case Jason.decode(content) do
      {:ok, data} -> {:ok, %{data: data, type: json_type(data)}}
      {:error, _} -> {:ok, %{error: "Invalid JSON"}}
    end
  end

  defp json_type(data) when is_map(data), do: "object"
  defp json_type(data) when is_list(data), do: "array"
  defp json_type(_), do: "primitive"
end

defmodule JidoBuilderRuntime.Actions.Tools.XmlParse do
  @moduledoc "Parse XML string to a simplified map."
  use Jido.Action, name: "xml_parse", description: "Parse XML text and extract tag contents", schema: [
    content: [type: :string, required: true],
    tag: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    content = params[:content] || params["content"]
    tag = params[:tag] || params["tag"]

    if tag do
      regex = ~r/<#{Regex.escape(tag)}[^>]*>(.*?)<\/#{Regex.escape(tag)}>/s
      matches = Regex.scan(regex, content) |> Enum.map(&List.last/1)
      {:ok, %{tag: tag, values: matches, count: length(matches)}}
    else
      {:ok, %{content_length: String.length(content), type: "xml"}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.PdfExtract do
  @moduledoc "Extract text from PDF (placeholder — requires external library)."
  use Jido.Action, name: "pdf_extract", description: "Extract text content from a PDF file", schema: [
    path: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    path = params[:path] || params["path"]
    {:ok, %{path: path, text: "[PDF extraction requires external library]", pages: 0}}
  end
end
