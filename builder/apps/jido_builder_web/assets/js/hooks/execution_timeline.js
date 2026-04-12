const ExecutionTimeline = {
  mounted() { this.render() },
  updated() { this.render() },
  render() {
    let events = []
    try { events = JSON.parse(this.el.dataset.events || "[]") } catch (_) {}
    this.el.innerHTML = `<div class='flex gap-2 overflow-x-auto'>${events.map((e, i) => `<button data-id='${i}' class='px-2 py-1 rounded text-xs ${this.color(e)}'>${e.kind || "event"}</button>`).join("")}</div>`
  },
  color(e) {
    if (e.status === "exception") return "bg-red-100 text-red-700"
    if (e.kind === "signal") return "bg-blue-100 text-blue-700"
    return "bg-emerald-100 text-emerald-700"
  }
}

export default ExecutionTimeline
