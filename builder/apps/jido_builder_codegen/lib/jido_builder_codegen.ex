defmodule JidoBuilderCodegen do
  @moduledoc false

  alias JidoBuilderCodegen.CompileQueue

  @spec compile(map()) :: {:ok, map()} | {:error, map()}
  def compile(request), do: CompileQueue.enqueue(request)
end
