import { Controller } from "@hotwired/stimulus"

const TARGETS = { xanax: 3, energy: 1, nerve: 1 }

const MEMBERS = [
  { name: "BlazeFist", level: 95, ssl: false, xanax: 4.21, energy: 1.43, nerve: 1.14, contracts: 2.07, crimes: 14.29 },
  { name: "IronWolf", level: 92, ssl: false, xanax: 3.14, energy: 1.07, nerve: 0.93, contracts: 1.50, crimes: 11.43 },
  { name: "ShadowStrike", level: 98, ssl: true, xanax: 0, energy: 1.29, nerve: 1.36, contracts: 3.21, crimes: 18.57 },
  { name: "ViperQueen", level: 90, ssl: false, xanax: 3.00, energy: 1.00, nerve: 1.00, contracts: 1.86, crimes: 9.71 },
  { name: "PhantomX", level: 88, ssl: false, xanax: 2.86, energy: 0.71, nerve: 1.07, contracts: 0.93, crimes: 7.14 },
  { name: "NightViper", level: 85, ssl: false, xanax: 1.43, energy: 0.36, nerve: 0.21, contracts: 0.71, crimes: 4.29 },
  { name: "StormRider", level: 82, ssl: false, xanax: 3.57, energy: 1.21, nerve: 0.86, contracts: 1.14, crimes: 8.57 },
  { name: "DeathBlade", level: 78, ssl: false, xanax: 2.14, energy: 0.57, nerve: 0.43, contracts: 0.50, crimes: 3.43 },
  { name: "CrimsonFury", level: 75, ssl: false, xanax: 0.71, energy: 0.14, nerve: 0.07, contracts: 0.29, crimes: 1.86 },
  { name: "FrostBite", level: 70, ssl: false, xanax: 3.43, energy: 0.93, nerve: 1.21, contracts: 1.64, crimes: 12.14 }
]

function statColor(daily, target) {
  if (!target || target === 0) return "green"
  const ratio = daily / target
  if (ratio >= 1.0) return "green"
  if (ratio >= 0.6) return "yellow"
  return "red"
}

function complianceLevel(m) {
  const x = m.ssl ? "green" : statColor(m.xanax, TARGETS.xanax)
  const e = statColor(m.energy, TARGETS.energy)
  const n = statColor(m.nerve, TARGETS.nerve)
  if (x === "green" && e === "green" && n === "green") return "compliant"
  if (x === "red" || e === "red" || n === "red") return "danger"
  return "warning"
}

function complianceScore(m) {
  let xWeight = 40, eWeight = 30, nWeight = 30
  if (m.ssl) {
    xWeight = 0; eWeight = 50; nWeight = 50
  }
  const xScore = m.ssl ? 0 : Math.min((m.xanax / TARGETS.xanax) * xWeight, xWeight)
  const eScore = TARGETS.energy > 0 ? Math.min((m.energy / TARGETS.energy) * eWeight, eWeight) : eWeight
  const nScore = TARGETS.nerve > 0 ? Math.min((m.nerve / TARGETS.nerve) * nWeight, nWeight) : nWeight
  return Math.round(xScore + eScore + nScore)
}

export default class extends Controller {
  static targets = ["table", "compliantCount", "warningCount", "dangerCount"]

  connect() {
    this.members = MEMBERS.map(m => ({
      ...m,
      level: m.level,
      compliance: complianceLevel(m),
      score: complianceScore(m)
    }))
    this.sortKey = "score"
    this.sortDir = "desc"
    this.render()
  }

  sort(event) {
    const key = event.currentTarget.dataset.sortKey
    if (this.sortKey === key) {
      this.sortDir = this.sortDir === "asc" ? "desc" : "asc"
    } else {
      this.sortKey = key
      this.sortDir = "asc"
    }
    this.render()
  }

