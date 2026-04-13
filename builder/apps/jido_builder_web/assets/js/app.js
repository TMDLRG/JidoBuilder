import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import WorkflowDag from "./hooks/workflow_dag"
import JsonTree from "./hooks/json_tree"
import ExecutionTimeline from "./hooks/execution_timeline"
import TimeSeriesChart from "./hooks/time_series_chart"
import CodeEditor from "./hooks/code_editor"
import BeliefVisualizer from "./hooks/belief_visualizer"
import PolicyTree from "./hooks/policy_tree"
import ChatStream from "./hooks/chat_stream"

const Sidebar = {
  mounted() {
    const sidebar = this.el.querySelector("#app-sidebar")
    const overlay = this.el.querySelector("#mobile-sidebar-overlay")

    const apply = (collapsed) => {
      if (!sidebar) return
      sidebar.style.width = collapsed ? "4rem" : "16rem"
      if (collapsed) {
        sidebar.classList.add("sidebar-collapsed")
      } else {
        sidebar.classList.remove("sidebar-collapsed")
      }
      localStorage.setItem("builder.sidebar.collapsed", collapsed ? "1" : "0")
    }

    const closeMobile = () => {
      if (!sidebar || !overlay) return
      sidebar.classList.remove("flex")
      sidebar.classList.add("hidden", "md:flex")
      overlay.classList.add("hidden")
    }

    const openMobile = () => {
      if (!sidebar || !overlay) return
      sidebar.classList.remove("hidden")
      sidebar.classList.add("flex")
      sidebar.style.width = "16rem"
      sidebar.classList.remove("sidebar-collapsed")
      overlay.classList.remove("hidden")
    }

    let collapsed = localStorage.getItem("builder.sidebar.collapsed") === "1"
    apply(collapsed)

    // Desktop sidebar toggle
    this.el.querySelectorAll('[data-role="sidebar-toggle"]').forEach((btn) => {
      btn.addEventListener("click", () => {
        collapsed = !collapsed
        apply(collapsed)
      })
    })

    // Mobile menu toggle
    this.el.querySelectorAll('[data-role="mobile-menu-toggle"]').forEach((btn) => {
      btn.addEventListener("click", () => {
        const isHidden = sidebar.classList.contains("hidden")
        if (isHidden) { openMobile() } else { closeMobile() }
      })
    })

    // Close mobile sidebar when clicking overlay
    if (overlay) {
      overlay.addEventListener("click", closeMobile)
    }
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
  hooks: { WorkflowDag, Sidebar, JsonTree, ExecutionTimeline, Download, TimeSeriesChart, CodeEditor, BeliefVisualizer, PolicyTree, ChatStream }
})

liveSocket.connect()
window.liveSocket = liveSocket
