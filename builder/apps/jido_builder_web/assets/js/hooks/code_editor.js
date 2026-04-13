const CodeEditor = {
  mounted() {
    this.setupListeners()

    this.handleEvent("cell_result", ({ result, status, cell }) => {
      // Update cell count in the phx-update="ignore" container
      const countEl = this.el.querySelector("[data-role='cell-count']")
      if (countEl) {
        countEl.textContent = `${cell} cells executed`
      }

      // Create or update output area
      let output = this.el.querySelector("[data-role='output']")
      if (!output) {
        output = document.createElement("div")
        output.setAttribute("data-role", "output")
        output.className = "mt-2 p-2 rounded text-xs font-mono border"
        this.el.appendChild(output)
      }
      output.className = status === "ok"
        ? "mt-2 p-2 rounded text-xs font-mono border bg-green-50 text-green-800"
        : "mt-2 p-2 rounded text-xs font-mono border bg-red-50 text-red-800"
      output.textContent = `[${cell}] ${result}`
    })
  },

  reconnected() {
    // Re-attach listeners after LiveView reconnects
    this.setupListeners()
  },

  setupListeners() {
    const textarea = this.el.querySelector("textarea")
    if (textarea) {
      textarea.classList.add("font-mono", "text-sm")
      textarea.setAttribute("spellcheck", "false")
    }

    const runBtn = this.el.querySelector("[data-action='run']")
    if (runBtn) {
      // Remove old listener to prevent duplicates
      runBtn.replaceWith(runBtn.cloneNode(true))
      const newBtn = this.el.querySelector("[data-action='run']")
      newBtn.addEventListener("click", () => {
        const code = textarea ? textarea.value : ""
        if (code.trim()) {
          this.pushEvent("run_cell", { code })
        }
      })
    }
  }
}

export default CodeEditor
