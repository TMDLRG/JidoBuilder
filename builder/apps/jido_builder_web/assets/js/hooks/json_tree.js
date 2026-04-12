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

    const controls = document.createElement("div")
    controls.className = "flex gap-2 mb-2"
    controls.innerHTML = `
      <button class="text-xs px-2 py-1 rounded bg-zinc-200 hover:bg-zinc-300" data-action="expand-all">Expand All</button>
      <button class="text-xs px-2 py-1 rounded bg-zinc-200 hover:bg-zinc-300" data-action="collapse-all">Collapse All</button>
    `

    const tree = document.createElement("div")
    tree.className = "text-xs font-mono bg-zinc-950 text-zinc-100 p-3 rounded overflow-auto"
    tree.innerHTML = this.buildTree(parsed, 0)

    this.el.innerHTML = ""
    this.el.appendChild(controls)
    this.el.appendChild(tree)

    controls.querySelector("[data-action=expand-all]").addEventListener("click", () => {
      tree.querySelectorAll("details").forEach(d => d.open = true)
    })
    controls.querySelector("[data-action=collapse-all]").addEventListener("click", () => {
      tree.querySelectorAll("details").forEach(d => d.open = false)
    })
  },
  buildTree(value, depth) {
    if (value === null) return `<span style="color:#a1a1aa">null</span>`
    if (typeof value === "string") return `<span style="color:#16a34a">"${this.escape(value)}"</span>`
    if (typeof value === "number") return `<span style="color:#2563eb">${value}</span>`
    if (typeof value === "boolean") return `<span style="color:#7c3aed">${value}</span>`
    if (Array.isArray(value)) {
      if (value.length === 0) return `<span style="color:#a1a1aa">[]</span>`
      const items = value.map((v, i) =>
        `<div style="padding-left:${(depth + 1) * 14}px">${i}: ${this.buildTree(v, depth + 1)}</div>`
      ).join("")
      return `<details open><summary style="cursor:pointer;color:#e4e4e7">Array [${value.length}]</summary>${items}</details>`
    }
    if (typeof value === "object") {
      const keys = Object.keys(value)
      if (keys.length === 0) return `<span style="color:#a1a1aa">{}</span>`
      const items = keys.map(k =>
        `<div style="padding-left:${(depth + 1) * 14}px"><span style="color:#d4d4d8">${this.escape(k)}</span>: ${this.buildTree(value[k], depth + 1)}</div>`
      ).join("")
      return `<details open><summary style="cursor:pointer;color:#e4e4e7">Object {${keys.length}}</summary>${items}</details>`
    }
    return this.escape(String(value))
  },
  escape(s) {
    return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }
}

export default JsonTree
