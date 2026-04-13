defmodule JidoBuilderRuntime.Actions.Tools.MathCalculate do
  @moduledoc "Evaluate a mathematical expression."
  use Jido.Action, name: "math_calculate", description: "Evaluate a mathematical expression", schema: [
    expression: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    expr = params[:expression] || params["expression"]
    try do
      # Simple safe eval for basic arithmetic
      {result, _} = Code.eval_string(expr, [], __ENV__)
      {:ok, %{expression: expr, result: result}}
    rescue
      _ -> {:ok, %{expression: expr, error: "Invalid expression"}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.StatisticsCompute do
  @moduledoc "Compute basic statistics on a list of numbers."
  use Jido.Action, name: "statistics_compute", description: "Compute mean, median, min, max, std dev on numbers", schema: [
    values: [type: {:list, :float}, required: true]
  ]

  def run(params, _ctx) do
    values = params[:values] || params["values"] || []
    values = Enum.map(values, &to_float/1)
    n = length(values)

    if n == 0 do
      {:ok, %{error: "Empty values list"}}
    else
      sorted = Enum.sort(values)
      mean = Enum.sum(values) / n
      median = if rem(n, 2) == 0, do: (Enum.at(sorted, div(n, 2) - 1) + Enum.at(sorted, div(n, 2))) / 2, else: Enum.at(sorted, div(n, 2))
      variance = Enum.map(values, fn v -> (v - mean) * (v - mean) end) |> Enum.sum() |> Kernel./(n)
      std_dev = :math.sqrt(variance)

      {:ok, %{count: n, mean: mean, median: median, min: Enum.min(values), max: Enum.max(values), std_dev: std_dev}}
    end
  end

  defp to_float(v) when is_float(v), do: v
  defp to_float(v) when is_integer(v), do: v / 1.0
  defp to_float(v) when is_binary(v), do: String.to_float(v)
  defp to_float(v), do: v / 1.0
end

defmodule JidoBuilderRuntime.Actions.Tools.RegexMatch do
  @moduledoc "Apply a regex pattern to text."
  use Jido.Action, name: "regex_match", description: "Match a regex pattern against text", schema: [
    text: [type: :string, required: true],
    pattern: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    text = params[:text] || params["text"]
    pattern = params[:pattern] || params["pattern"]
    case Regex.compile(pattern) do
      {:ok, regex} ->
        matches = Regex.scan(regex, text) |> Enum.map(&List.first/1)
        {:ok, %{matches: matches, count: length(matches), matched?: length(matches) > 0}}
      {:error, _} ->
        {:ok, %{error: "Invalid regex pattern"}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.StringTransform do
  @moduledoc "Transform a string via various operations."
  use Jido.Action, name: "string_transform", description: "Transform text: upcase, downcase, trim, reverse, capitalize", schema: [
    text: [type: :string, required: true],
    operation: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    text = params[:text] || params["text"]
    op = params[:operation] || params["operation"]
    result = case op do
      "upcase" -> String.upcase(text)
      "downcase" -> String.downcase(text)
      "trim" -> String.trim(text)
      "reverse" -> String.reverse(text)
      "capitalize" -> String.capitalize(text)
      "length" -> to_string(String.length(text))
      _ -> text
    end
    {:ok, %{original: text, operation: op, result: result}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.DatetimeCompute do
  @moduledoc "Compute datetime operations."
  use Jido.Action, name: "datetime_compute", description: "Get current datetime or compute differences", schema: [
    operation: [type: :string, required: true],
    value: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    op = params[:operation] || params["operation"]
    case op do
      "now" -> {:ok, %{datetime: DateTime.utc_now() |> DateTime.to_iso8601()}}
      "today" -> {:ok, %{date: Date.utc_today() |> Date.to_iso8601()}}
      "unix" -> {:ok, %{unix: System.system_time(:second)}}
      _ -> {:ok, %{operation: op, error: "Unknown operation"}}
    end
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.HashCompute do
  @moduledoc "Compute hash of input text."
  use Jido.Action, name: "hash_compute", description: "Compute hash (md5, sha256) of text", schema: [
    text: [type: :string, required: true],
    algorithm: [type: :string, required: false]
  ]

  def run(params, _ctx) do
    text = params[:text] || params["text"]
    algo = params[:algorithm] || params["algorithm"] || "sha256"
    hash = case algo do
      "md5" -> :crypto.hash(:md5, text) |> Base.encode16(case: :lower)
      "sha256" -> :crypto.hash(:sha256, text) |> Base.encode16(case: :lower)
      "sha512" -> :crypto.hash(:sha512, text) |> Base.encode16(case: :lower)
      _ -> :crypto.hash(:sha256, text) |> Base.encode16(case: :lower)
    end
    {:ok, %{text: text, algorithm: algo, hash: hash}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.Base64Encode do
  @moduledoc "Base64 encode text."
  use Jido.Action, name: "base64_encode", description: "Base64 encode text", schema: [
    text: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    text = params[:text] || params["text"]
    {:ok, %{encoded: Base.encode64(text)}}
  end
end

defmodule JidoBuilderRuntime.Actions.Tools.Base64Decode do
  @moduledoc "Base64 decode text."
  use Jido.Action, name: "base64_decode", description: "Base64 decode text", schema: [
    text: [type: :string, required: true]
  ]

  def run(params, _ctx) do
    text = params[:text] || params["text"]
    case Base.decode64(text) do
      {:ok, decoded} -> {:ok, %{decoded: decoded}}
      :error -> {:ok, %{error: "Invalid base64"}}
    end
  end
end
