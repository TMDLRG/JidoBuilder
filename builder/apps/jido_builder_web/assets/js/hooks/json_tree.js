const JsonTree = {
  mounted() {
    this.renderTree()
  },
  updated() {
    this.renderTree()
  },
  renderTree() {
    const data = this.el.dataset.json || "{}"
    let parsed = {}
    try { parsed = JSON.parse(data) } catch (_) { parsed = { error: "invalid json" } }
    this.el.innerHTML = `<pre class="text-xs bg-zinc-950 text-zinc-100 p-3 rounded overflow-auto">${this.format(parsed)}</pre>`
  },
  format(value, depth = 0) {
    if (value === null) return `<span class='text-zinc-400'>null</span>`
    if (typeof value === "string") return `<span class='text-emerald-400'>"${value}"</span>`
    if (typeof value === "number") return `<span class='text-blue-400'>${value}</span>`
    if (typeof value === "boolean") return `<span class='text-purple-400'>${value}</span>`
    if (Array.isArray(value)) return `[${value.map(v => this.format(v, depth + 1)).join(", ")}]`
    if (typeof value === "object") {
      return `{${Object.entries(value).map(([k, v]) => `<div style='padding-left:${(depth + 1) * 12}px'><span class='text-zinc-300'>${k}</span>: ${this.format(v, depth + 1)}</div>`).join("")}}`
    }
    return String(value)
  }
}

export default JsonTree
