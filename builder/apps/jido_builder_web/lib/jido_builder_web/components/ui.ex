defmodule JidoBuilderWeb.UI do
  @moduledoc "Builder UI design-system components."
  use Phoenix.Component
  import JidoBuilderWeb.Icons

  # -- Button --
  attr :variant, :string, default: "primary"
  attr :size, :string, default: "md"
  attr :class, :string, default: ""
  attr :disabled, :boolean, default: false
  attr :rest, :global, include: ~w(phx-click phx-value-id type)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button class={["ui-btn", @variant, @size, @class]} disabled={@disabled} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  # -- Card --
  attr :class, :string, default: ""
  slot :header
  slot :inner_block, required: true
  slot :footer

  def card(assigns) do
    ~H"""
    <section class={["ui-card", @class]}>
      <header :if={@header != []} class="ui-card-header">
        {render_slot(@header)}
      </header>
      <div class="ui-card-body">
        {render_slot(@inner_block)}
      </div>
      <footer :if={@footer != []} class="ui-card-footer">
        {render_slot(@footer)}
      </footer>
    </section>
    """
  end

  # -- Modal --
  attr :show, :boolean, default: false
  attr :id, :string, required: true
  slot :inner_block

  def modal(assigns) do
    ~H"""
    <div :if={@show} id={@id} class="ui-modal">
      <div class="ui-card max-w-md w-full">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  # -- Badge --
  attr :variant, :string, default: "neutral"
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={["ui-badge", @variant]}>{render_slot(@inner_block)}</span>
    """
  end

  # -- Input Field --
  attr :name, :string, default: nil
  attr :label, :string, default: nil
  attr :value, :string, default: nil
  attr :type, :string, default: "text"
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :class, :string, default: ""

  def input_field(assigns) do
    ~H"""
    <label class="ui-label block text-sm">
      <span :if={@label} class="block text-xs font-medium text-zinc-600 mb-1">{@label}</span>
      <input type={@type} name={@name} value={@value} placeholder={@placeholder} required={@required} class={["ui-input", @class]} />
    </label>
    """
  end

  # -- Table --
  attr :id, :string, required: true
  attr :rows, :list, default: []
  slot :col, required: true

  def table(assigns) do
    ~H"""
    <table id={@id} class="ui-table w-full text-sm">
      <tbody>
        <tr :for={row <- @rows} class="border-b last:border-0">
          <td :for={col <- @col} class="py-2 px-3">{render_slot(col, row)}</td>
        </tr>
      </tbody>
    </table>
    """
  end

  # -- Alert --
  attr :variant, :string, default: "info"
  slot :inner_block, required: true

  def alert(assigns) do
    ~H"""
    <div class={["ui-alert", @variant, "rounded-lg p-3 text-sm"]}>{render_slot(@inner_block)}</div>
    """
  end

  # -- Stat Card --
  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: "signal"
  attr :variant, :string, default: "neutral"

  def stat_card(assigns) do
    ~H"""
    <div class={["ui-card p-4", @variant]}>
      <div class="flex items-center gap-2 text-zinc-500 text-xs uppercase tracking-wide mb-1">
        <.icon name={@icon} class="h-4 w-4" />
        {@label}
      </div>
      <div class="text-2xl font-semibold text-zinc-900">{@value}</div>
    </div>
    """
  end

  # -- Page Header --
  slot :inner_block, required: true
  slot :actions

  def page_header(assigns) do
    ~H"""
    <header class="ui-page-header flex items-center justify-between mb-6 pb-4 border-b">
      <h1 class="text-2xl font-semibold text-zinc-900">{render_slot(@inner_block)}</h1>
      <div :if={@actions != []} class="flex items-center gap-2">
        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  # -- Breadcrumb --
  attr :items, :list, default: []

  def breadcrumb(assigns) do
    ~H"""
    <nav class="text-xs text-zinc-500 mb-4 flex items-center gap-1">
      <span :for={item <- @items}>{item}</span>
    </nav>
    """
  end

  # -- Empty State --
  attr :title, :string, required: true
  attr :description, :string, default: ""
  attr :icon, :string, default: "folder"

  def empty_state(assigns) do
    ~H"""
    <div class="ui-empty flex flex-col items-center py-12 text-zinc-400">
      <.icon name={@icon} class="h-10 w-10 mb-3" />
      <h3 class="text-base font-medium text-zinc-600">{@title}</h3>
      <p :if={@description != ""} class="text-sm mt-1">{@description}</p>
    </div>
    """
  end

  # -- Tabs --
  attr :active_tab, :string, default: ""
  attr :items, :list, default: []

  def tabs(assigns) do
    ~H"""
    <nav class="flex gap-1 border-b mb-6">
      <button
        :for={item <- @items}
        class={["px-4 py-2 text-sm font-medium border-b-2 -mb-px", if(item == @active_tab, do: "border-emerald-500 text-zinc-900", else: "border-transparent text-zinc-500 hover:text-zinc-700")]}
      >
        {item}
      </button>
    </nav>
    """
  end

  # -- Toast --
  attr :variant, :string, default: "info"
  attr :title, :string, default: ""
  attr :message, :string, default: ""

  def toast(assigns) do
    ~H"""
    <aside class={["ui-toast fixed top-4 right-4 z-50 ui-card p-3 min-w-[280px]", @variant]}>
      <strong class="text-sm">{@title}</strong>
      <p class="text-xs text-zinc-600">{@message}</p>
    </aside>
    """
  end

  # -- Spinner --
  attr :size, :string, default: "md"

  def spinner(assigns) do
    ~H"""
    <div class={["animate-spin rounded-full border-2 border-zinc-200 border-t-emerald-500", size_class(@size)]}></div>
    """
  end

  defp size_class("sm"), do: "h-4 w-4"
  defp size_class("md"), do: "h-6 w-6"
  defp size_class("lg"), do: "h-8 w-8"
  defp size_class(_), do: "h-6 w-6"

  # -- Skeleton --
  attr :variant, :string, default: "line"

  def skeleton(assigns) do
    ~H"""
    <div class={["animate-pulse bg-zinc-200 rounded", skeleton_class(@variant)]}></div>
    """
  end

  defp skeleton_class("line"), do: "h-4 w-full"
  defp skeleton_class("card"), do: "h-24 w-full"
  defp skeleton_class("circle"), do: "h-10 w-10 rounded-full"
  defp skeleton_class(_), do: "h-4 w-full"
end
