import { Controller } from "@hotwired/stimulus"

const MEMBERS = [
  { name: "BlazeFist", level: 95, status: "Okay", activity: "Online", timer: null, travel: null, total: 18600000000 },
  { name: "IronWolf", level: 92, status: "Okay", activity: "Idle", timer: null, travel: null, total: 15100000000 },
  { name: "ShadowStrike", level: 98, status: "Okay", activity: "Online", timer: null, travel: null, total: 12500000000 },
  { name: "ViperQueen", level: 90, status: "Traveling", activity: "Idle", timer: null, travel: { direction: "returning", seconds: 130 }, total: 11400000000 },
  { name: "PhantomX", level: 88, status: "Hospital", activity: "Offline", timer: { seconds: 225 }, travel: null, total: 9800000000 },
  { name: "NightViper", level: 85, status: "Okay", activity: "Online", timer: null, travel: null, total: 8200000000 },
  { name: "StormRider", level: 82, status: "Traveling", activity: "Online", timer: null, travel: { direction: "outbound", seconds: 500 }, total: 7300000000 },
  { name: "DeathBlade", level: 78, status: "Okay", activity: "Idle", timer: null, travel: null, total: 5700000000 },
  { name: "CrimsonFury", level: 75, status: "Hospital", activity: "Offline", timer: { seconds: 45 }, travel: null, total: 4200000000 },
  { name: "FrostBite", level: 70, status: "Okay", activity: "Offline", timer: null, travel: null, total: 3100000000 }
]

const STATUS_ORDER = { Okay: 0, Traveling: 1, Hospital: 2 }
const ACTIVITY_ORDER = { Online: 0, Idle: 1, Offline: 2 }

export default class extends Controller {
  static targets = ["table", "filterCount"]

  connect() {
    this.members = MEMBERS.map(m => ({
      ...m,
      timer: m.timer ? { ...m.timer } : null,
      travel: m.travel ? { ...m.travel } : null
    }))
    this.sortKey = "total"
    this.sortDir = "desc"
    this.statusFilters = { Okay: true, Hospital: true, Traveling: true }
    this.activityFilters = { Online: true, Idle: true, Offline: true }

    this.render()
    this.timerInterval = setInterval(() => this.tickTimers(), 1000)
  }

  disconnect() {
    if (this.timerInterval) clearInterval(this.timerInterval)
  }

  tickTimers() {
    let changed = false
    this.members.forEach(m => {
      if (m.timer && m.timer.seconds > 0) {
        m.timer.seconds--
        changed = true
        if (m.timer.seconds <= 0) {
          m.status = "Okay"
          m.timer = null
        }
      }
      if (m.travel && m.travel.seconds > 0) {
        m.travel.seconds--
        changed = true
        if (m.travel.seconds <= 0) {
          m.status = "Okay"
          m.travel = null
        }
      }
    })
    if (changed) this.updateTimerCells()
  }

