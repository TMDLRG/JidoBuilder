defmodule JidoBuilderCodegen.Compiler do
  @moduledoc false

  @spec compile([String.t()]) :: {:ok, map()} | {:error, map()}
  def compile([file]) do
    Code.compile_file(file)
    |> then(fn modules -> {:ok, %{modules: Enum.map(modules, &elem(&1, 0)), warnings: []}} end)
  rescue
    error -> {:error, %{errors: [Exception.message(error)], warnings: []}}
  end

  def compile(files) when is_list(files) do
    case Kernel.ParallelCompiler.compile(files) do
      {:ok, modules, warnings} ->
        {:ok, %{modules: modules, warnings: Enum.map(warnings, &inspect/1)}}

      {:error, errors, warnings} ->
        {:error,
         %{errors: Enum.map(errors, &inspect/1), warnings: Enum.map(warnings, &inspect/1)}}
    end
  end
end
