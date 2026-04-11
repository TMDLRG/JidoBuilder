defmodule JidoBuilderCodegen.BlockSchema do
  @moduledoc false

  @schemas %{
    action: [:module, :name, :description],
    agent: [:module, :name, :description],
    plugin: [:module, :name, :description],
    sensor: [:module, :name, :description],
    strategy: [:module, :name, :description]
  }

  @spec valid?(map()) :: boolean()
  def valid?(%{type: type} = block) do
    with {:ok, keys} <- Map.fetch(@schemas, type),
         true <- Enum.all?(keys, &Map.has_key?(block, &1)) do
      true
    else
      _ -> false
    end
  end

  def valid?(_), do: false
end
