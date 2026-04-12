import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import WorkflowDag from "./hooks/workflow_dag"
import JsonTree from "./hooks/json_tree"
import ExecutionTimeline from "./hooks/execution_timeline"

const Sidebar = {
  mounted() {
    const apply = (collapsed) => {
      const sidebar = this.el.querySelector("#app-sidebar")
      if (!sidebar) return
      sidebar.style.width = collapsed ? "4rem" : "16rem"
      localStorage.setItem("builder.sidebar.collapsed", collapsed ? "1" : "0")
    }

    let collapsed = localStorage.getItem("builder.sidebar.collapsed") === "1"
    apply(collapsed)

    this.el.querySelectorAll('[data-role="sidebar-toggle"]').forEach((btn) => {
      btn.addEventListener("click", () => {
        collapsed = !collapsed
        apply(collapsed)
      })
    })
  }
}

const Download = {
  mounted() {
    this.handleEvent("download", ({ filename, content }) => {
      const blob = new Blob([content], { type: "text/plain;charset=utf-8" })
      const url = URL.createObjectURL(blob)
      const anchor = document.createElement("a")
      anchor.href = url
      anchor.download = filename || "export.ex"
      document.body.appendChild(anchor)
      anchor.click()
      anchor.remove()
      URL.revokeObjectURL(url)
    })
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: { WorkflowDag, Sidebar, JsonTree, ExecutionTimeline, Download }
})

liveSocket.connect()
window.liveSocket = liveSocket
