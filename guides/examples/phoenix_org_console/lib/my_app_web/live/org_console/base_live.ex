defmodule MyAppWeb.OrgConsole.BaseLive do
  @moduledoc false

  import Phoenix.Component
  import Phoenix.LiveView

  alias MyAppWeb.OrgConsole.Components.ShellComponents

  def init(socket, attrs) do
    socket
    |> assign(:advanced_mode, false)
    |> assign(:loading, false)
    |> assign(:error, nil)
    |> assign(:confirming, nil)
    |> assign(:flash_notice, nil)
    |> assign(attrs)
  end

  def toggle_advanced(socket) do
    update(socket, :advanced_mode, &(!&1))
  end

  def open_confirm(socket, action, title, message) do
    assign(socket, :confirming, %{action: action, title: title, message: message})
  end

  def close_confirm(socket), do: assign(socket, :confirming, nil)

  def render_shell(assigns, do: block) do
    assigns = assign(assigns, :inner_block, block)

    ~H"""
    <ShellComponents.page
      title={@title}
      subtitle={@subtitle}
      loading={@loading}
      error={@error}
      empty={@empty}
      advanced_mode={@advanced_mode}
    >
      <:actions>
        <%= render_slot(@actions) %>
      </:actions>
      <%= render_slot(@inner_block) %>
      <p :if={@flash_notice} class="text-sm text-emerald-700"><%= @flash_notice %></p>
    </ShellComponents.page>

    <ShellComponents.confirm_dialog confirming={@confirming} />
    """
  end
end
