const BeliefVisualizer = {
  mounted() {
    this.render()
    this.handleEvent("update_beliefs", (data) => {
      this.el.dataset.beliefs = JSON.stringify(data.beliefs || [])
      this.render()
    })
  },

  updated() {
    this.render()
  },

  render() {
    const raw = this.el.dataset.beliefs
    if (!raw) return

    let beliefs
    try { beliefs = JSON.parse(raw) } catch { return }
    if (!Array.isArray(beliefs) || beliefs.length === 0) return

    const w = this.el.clientWidth || 300
    const barH = 28
    const h = beliefs.length * barH + 10
    const maxBar = w - 80

    const bars = beliefs.map((val, i) => {
      const bw = Math.max(1, val * maxBar)
      const y = i * barH + 5
      return `
        <rect x="60" y="${y}" width="${bw}" height="20" rx="3" fill="#10b981" opacity="0.8"/>
        <text x="2" y="${y + 15}" font-size="11" fill="#555">S${i}</text>
        <text x="${62 + bw}" y="${y + 15}" font-size="10" fill="#333">${val.toFixed(3)}</text>
      `
    }).join("")

    this.el.innerHTML = `<svg width="${w}" height="${h}" xmlns="http://www.w3.org/2000/svg">${bars}</svg>`
  }
}

export default BeliefVisualizer
