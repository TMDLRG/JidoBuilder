defmodule JidoBuilderWeb.Icons do
  @moduledoc "Inline SVG icon component set for Builder UI."
  use Phoenix.Component

  attr :name, :string, required: true
  attr :class, :string, default: "h-4 w-4"

  def icon(assigns) do
    ~H"""
    <span class={@class}>
      <%= case @name do %>
        <% "home" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M10 2 2 8v10h5v-6h6v6h5V8z"/></svg>
        <% "users" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M7 10a3 3 0 1 1 0-6 3 3 0 0 1 0 6zm6 1a3 3 0 1 0-2.1-.9A4.8 4.8 0 0 1 17 15v1h-4v-1c0-1.5-.7-2.8-1.8-3.7A5 5 0 0 1 13 11zm-6 1c3.3 0 6 1.8 6 4v1H1v-1c0-2.2 2.7-4 6-4z"/></svg>
        <% "play" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M6 4v12l10-6z"/></svg>
        <% "cog" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M11 2h-2l-.5 2a6.8 6.8 0 0 0-1.5.6L5.2 3.4 3.8 4.8l1.2 1.8a6.8 6.8 0 0 0-.6 1.5L2 8.6v2l2 .5c.1.5.3 1 .6 1.5l-1.2 1.8 1.4 1.4 1.8-1.2c.5.3 1 .5 1.5.6l.5 2h2l.5-2a6.8 6.8 0 0 0 1.5-.6l1.8 1.2 1.4-1.4-1.2-1.8c.3-.5.5-1 .6-1.5l2-.5v-2l-2-.5a6.8 6.8 0 0 0-.6-1.5l1.2-1.8-1.4-1.4-1.8 1.2a6.8 6.8 0 0 0-1.5-.6zM10 13a3 3 0 1 1 0-6 3 3 0 0 1 0 6z"/></svg>
        <% "bolt" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M11 1 4 11h5l-1 8 8-11h-5z"/></svg>
        <% "clock" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M10 2a8 8 0 1 0 0 16 8 8 0 0 0 0-16zm1 4H9v5l4 2 1-1.7-3-1.3z"/></svg>
        <% "folder" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M2 5h6l2 2h8v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2z"/></svg>
        <% "bug" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M12 4V2H8v2H6v2h8V4zM5 9h10v2H5zm2 3h6v5H7z"/></svg>
        <% "search" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="m13 12 5 5-1 1-5-5v-1l-.3-.3A5 5 0 1 1 13 12zM5 9a4 4 0 1 0 8 0 4 4 0 0 0-8 0z"/></svg>
        <% "chart_bar" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M3 17h14v1H2V2h1zM6 9h2v7H6zm4-4h2v11h-2zm4 2h2v9h-2z"/></svg>
        <% "eye" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M10 5c4.7 0 8 5 8 5s-3.3 5-8 5-8-5-8-5 3.3-5 8-5zm0 2.5A2.5 2.5 0 1 0 10 12.5 2.5 2.5 0 0 0 10 7.5z"/></svg>
        <% "plus" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M9 4h2v5h5v2h-5v5H9v-5H4V9h5z"/></svg>
        <% "x" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="m5 5 10 10m0-10L5 15" stroke="currentColor" stroke-width="2"/></svg>
        <% "chevron_left" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="m12 5-5 5 5 5"/></svg>
        <% "chevron_right" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="m8 5 5 5-5 5"/></svg>
        <% "exclamation_triangle" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M10 2 2 17h16L10 2zm1 12H9v2h2zm0-6H9v4h2z"/></svg>
        <% "check_circle" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M10 2a8 8 0 1 0 0 16 8 8 0 0 0 0-16zm-1 11L5 9l1.4-1.4L9 10.2l4.6-4.6L15 7z"/></svg>
        <% "arrow_path" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M10 3a7 7 0 0 1 6.9 6H19l-3 3-3-3h1.9A5 5 0 1 0 15 12h2a7 7 0 1 1-7-9z"/></svg>
        <% "beaker" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M7 2h6v2l-1 2v2l4 7v3H4v-3l4-7V6L7 4z"/></svg>
        <% "cube" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="m10 2 7 4v8l-7 4-7-4V6z"/></svg>
        <% "puzzle_piece" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M3 3h6v3a2 2 0 1 1 2 2h3v9H3z"/></svg>
        <% "signal" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M2 16h2V9H2zm4 0h2V6H6zm4 0h2V3h-2zm4 0h2v-7h-2z"/></svg>
        <% "cpu_chip" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M7 7h6v6H7zM3 8h2V6h2V4H5V2H3v2H1v2h2zm14 0h2V6h-2V4h-2V2h-2v2h2v2h2zM3 12H1v2h2v2h2v2h2v-2H5v-2H3zm16 0h-2v2h-2v2h-2v2h2v-2h2v-2h2z"/></svg>
        <% "command_line" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M2 4h16v12H2zm3 3 3 3-3 3-1-1 2-2-2-2zm5 6h5v-1h-5z"/></svg>
        <% "trash" -> %><svg viewBox="0 0 20 20" fill="currentColor"><path d="M6 6h8l-1 11H7zm2-3h4l1 2H7zM4 5h12v1H4z"/></svg>
        <% _ -> %><svg viewBox="0 0 20 20" fill="currentColor"><circle cx="10" cy="10" r="8"/></svg>
      <% end %>
    </span>
    """
  end
end
