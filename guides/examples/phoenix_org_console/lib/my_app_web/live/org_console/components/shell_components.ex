defmodule MyAppWeb.OrgConsole.Components.ShellComponents do
  @moduledoc """
  Shared layout and confirmation components for Org Console LiveViews.
  """

  use Phoenix.Component

  attr(:title, :string, required: true)
  attr(:subtitle, :string, required: true)
  attr(:advanced_mode, :boolean, default: false)
  attr(:loading, :boolean, default: false)
  attr(:error, :string, default: nil)
  attr(:empty, :string, default: nil)
  slot(:actions)
  slot(:inner_block, required: true)

  def page(assigns) do
    ~H"""
    <section class="space-y-4 rounded-lg border border-slate-200 p-6">
      <header class="flex items-center justify-between gap-4">
        <div>
          <h1 class="text-2xl font-semibold"><%= @title %></h1>
          <p class="text-sm text-slate-600"><%= @subtitle %></p>
        </div>

        <div class="flex items-center gap-3">
          <span class="text-xs text-slate-500">Advanced Jido terms</span>
          <button
            type="button"
            class="rounded border px-2 py-1 text-xs"
            phx-click="toggle_advanced"
            aria-pressed={to_string(@advanced_mode)}
          >
            <%= if @advanced_mode, do: "On", else: "Off" %>
          </button>
        </div>
      </header>

      <div :if={@loading} class="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-700">
        Loading data…
      </div>

      <div :if={@error} class="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
        <strong>Could not load this screen.</strong>
        <p><%= @error %></p>
      </div>

      <div :if={@empty} class="rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
        <%= @empty %>
      </div>

      <div class="flex flex-wrap gap-2">
        <%= render_slot(@actions) %>
      </div>

      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  attr(:confirming, :map, default: nil)

  def confirm_dialog(assigns) do
    ~H"""
    <div :if={@confirming} class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-md rounded-lg bg-white p-5 shadow-lg">
        <h2 class="text-lg font-semibold"><%= @confirming.title %></h2>
        <p class="mt-2 text-sm text-slate-600"><%= @confirming.message %></p>

        <div class="mt-4 flex justify-end gap-2">
          <button type="button" class="rounded border px-3 py-1.5" phx-click="cancel_confirm">
            Keep as-is
          </button>
          <button
            type="button"
            class="rounded bg-red-600 px-3 py-1.5 text-white"
            phx-click="confirm_action"
          >
            Confirm
          </button>
        </div>
      </div>
    </div>
    """
  end
end
