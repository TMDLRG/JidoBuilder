defmodule JidoBuilderRuntime.PluginManifest do
  @moduledoc """
  Validates plugin JSON manifests.

  Required fields: name, version (semver), description, entry_module.
  Optional: actions (list of action slugs), sensors, config_schema.
  """

  @required_fields ~w(name version description entry_module)

  @doc "Validate a plugin manifest map. Returns {:ok, parsed} or {:error, reason}."
  def validate(manifest) when is_map(manifest) do
    with :ok <- check_required(manifest),
         :ok <- check_version(manifest["version"]) do
      {:ok,
       %{
         name: manifest["name"],
         version: manifest["version"],
         description: manifest["description"],
         entry_module: manifest["entry_module"],
         actions: manifest["actions"] || [],
         sensors: manifest["sensors"] || [],
         config_schema: manifest["config_schema"] || %{}
       }}
    end
  end

  def validate(_), do: {:error, "Manifest must be a map"}

  defp check_required(manifest) do
    missing =
      Enum.filter(@required_fields, fn field ->
        is_nil(manifest[field]) || manifest[field] == ""
      end)

    case missing do
      [] -> :ok
      fields -> {:error, "Missing required fields: #{Enum.join(fields, ", ")}"}
    end
  end

  defp check_version(version) when is_binary(version) do
    if Regex.match?(~r/^\d+\.\d+\.\d+/, version) do
      :ok
    else
      {:error, "Version must follow semver format (e.g., 1.0.0)"}
    end
  end

  defp check_version(_), do: {:error, "Version is required and must be a string"}
end
