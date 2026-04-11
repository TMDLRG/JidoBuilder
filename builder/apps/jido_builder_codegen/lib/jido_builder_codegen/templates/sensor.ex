defmodule JidoBuilderCodegen.Templates.Sensor do
  @moduledoc false

  def render(%{module: mod, description: description}) do
    """
    defmodule #{mod} do
      @moduledoc \"\"\"
      #{description}
      \"\"\"

      @behaviour Jido.Sensor

      @impl true
      def mount(opts), do: {:ok, opts}
    end
    """
  end
end
