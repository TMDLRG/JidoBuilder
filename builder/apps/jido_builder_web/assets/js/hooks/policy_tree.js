const PolicyTree = {
  mounted() {
    this.render()
    this.handleEvent("update_policies", (data) => {
      this.el.dataset.policies = JSON.stringify(data.policies || [])
      this.render()
    })
  },

  updated() {
    this.render()
  },

  render() {
    const raw = this.el.dataset.policies
    if (!raw) return

    let policies
    try { policies = JSON.parse(raw) } catch { return }
    if (!Array.isArray(policies) || policies.length === 0) return

    const w = this.el.clientWidth || 300
    const barH = 32
    const h = policies.length * barH + 10

    // Find min/max EFE for normalization
    const efes = policies.map(p => p.efe || 0)
    const minEfe = Math.min(...efes)
    const maxEfe = Math.max(...efes)
    const range = maxEfe - minEfe || 1
    const maxBar = w - 140

    const bars = policies.map((p, i) => {
      const norm = 1 - ((p.efe - minEfe) / range) // lower EFE = longer bar
      const bw = Math.max(2, norm * maxBar)
      const y = i * barH + 5
      const isBest = i === 0 || p.efe === minEfe
      const color = isBest ? "#10b981" : "#6b7280"
      const label = (p.actions || []).join(",")
      return `
        <rect x="80" y="${y}" width="${bw}" height="22" rx="3" fill="${color}" opacity="0.7"/>
        <text x="2" y="${y + 16}" font-size="10" fill="#555">[${label}]</text>
        <text x="${82 + bw}" y="${y + 16}" font-size="10" fill="#333">${p.efe.toFixed(2)}</text>
      `
    }).join("")

    this.el.innerHTML = `<svg width="${w}" height="${h}" xmlns="http://www.w3.org/2000/svg">${bars}</svg>`
  }
}

export default PolicyTree
