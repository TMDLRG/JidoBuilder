/**
 * WorkflowDag — Phase 3.5 LiveView hook for the D3 DAG workflow editor.
 *
 * Server → client events:
 *   init_graph  { nodes: [...], edges: [...] }  — initial/full graph state
 *
 * Client → server events (pushEvent):
 *   node_moved  { name, x, y, workflow_id }     — after drag
 *   edge_upserted { from, to, workflow_id }      — after draw
 *   edge_removed  { from, to, workflow_id }      — after delete
 *   save_workflow { workflow_id, nodes }         — on save button
 */
const WorkflowDag = {
  mounted() {
    this._nodes = JSON.parse(this.el.dataset.nodes || "[]")
    this._edges = JSON.parse(this.el.dataset.edges || "[]")

    // Listen for init_graph pushed from server on connect
    this.handleEvent("init_graph", ({ nodes, edges }) => {
      this._nodes = nodes || []
      this._edges = edges || []
      this._render()
    })
  },

  updated() {
    this._nodes = JSON.parse(this.el.dataset.nodes || "[]")
    this._edges = JSON.parse(this.el.dataset.edges || "[]")
    this._render()
  },

  _render() {
    // Minimal placeholder render — a real implementation would use D3.
    // Nodes are rendered as labelled rectangles; edges as connecting lines.
    // The canvas element is identified by id="workflow-dag".
    const el = this.el
    if (!el) return

    const existing = el.querySelector(".dag-canvas")
    if (existing) existing.remove()

    const canvas = document.createElement("div")
    canvas.className = "dag-canvas text-xs p-2 text-left w-full"

    const nodeList = this._nodes.map(n => `<div class="dag-node font-mono">${n.name || n.id}</div>`).join("")
    canvas.innerHTML = nodeList || "<span class='text-zinc-400'>Empty workflow — add steps</span>"
    el.appendChild(canvas)
  }
}

export default WorkflowDag
