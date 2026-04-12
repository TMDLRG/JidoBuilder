defmodule JidoBuilderCodegen.Templates.Strategy do
  @moduledoc false

  def render(%{module: mod, description: description}) do
    """
    defmodule #{mod} do
      @moduledoc #{inspect(description)}

      @behaviour Jido.Agent.Server.Strategy

      @impl true
      def apply(ops, state), do: {:ok, ops, state}
    end
    """
  end
end
