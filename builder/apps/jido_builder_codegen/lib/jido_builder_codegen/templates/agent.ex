defmodule JidoBuilderCodegen.Templates.Agent do
  @moduledoc false

  def render(%{module: mod, description: description}) do
    """
    defmodule #{mod} do
      @moduledoc \"\"\"
      #{description}
      \"\"\"

      use Jido.Agent,
        name: :generated_agent,
        description: #{inspect(description)}
    end
    """
  end
end
