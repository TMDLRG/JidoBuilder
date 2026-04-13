/**
 * TimeSeriesChart hook — renders an inline SVG bar chart from
 * JSON data stored in data-chart attribute.
 *
 * Expected data shape: [{ hour: "2025-01-01 14:00", count: 5 }, ...]
 * Attributes:
 *   data-chart  — JSON array of {hour, count}
 *   data-label  — chart title / legend label
 *   data-color  — bar fill colour (hex)
 */
const TimeSeriesChart = {
  mounted() {
    this.render()
  },

  updated() {
    this.render()
  },

  render() {
    const raw = this.el.getAttribute("data-chart")
    const label = this.el.getAttribute("data-label") || "Value"
    const color = this.el.getAttribute("data-color") || "#10b981"

    let data = []
    try { data = JSON.parse(raw) } catch (_) { /* noop */ }

    if (!data || data.length === 0) {
      this.el.innerHTML =
        '<div class="flex flex-col items-center justify-center py-8 text-zinc-400 text-sm">' +
        '<svg class="h-8 w-8 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">' +
        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>' +
        '</svg>' +
        'No data for this period' +
        '</div>'
      return
    }

    const maxCount = Math.max(...data.map(d => d.count), 1)
    const svgWidth = 600
    const svgHeight = 200
    const padding = { top: 20, right: 10, bottom: 40, left: 40 }
    const chartW = svgWidth - padding.left - padding.right
    const chartH = svgHeight - padding.top - padding.bottom
    const barGap = 2
    const barWidth = Math.max(2, (chartW / data.length) - barGap)

    // Y-axis ticks
    const yTicks = 4
    let yLines = ""
    for (let i = 0; i <= yTicks; i++) {
      const y = padding.top + chartH - (chartH / yTicks) * i
      const val = Math.round((maxCount / yTicks) * i)
      yLines += `<line x1="${padding.left}" y1="${y}" x2="${svgWidth - padding.right}" y2="${y}" stroke="#e4e4e7" stroke-width="1"/>`
      yLines += `<text x="${padding.left - 6}" y="${y + 4}" text-anchor="end" fill="#a1a1aa" font-size="10">${val}</text>`
    }

    // Bars
    let bars = ""
    data.forEach((d, i) => {
      const x = padding.left + i * (barWidth + barGap)
      const h = (d.count / maxCount) * chartH
      const y = padding.top + chartH - h
      bars += `<rect x="${x}" y="${y}" width="${barWidth}" height="${h}" fill="${color}" rx="1" opacity="0.85">`
      bars += `<title>${d.hour}: ${d.count} ${label.toLowerCase()}</title>`
      bars += `</rect>`
    })

    // X-axis labels (show ~6 evenly spaced)
    const labelCount = Math.min(6, data.length)
    const step = Math.max(1, Math.floor(data.length / labelCount))
    let xLabels = ""
    for (let i = 0; i < data.length; i += step) {
      const x = padding.left + i * (barWidth + barGap) + barWidth / 2
      const y = svgHeight - 6
      const hourStr = data[i].hour.slice(11, 16) || data[i].hour.slice(-5)
      xLabels += `<text x="${x}" y="${y}" text-anchor="middle" fill="#a1a1aa" font-size="10">${hourStr}</text>`
    }

    this.el.innerHTML =
      `<svg viewBox="0 0 ${svgWidth} ${svgHeight}" class="w-full" preserveAspectRatio="xMidYMid meet">` +
      yLines + bars + xLabels +
      `</svg>`
  }
}

export default TimeSeriesChart
