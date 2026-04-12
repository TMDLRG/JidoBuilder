const NS = "http://www.w3.org/2000/svg"

const WorkflowDag = {
  mounted() {
    this.state = { nodes: [], edges: [], viewBox: [0, 0, 1200, 800], selected: null, drag: null, linkFrom: null }
    this.svg = document.createElementNS(NS, "svg")
    this.svg.setAttribute("class", "w-full h-[560px] bg-white rounded border")
    this.svg.addEventListener("mousedown", (e) => this.onDown(e))
    this.svg.addEventListener("mousemove", (e) => this.onMove(e))
    this.svg.addEventListener("mouseup", () => this.onUp())
    this.svg.addEventListener("wheel", (e) => this.onWheel(e))
    this.el.innerHTML = ""
    this.el.appendChild(this.svg)
    this.handleEvent("init_graph", ({ nodes, edges }) => {
      this.state.nodes = nodes || []
      this.state.edges = edges || []
      this.render()
    })
    this.handleEvent("highlight_step", ({ step }) => {
      this.state.selected = step
      this.render()
    })
    this.render()
  },
  updated() {
    try {
      this.state.nodes = JSON.parse(this.el.dataset.nodes || "[]")
      this.state.edges = JSON.parse(this.el.dataset.edges || "[]")
    } catch (_) {}
    this.render()
  },
  colors(kind) {
    return { action: "#10b981", emit: "#3b82f6", condition: "#f59e0b", transform: "#8b5cf6" }[kind] || "#64748b"
  },
  point(e) {
    const r = this.svg.getBoundingClientRect()
    return { x: e.clientX - r.left, y: e.clientY - r.top }
  },
  nodeAt(p) {
    return this.state.nodes.find((n) => p.x >= n.x && p.x <= n.x + 170 && p.y >= n.y && p.y <= n.y + 56)
  },
  onDown(e) {
    const p = this.point(e)
    const node = this.nodeAt(p)
    if (node) {
      this.state.selected = node.id || node.name
      this.state.drag = { id: node.id || node.name, dx: p.x - node.x, dy: p.y - node.y }
      this.pushEvent("node_selected", { node_id: node.id || node.name })
      if (p.x > node.x + 158) this.state.linkFrom = node.id || node.name
    } else {
      this.state.drag = null
      this.state.linkFrom = null
    }
    this.render()
  },
  onMove(e) {
    if (!this.state.drag) return
    const p = this.point(e)
    const node = this.state.nodes.find((n) => (n.id || n.name) === this.state.drag.id)
    if (!node) return
    node.x = p.x - this.state.drag.dx
    node.y = p.y - this.state.drag.dy
    this.render()
  },
  onUp() {
    if (this.state.drag) {
      const node = this.state.nodes.find((n) => (n.id || n.name) === this.state.drag.id)
      if (node) this.pushEvent("node_moved", { name: node.name, x: node.x, y: node.y, workflow_id: this.el.dataset.workflowId })
    }
    this.state.drag = null
    this.state.linkFrom = null
  },
  onWheel(e) {
    e.preventDefault()
    this.state.viewBox[2] += e.deltaY
    this.state.viewBox[3] += e.deltaY
    this.render()
  },
  path(from, to) {
    const x1 = from.x + 170, y1 = from.y + 28, x2 = to.x, y2 = to.y + 28
    const c1 = x1 + 90, c2 = x2 - 90
    return `M ${x1} ${y1} C ${c1} ${y1}, ${c2} ${y2}, ${x2} ${y2}`
  },
  render() {
    this.svg.setAttribute("viewBox", this.state.viewBox.join(" "))
    this.svg.innerHTML = `<rect x='0' y='0' width='100%' height='100%' fill='#fafafa'/>`

    this.state.edges.forEach((edge) => {
      const from = this.state.nodes.find((n) => `${n.id}` === `${edge.source}` || `${n.name}` === `${edge.source}`)
      const to = this.state.nodes.find((n) => `${n.id}` === `${edge.target}` || `${n.name}` === `${edge.target}`)
      if (!from || !to) return
      const path = document.createElementNS(NS, "path")
      path.setAttribute("d", this.path(from, to))
      path.setAttribute("stroke", "#94a3b8")
      path.setAttribute("fill", "none")
      path.setAttribute("stroke-width", "2")
      this.svg.appendChild(path)
    })

    this.state.nodes.forEach((node) => {
      const g = document.createElementNS(NS, "g")
      const selected = this.state.selected === (node.id || node.name)
      const rect = document.createElementNS(NS, "rect")
      rect.setAttribute("x", node.x || 40)
      rect.setAttribute("y", node.y || 40)
      rect.setAttribute("rx", "10")
      rect.setAttribute("width", "170")
      rect.setAttribute("height", "56")
      rect.setAttribute("fill", this.colors(node.kind))
      rect.setAttribute("stroke", selected ? "#111827" : "none")
      rect.setAttribute("stroke-width", selected ? "3" : "0")
      const label = document.createElementNS(NS, "text")
      label.setAttribute("x", (node.x || 40) + 14)
      label.setAttribute("y", (node.y || 40) + 32)
      label.setAttribute("fill", "#fff")
      label.setAttribute("font-size", "12")
      label.textContent = node.name
      g.appendChild(rect)
      g.appendChild(label)
      this.svg.appendChild(g)
    })
  }
}

export default WorkflowDag
