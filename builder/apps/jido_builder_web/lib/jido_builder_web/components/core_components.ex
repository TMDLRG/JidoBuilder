defmodule JidoBuilderWeb.CoreComponents do
  use Phoenix.Component

  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  def page_header(assigns) do
    ~H"""
    <header class={["mb-6 border-b pb-4", @class]}>
      <h1 class="text-2xl font-semibold text-zinc-900"><%= render_slot(@inner_block) %></h1>
    </header>
    """
  end
end
