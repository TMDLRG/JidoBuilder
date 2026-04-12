defmodule JidoBuilderWeb.UI do
  @moduledoc "Builder UI design-system components."
  use Phoenix.Component
  import JidoBuilderWeb.Icons

  attr :variant, :string, default: "primary"
  attr :size, :string, default: "md"
  attr :class, :string, default: ""
  attr :disabled, :boolean, default: false
  slot :inner_block, required: true
  def button(assigns), do: ~H"<button class={"ui-btn " <> @variant <> " " <> @size <> " " <> @class} disabled={@disabled}>{render_slot(@inner_block)}</button>"

  attr :class, :string, default: ""
  slot :header
  slot :inner_block, required: true
  slot :footer
  def card(assigns), do: ~H"<section class={"ui-card " <> @class}><header :if={@header!=[]} class="ui-card-header">{render_slot(@header)}</header><div class="ui-card-body">{render_slot(@inner_block)}</div><footer :if={@footer!=[]} class="ui-card-footer">{render_slot(@footer)}</footer></section>"

  attr :show, :boolean, default: false
  attr :id, :string, required: true
  slot :inner_block
  def modal(assigns), do: ~H"<div :if={@show} id={@id} class="ui-modal">{render_slot(@inner_block)}</div>"

  attr :variant, :string, default: "neutral"
  slot :inner_block, required: true
  def badge(assigns), do: ~H"<span class={"ui-badge " <> @variant}>{render_slot(@inner_block)}</span>"

  attr :name, :string, default: nil
  attr :label, :string, default: nil
  attr :value, :string, default: nil
  attr :type, :string, default: "text"
  def input_field(assigns), do: ~H"<label class="ui-label">{@label}<input type={@type} name={@name} value={@value} class="ui-input" /></label>"

  attr :id, :string, required: true
  attr :rows, :list, default: []
  slot :col, required: true
  def table(assigns), do: ~H"<table id={@id} class="ui-table"><tbody><tr :for={row <- @rows}><td :for={col <- @col}>{render_slot(col, row)}</td></tr></tbody></table>"

  attr :variant, :string, default: "info"
  slot :inner_block, required: true
  def alert(assigns), do: ~H"<div class={"ui-alert " <> @variant}>{render_slot(@inner_block)}</div>"

  attr :label, :string, required: true
  attr :value, :string, required: true
  attr :icon, :string, default: "signal"
  def stat_card(assigns), do: ~H"<div class="ui-stat"><.icon name={@icon} class="h-4 w-4" /><p>{@label}</p><p>{@value}</p></div>"

  attr :title, :string, default: nil
  slot :inner_block, required: true
  slot :actions
  def page_header(assigns), do: ~H"<header class="ui-page-header"><div>{render_slot(@inner_block)}</div><div>{render_slot(@actions)}</div></header>"

  attr :items, :list, default: []
  def breadcrumb(assigns), do: ~H"<nav class="ui-breadcrumb"><span :for={item <- @items}>{item}</span></nav>"

  attr :title, :string, required: true
  attr :description, :string, default: ""
  attr :icon, :string, default: "folder"
  def empty_state(assigns), do: ~H"<div class="ui-empty"><.icon name={@icon} class="h-6 w-6" /><h3>{@title}</h3><p>{@description}</p></div>"

  attr :active_tab, :string, default: ""
  attr :items, :list, default: []
  def tabs(assigns), do: ~H"<nav class="ui-tabs"><button :for={item <- @items} class={if item == @active_tab, do: "active", else: ""}>{item}</button></nav>"

  attr :variant, :string, default: "info"
  attr :title, :string, default: ""
  attr :message, :string, default: ""
  def toast(assigns), do: ~H"<aside class={"ui-toast " <> @variant}><strong>{@title}</strong><p>{@message}</p></aside>"

  attr :size, :string, default: "md"
  def spinner(assigns), do: ~H"<div class={"ui-spinner " <> @size}></div>"

  attr :variant, :string, default: "line"
  def skeleton(assigns), do: ~H"<div class={"ui-skeleton " <> @variant}></div>"
end
