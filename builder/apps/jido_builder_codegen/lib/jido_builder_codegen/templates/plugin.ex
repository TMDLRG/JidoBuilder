defmodule JidoBuilderCodegen.Templates.Plugin do
  @moduledoc false

  def render(%{module: mod, description: description}) do
    """
    defmodule #{mod} do
      @moduledoc #{inspect(description)}

      @behaviour Jido.Agent.Plugin

      @impl true
      def mount(agent, _opts), do: {:ok, agent}
    end
    """
  end
end
