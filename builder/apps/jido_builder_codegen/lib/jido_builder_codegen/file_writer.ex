defmodule JidoBuilderCodegen.FileWriter do
  @moduledoc false

  @default_root Path.expand("../../jido_builder_generated/lib", __DIR__)

  @spec write(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def write(relative_path, content) do
    with {:ok, path} <- resolve_path(relative_path) do
      previous = if File.exists?(path), do: File.read!(path), else: nil
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, content)
      {:ok, %{path: path, previous: previous}}
    end
  end

  @spec restore(String.t(), nil | String.t()) :: :ok | {:error, term()}
  def restore(path, nil), do: File.rm(path)
  def restore(path, previous), do: File.write(path, previous)

  defp resolve_path(relative_path) do
    configured_root =
      Application.get_env(:jido_builder_codegen, :generated_lib_dir, @default_root)

    root = Path.expand(configured_root)
    expanded = Path.expand(relative_path, root)

    if String.starts_with?(expanded, root <> "/") or expanded == root do
      {:ok, expanded}
    else
      {:error, :path_outside_generated_lib}
    end
  end
end
