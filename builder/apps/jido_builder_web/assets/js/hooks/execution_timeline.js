const EVENT_COLORS = {
  cmd: "#10b981",
  signal: "#3b82f6",
  directive: "#f59e0b",
  error: "#ef4444"
}
const RADIUS = 8
const SVG_HEIGHT = 120
const AXIS_Y = 90
const EVENT_Y = 56

const ExecutionTimeline = {
  mounted() {
    this._events = []
    this._selected = null
    this._tooltip = null

    this.handleEvent("append_event", (event) => {
      this._events.push(event)
      this.render()
    })

    this.render()
  },
  updated() {
    try {
      this._events = JSON.parse(this.el.dataset.events || "[]")
    } catch (_) {}
    this.render()
  },
  render() {
    try {
      if (!this._events.length) {
        const eventsAttr = JSON.parse(this.el.dataset.events || "[]")
        if (eventsAttr.length) this._events = eventsAttr
      }
    } catch (_) {}

    const events = this._events
    const width = this.el.clientWidth || 800
    const spacing = Math.max(60, Math.min(120, (width - 60) / Math.max(events.length, 1)))

    const svgW = Math.max(width, events.length * spacing + 60)

    const ns = "http://www.w3.org/2000/svg"
    const svg = document.createElementNS(ns, "svg")
    svg.setAttribute("width", svgW)
    svg.setAttribute("height", SVG_HEIGHT)
    svg.style.display = "block"

    // Horizontal axis line
    const line = document.createElementNS(ns, "line")
    line.setAttribute("x1", "20")
    line.setAttribute("y1", AXIS_Y)
    line.setAttribute("x2", svgW - 20)
    line.setAttribute("y2", AXIS_Y)
    line.setAttribute("stroke", "#d4d4d8")
    line.setAttribute("stroke-width", "2")
    svg.appendChild(line)

    events.forEach((event, i) => {
      const cx = 30 + i * spacing
      const kind = event.kind || "cmd"
      const color = EVENT_COLORS[kind] || EVENT_COLORS.cmd

      // Tick mark
      const tick = document.createElementNS(ns, "line")
      tick.setAttribute("x1", cx)
      tick.setAttribute("y1", AXIS_Y - 6)
      tick.setAttribute("x2", cx)
      tick.setAttribute("y2", AXIS_Y + 6)
      tick.setAttribute("stroke", "#a1a1aa")
      tick.setAttribute("stroke-width", "1")
      svg.appendChild(tick)

      // Event circle
      const circle = document.createElementNS(ns, "circle")
      circle.setAttribute("cx", cx)
      circle.setAttribute("cy", EVENT_Y)
      circle.setAttribute("r", RADIUS)
      circle.setAttribute("fill", color)
      circle.setAttribute("stroke", this._selected === i ? "#111827" : "none")
      circle.setAttribute("stroke-width", "2")
      circle.style.cursor = "pointer"

      // Hover tooltip
      const tooltip = document.createElementNS(ns, "title")
      tooltip.textContent = `${kind}: ${event.id || event.signal_type || JSON.stringify(event)}`
      circle.appendChild(tooltip)

      circle.addEventListener("click", () => {
        this._selected = i
        this.pushEvent("select_event", { id: event.id || String(i) })
        this.render()
      })

      svg.appendChild(circle)

      // Label below axis
      const label = document.createElementNS(ns, "text")
      label.setAttribute("x", cx)
      label.setAttribute("y", AXIS_Y + 20)
      label.setAttribute("text-anchor", "middle")
      label.setAttribute("font-size", "9")
      label.setAttribute("fill", "#a1a1aa")
      label.textContent = kind
      svg.appendChild(label)
    })

    const container = this.el
    container.style.overflowX = "auto"
    container.innerHTML = ""

    if (events.length === 0) {
      container.innerHTML = `<p class="text-xs text-zinc-400 pt-4">No events yet</p>`
      return
    }

    container.appendChild(svg)

    // Auto-scroll right on new events
    container.scrollLeft = container.scrollWidth
  }
}

export default ExecutionTimeline
