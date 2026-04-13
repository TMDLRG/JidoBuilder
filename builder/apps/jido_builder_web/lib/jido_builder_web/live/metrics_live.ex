defmodule JidoBuilderWeb.MetricsLive do
  use JidoBuilderWeb, :live_view

  alias JidoBuilderCore.Metrics

  @impl true
  def mount(_params, _session, socket) do
    workspace_id = 1

    signals = Metrics.signals_per_hour(workspace_id)
    errors = Metrics.errors_per_hour(workspace_id)

    total_signals = Enum.reduce(signals, 0, fn %{count: c}, acc -> acc + c end)
    total_errors = Enum.reduce(errors, 0, fn %{count: c}, acc -> acc + c end)

    {:ok,
     assign(socket,
       page_title: "Metrics Dashboard",
       signals_data: Jason.encode!(signals),
       errors_data: Jason.encode!(errors),
       total_signals: total_signals,
       total_errors: total_errors
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_header>Metrics Dashboard</.page_header>

    <section class="grid md:grid-cols-2 gap-4 mb-6">
      <.stat_card label="Signals (24h)" value={to_string(@total_signals)} icon="signal" />
      <.stat_card label="Errors (24h)" value={to_string(@total_errors)} icon="exclamation_triangle" variant={if @total_errors > 0, do: "destructive", else: "neutral"} />
    </section>

    <section class="grid md:grid-cols-2 gap-6">
      <.card>
        <:header>Signals per Hour</:header>
        <div id="signals-chart" phx-hook="TimeSeriesChart" data-chart={@signals_data} data-label="Signals" data-color="#10b981" class="w-full" style="min-height:200px;">
          <noscript>Enable JavaScript to view charts.</noscript>
        </div>
      </.card>

      <.card>
        <:header>Errors per Hour</:header>
        <div id="errors-chart" phx-hook="TimeSeriesChart" data-chart={@errors_data} data-label="Errors" data-color="#ef4444" class="w-full" style="min-height:200px;">
          <noscript>Enable JavaScript to view charts.</noscript>
        </div>
      </.card>
    </section>
    """
  end
end