  getSorted() {
    const dir = this.sortDir === "asc" ? 1 : -1
    return [...this.members].sort((a, b) => {
      let cmp = 0
      switch (this.sortKey) {
        case "name": cmp = a.name.localeCompare(b.name); break
        case "xanax": cmp = a.xanax - b.xanax; break
        case "energy": cmp = a.energy - b.energy; break
        case "nerve": cmp = a.nerve - b.nerve; break
        case "contracts": cmp = a.contracts - b.contracts; break
        case "crimes": cmp = a.crimes - b.crimes; break
        case "score": cmp = a.score - b.score; break
      }
      return cmp * dir
    })
  }

  render() {
    const sorted = this.getSorted()
    const counts = { compliant: 0, warning: 0, danger: 0 }
    this.members.forEach(m => counts[m.compliance]++)

    this.compliantCountTarget.textContent = counts.compliant
    this.warningCountTarget.textContent = counts.warning
    this.dangerCountTarget.textContent = counts.danger

    const indicator = (key) => {
      if (this.sortKey !== key) return ""
      return `<span class="demo-sort-indicator">${this.sortDir === "asc" ? "▲" : "▼"}</span>`
    }

    const th = (key, label, sub) => {
      const subHtml = sub ? `<span class="demo-ct-sub">${sub}</span>` : ""
      return `<th class="demo-sortable" data-sort-key="${key}" data-action="click->demo-compliance#sort">${label} ${indicator(key)}${subHtml}</th>`
    }

    let html = `<table class="demo-ct-table">
      <thead><tr>
        <th class="demo-ct-th-status"></th>
        ${th("name", "Member", "")}
        ${th("xanax", "Xanax", `${TARGETS.xanax}/day`)}
        ${th("energy", "E. Refills", `${TARGETS.energy}/day`)}
        ${th("nerve", "N. Refills", `${TARGETS.nerve}/day`)}
        <th class="demo-ct-hide-mobile demo-sortable" data-sort-key="contracts" data-action="click->demo-compliance#sort">Contracts ${indicator("contracts")}</th>
        <th class="demo-ct-hide-mobile demo-sortable" data-sort-key="crimes" data-action="click->demo-compliance#sort">Crimes ${indicator("crimes")}</th>
      </tr></thead><tbody>`

    sorted.forEach(m => {
      const badge = this.renderBadge(m.compliance)
      const xColor = m.ssl ? "" : statColor(m.xanax, TARGETS.xanax)
      const eColor = statColor(m.energy, TARGETS.energy)
      const nColor = statColor(m.nerve, TARGETS.nerve)

      html += `<tr class="demo-ct-row-${m.compliance}">
        <td class="demo-ct-td-status">${badge}</td>
        <td>
          <span class="demo-player-name">${m.name}</span>
          ${m.ssl ? '<span class="demo-ct-ssl">SSL</span>' : ""}
        </td>
        <td>${m.ssl ? this.renderExempt() : this.renderStat(m.xanax, xColor)}</td>
        <td>${this.renderStat(m.energy, eColor)}</td>
        <td>${this.renderStat(m.nerve, nColor)}</td>
        <td class="demo-ct-hide-mobile">${this.renderPlainStat(m.contracts)}</td>
        <td class="demo-ct-hide-mobile">${this.renderPlainStat(m.crimes)}</td>
      </tr>`
    })

    html += "</tbody></table>"
    this.tableTarget.innerHTML = html
  }

  renderBadge(level) {
    const icons = { compliant: "✓", warning: "⚠", danger: "✗" }
    return `<span class="demo-ct-badge demo-ct-badge-${level}">${icons[level]}</span>`
  }

  renderStat(daily, color) {
    return `<div class="demo-ct-stat">
      <span class="demo-ct-stat-daily demo-ct-c-${color}">${daily.toFixed(2)}</span>
    </div>`
  }

  renderPlainStat(daily) {
    return `<div class="demo-ct-stat">
      <span class="demo-ct-stat-daily">${daily.toFixed(2)}</span>
    </div>`
  }

  renderExempt() {
    return `<div class="demo-ct-stat"><span class="demo-ct-exempt">Exempt</span></div>`
  }
}
