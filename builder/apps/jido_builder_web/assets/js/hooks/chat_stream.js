const ChatStream = {
  mounted() {
    this.currentMessage = null

    this.handleEvent("new_chunk", ({ content }) => {
      if (!this.currentMessage) {
        this.currentMessage = document.createElement("div")
        this.currentMessage.className = "p-2 rounded text-sm bg-zinc-50 mr-8 mb-2"
        const label = document.createElement("span")
        label.className = "text-xs font-semibold"
        label.textContent = "assistant"
        this.currentMessage.appendChild(label)
        const text = document.createElement("p")
        text.className = "streaming-text"
        this.currentMessage.appendChild(text)
        this.el.appendChild(this.currentMessage)
      }

      const textEl = this.currentMessage.querySelector(".streaming-text")
      if (textEl) {
        textEl.textContent += content
      }

      this.el.scrollTop = this.el.scrollHeight
    })

    this.handleEvent("stream_end", () => {
      this.currentMessage = null
    })

    this.handleEvent("add_message", ({ role, content }) => {
      const msg = document.createElement("div")
      const isUser = role === "user"
      msg.className = `p-2 rounded text-sm mb-2 ${isUser ? "bg-blue-50 ml-8" : "bg-zinc-50 mr-8"}`
      msg.innerHTML = `<span class="text-xs font-semibold">${role}</span><p>${this.escapeHtml(content)}</p>`
      this.el.appendChild(msg)
      this.el.scrollTop = this.el.scrollHeight
    })
  },

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}

export default ChatStream