  updateTimerCells() {
    const rows = this.tableTarget.querySelectorAll("tr[data-member]")
    rows.forEach(row => {
      const name = row.dataset.member
      const member = this.members.find(m => m.name === name)
      if (!member) return

      const timerCell = row.querySelector(".demo-war-timer")
      if (timerCell) timerCell.innerHTML = this.renderTimer(member)

      const statusCell = row.querySelector(".demo-war-status-cell")
      if (statusCell) statusCell.innerHTML = this.renderStatus(member.status)
    })
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

  toggleFilter(event) {
    const type = event.currentTarget.dataset.filterType
    const value = event.currentTarget.dataset.filterValue
    const filters = type === "status" ? this.statusFilters : this.activityFilters
    filters[value] = !filters[value]
    event.currentTarget.classList.toggle("demo-filter-disabled")
    this.render()
  }

  getFiltered() {
    return this.members.filter(m =>
      this.statusFilters[m.status] && this.activityFilters[m.activity]
    )
  }

  getSorted(members) {
    const dir = this.sortDir === "asc" ? 1 : -1
    return [...members].sort((a, b) => {
      let cmp = 0
      switch (this.sortKey) {
        case "name": cmp = a.name.localeCompare(b.name); break
        case "level": cmp = a.level - b.level; break
        case "status": cmp = (STATUS_ORDER[a.status] ?? 99) - (STATUS_ORDER[b.status] ?? 99); break
        case "activity": cmp = (ACTIVITY_ORDER[a.activity] ?? 99) - (ACTIVITY_ORDER[b.activity] ?? 99); break
        case "timer": cmp = this.timerSeconds(a) - this.timerSeconds(b); break
        case "total": cmp = a.total - b.total; break
      }
      return cmp * dir
    })
  }

  timerSeconds(m) {
    if (m.timer) return m.timer.seconds
    if (m.travel) return m.travel.seconds
    return -1
  }

  render() {
    const filtered = this.getFiltered()
    const sorted = this.getSorted(filtered)
    const hidden = this.members.length - filtered.length

    this.filterCountTarget.textContent = hidden > 0
      ? `(${filtered.length}/${this.members.length}) ${hidden} hidden`
      : `(${filtered.length}/${this.members.length})`

    const indicator = (key) => {
      if (this.sortKey !== key) return ""
      return `<span class="demo-sort-indicator">${this.sortDir === "asc" ? "▲" : "▼"}</span>`
    }

    let html = `<table class="demo-war-table">
      <thead><tr>
        <th class="demo-sortable" data-sort-key="name" data-action="click->demo-war-dashboard#sort">Member ${indicator("name")}</th>
        <th class="demo-sortable demo-col-level" data-sort-key="level" data-action="click->demo-war-dashboard#sort">Lvl ${indicator("level")}</th>
        <th class="demo-sortable" data-sort-key="status" data-action="click->demo-war-dashboard#sort">Status ${indicator("status")}</th>
        <th class="demo-sortable" data-sort-key="activity" data-action="click->demo-war-dashboard#sort">Activity ${indicator("activity")}</th>
        <th class="demo-sortable" data-sort-key="timer" data-action="click->demo-war-dashboard#sort">Timer ${indicator("timer")}</th>
        <th class="demo-sortable" data-sort-key="total" data-action="click->demo-war-dashboard#sort">Total Stats ${indicator("total")}</th>
      </tr></thead><tbody>`

    sorted.forEach(m => {
      const rowClass = m.status === "Hospital" ? "demo-row-hospital" : ""
      html += `<tr data-member="${m.name}" class="${rowClass}">
        <td><span class="demo-player-name">${m.name}</span></td>
        <td class="demo-col-level"><span class="demo-stat-value">${m.level}</span></td>
        <td class="demo-war-status-cell">${this.renderStatus(m.status)}</td>
        <td>${this.renderActivity(m.activity)}</td>
        <td class="demo-war-timer">${this.renderTimer(m)}</td>
        <td><span class="demo-stat-value demo-stat-total">${this.formatStats(m.total)}</span></td>
      </tr>`
    })

    html += "</tbody></table>"
    this.tableTarget.innerHTML = html
  }

  renderStatus(status) {
    const cls = status.toLowerCase()
    return `<span class="demo-member-status demo-status-${cls}">${status}</span>`
  }

  renderActivity(activity) {
    const cls = activity.toLowerCase()
    return `<span class="demo-action-badge demo-action-${cls}">${activity}</span>`
  }

  renderTimer(m) {
    if (m.timer && m.timer.seconds > 0) {
      const cls = m.timer.seconds < 60 ? "demo-timer-expiring" : ""
      return `<span class="demo-hospital-timer ${cls}">${this.formatTime(m.timer.seconds)}</span>`
    }
    if (m.travel && m.travel.seconds > 0) {
      const arrow = m.travel.direction === "returning" ? "←" : "→"
      return `<span class="demo-travel-timer">${arrow} ${this.formatTime(m.travel.seconds)}</span>`
    }
    if (m.travel && m.travel.seconds <= 0) {
      return `<span class="demo-travel-landing">Landing</span>`
    }
    return `<span class="demo-no-data">-</span>`
  }

  formatTime(seconds) {
    const m = Math.floor(seconds / 60)
    const s = seconds % 60
    return `${m}:${s.toString().padStart(2, "0")}`
  }

  formatStats(n) {
    if (n >= 1000000000) return `${(n / 1000000000).toFixed(1)}B`
    if (n >= 1000000) return `${(n / 1000000).toFixed(1)}M`
    if (n >= 1000) return `${(n / 1000).toFixed(1)}K`
    return n.toString()
  }
}
