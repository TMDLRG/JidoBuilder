defmodule JidoBuilderCodegen.Templates.Action do
  @moduledoc false

  def render(%{module: mod, name: name, description: description}) do
    """
    defmodule #{mod} do
      @moduledoc \"\"\"
      #{description}
      \"\"\"

      use Jido.Action,
        name: #{inspect(name)},
        description: #{inspect(description)}

      @impl true
      def run(params, _context) do
        {:ok, Map.put(params, :action, #{inspect(name)})}
      end
    end
    """
  end
end
