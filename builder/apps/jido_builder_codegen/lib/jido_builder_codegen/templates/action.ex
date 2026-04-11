defmodule JidoBuilderCodegen.Templates.Action do
  @moduledoc false

  def render(%{module: mod, name: name, description: description}) do
    """
    defmodule #{mod} do
      @moduledoc \"\"\"
      #{description}
      \"\"\"

      @behaviour Jido.Action

      @impl true
      def run(params, _context) do
        {:ok, Map.put(params, :action, #{inspect(name)})}
      end
    end
    """
  end
end
