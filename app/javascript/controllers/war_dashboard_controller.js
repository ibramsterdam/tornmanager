import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL = 6000 // Match WarPollingJob interval

export default class extends Controller {
  static values = {
    initialData: Object,
    ourScore: Number,
    theirScore: Number,
    targetScore: Number,
    factionName: String,
    enemyName: String,
    startedAt: String,
    pollUrl: String
  }

  static targets = [
    "ourScore", "theirScore", "targetScore",
    "warTimer", "connectionStatus", "lastUpdated",
    "membersBody",
    "sortIndicatorName", "sortIndicatorLevel", "sortIndicatorStatus",
    "sortIndicatorTimer", "sortIndicatorTotal",
    "sortIndicatorStrength", "sortIndicatorDefense",
    "sortIndicatorSpeed", "sortIndicatorDexterity"
  ]

  connect() {
    this.members = {}
    this.sortKey = "status"
    this.sortDirection = "asc"
    this.timerInterval = null
    this.pollInterval = null

    // Load initial data from cache if available
    if (this.initialDataValue && Object.keys(this.initialDataValue).length > 0) {
      this.handleData(this.initialDataValue)
      this.updateConnectionStatus("connected", "Live")
    }

    // Start war duration timer
    this.startWarTimer()

    // Start HTTP polling for war data
    this.startPolling()

    // Start hospital countdown ticker
    this.timerInterval = setInterval(() => this.tickTimers(), 1000)

    // Update sort indicator for default sort
    this.updateSortIndicators()
  }

  disconnect() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
    if (this.warTimerInterval) {
      clearInterval(this.warTimerInterval)
      this.warTimerInterval = null
    }
  }

  // --- HTTP Polling ---

  startPolling() {
    if (!this.pollUrlValue) return

    // Fetch immediately, then every POLL_INTERVAL
    this.fetchWarData()
    this.pollInterval = setInterval(() => this.fetchWarData(), POLL_INTERVAL)
  }

  async fetchWarData() {
    try {
      const response = await fetch(this.pollUrlValue, {
        headers: { "Accept": "application/json" }
      })

      if (response.status === 204) return

      if (response.ok) {
        const data = await response.json()
        if (data && data.members) {
          this.handleData(data)
          this.updateConnectionStatus("connected", "Live")
        }
      }
    } catch {
      this.updateConnectionStatus("connecting", "Reconnecting...")
    }
  }

  // --- Data handling ---

  handleData(data) {
    // Update scores
    if (data.our_score !== undefined) {
      this.ourScoreValue = data.our_score
      this.ourScoreTarget.textContent = data.our_score
    }
    if (data.their_score !== undefined) {
      this.theirScoreValue = data.their_score
      this.theirScoreTarget.textContent = data.their_score
    }
    if (data.target_score !== undefined) {
      this.targetScoreValue = data.target_score
      this.targetScoreTarget.textContent = data.target_score
    }

    this.updateScoreClasses()

    // Update members (filter out Fallen)
    if (data.members) {
      const previousMembers = { ...this.members }
      this.members = {}

      for (const [id, member] of Object.entries(data.members)) {
        if (member.status?.state === "Fallen") continue

        this.members[id] = {
          ...member,
          torn_id: member.torn_id || id,
          _changed: this.memberChanged(previousMembers[id], member)
        }
      }

      this.renderTable()
    }

    // Update last updated timestamp
    if (data.cached_at) {
      this.updateLastUpdated(data.cached_at)
    }
  }

  memberChanged(prev, current) {
    if (!prev) return true
    if (prev.status?.state !== current.status?.state) return true
    if (prev.status?.until !== current.status?.until) return true
    if (prev.level !== current.level) return true
    return false
  }

  // --- Score display ---

  updateScoreClasses() {
    const ours = this.ourScoreValue
    const theirs = this.theirScoreValue
    const ourEl = this.ourScoreTarget
    const theirEl = this.theirScoreTarget

    ourEl.classList.remove("winning", "losing", "tied")
    theirEl.classList.remove("winning", "losing", "tied")

    if (ours > theirs) {
      ourEl.classList.add("winning")
      theirEl.classList.add("losing")
    } else if (theirs > ours) {
      ourEl.classList.add("losing")
      theirEl.classList.add("winning")
    } else {
      ourEl.classList.add("tied")
      theirEl.classList.add("tied")
    }
  }

  // --- War timer ---

  startWarTimer() {
    if (!this.startedAtValue) return

    const startedAt = new Date(this.startedAtValue)
    const updateTimer = () => {
      const now = new Date()
      const elapsed = Math.floor((now - startedAt) / 1000)
      if (this.hasWarTimerTarget) {
        this.warTimerTarget.textContent = this.formatDuration(elapsed)
      }
    }

    updateTimer()
    this.warTimerInterval = setInterval(updateTimer, 1000)
  }

  // --- Connection status ---

  updateConnectionStatus(state, text) {
    if (!this.hasConnectionStatusTarget) return

    this.connectionStatusTarget.innerHTML = `
      <span class="connection-dot ${state}"></span>
      <span class="connection-text">${text}</span>
    `
  }

  // --- Last updated ---

  updateLastUpdated(isoString) {
    if (!this.hasLastUpdatedTarget) return

    const date = new Date(isoString)
    const hours = date.getHours().toString().padStart(2, "0")
    const minutes = date.getMinutes().toString().padStart(2, "0")
    const seconds = date.getSeconds().toString().padStart(2, "0")
    this.lastUpdatedTarget.textContent = `Updated ${hours}:${minutes}:${seconds}`
  }

  // --- Sorting ---

  sort({ params: { sortKey } }) {
    if (this.sortKey === sortKey) {
      this.sortDirection = this.sortDirection === "asc" ? "desc" : "asc"
    } else {
      this.sortKey = sortKey
      this.sortDirection = "asc"
    }

    this.updateSortIndicators()
    this.renderTable()
  }

  updateSortIndicators() {
    const keys = ["Name", "Level", "Status", "Timer", "Total", "Strength", "Defense", "Speed", "Dexterity"]

    keys.forEach(key => {
      const targetName = `sortIndicator${key}`
      const target = this[`has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`]
        ? this[`${targetName}Target`]
        : null

      if (target) {
        target.classList.remove("asc", "desc")
        if (this.sortKey === key.toLowerCase()) {
          target.classList.add(this.sortDirection)
        }
      }
    })
  }

  getSortedMembers() {
    const members = Object.values(this.members)
    const key = this.sortKey
    const dir = this.sortDirection === "asc" ? 1 : -1

    return members.sort((a, b) => {
      let aVal, bVal

      switch (key) {
        case "name":
          aVal = (a.name || "").toLowerCase()
          bVal = (b.name || "").toLowerCase()
          return aVal < bVal ? -1 * dir : aVal > bVal ? 1 * dir : 0

        case "level":
          return ((a.level || 0) - (b.level || 0)) * dir

        case "status":
          aVal = this.statusSortOrder(a.status?.state)
          bVal = this.statusSortOrder(b.status?.state)
          return (aVal - bVal) * dir

        case "timer":
          aVal = this.getTimerSeconds(a)
          bVal = this.getTimerSeconds(b)
          return (aVal - bVal) * dir

        case "total":
          aVal = a.stats?.total || 0
          bVal = b.stats?.total || 0
          return (aVal - bVal) * dir

        case "strength":
          aVal = a.stats?.strength || 0
          bVal = b.stats?.strength || 0
          return (aVal - bVal) * dir

        case "defense":
          aVal = a.stats?.defense || 0
          bVal = b.stats?.defense || 0
          return (aVal - bVal) * dir

        case "speed":
          aVal = a.stats?.speed || 0
          bVal = b.stats?.speed || 0
          return (aVal - bVal) * dir

        case "dexterity":
          aVal = a.stats?.dexterity || 0
          bVal = b.stats?.dexterity || 0
          return (aVal - bVal) * dir

        default:
          return 0
      }
    })
  }

  statusSortOrder(state) {
    const order = { "Okay": 0, "Traveling": 1, "Jail": 2, "Hospital": 3, "Fallen": 4 }
    return order[state] ?? 5
  }

  getTimerSeconds(member) {
    if (!member.status?.until) return -1

    const expiresAt = new Date(member.status.until)
    const now = new Date()
    const remaining = Math.floor((expiresAt - now) / 1000)
    return remaining > 0 ? remaining : -1
  }

  // --- Render ---

  renderTable() {
    if (!this.hasMembersBodyTarget) return

    const sorted = this.getSortedMembers()

    if (sorted.length === 0) {
      this.membersBodyTarget.innerHTML = `
        <tr>
          <td colspan="10" class="table-empty-text">No member data available.</td>
        </tr>
      `
      return
    }

    const rows = sorted.map(member => this.renderRow(member)).join("")
    this.membersBodyTarget.innerHTML = rows
  }

  renderRow(member) {
    const status = member.status || { state: "Unknown" }
    const statusClass = this.statusCssClass(status.state)
    const rowClass = status.state === "Hospital" ? "row-hospital" : "row-okay"
    const changedClass = member._changed ? "row-updated" : ""

    const timerHtml = this.renderTimer(member)
    const statsHtml = this.renderStats(member)
    const attackUrl = `https://www.torn.com/loader.php?sid=attack&user2ID=${member.torn_id}`
    const profileUrl = `https://www.torn.com/profiles.php?XID=${member.torn_id}`
    const attackDisabled = status.state === "Hospital" || status.state === "Jail" || status.state === "Fallen" || status.state === "Traveling"

    return `
      <tr class="${rowClass} ${changedClass}" data-member-id="${member.torn_id}">
        <td>
          <a href="${profileUrl}" target="_blank" class="player-link">${this.escapeHtml(member.name || "Unknown")}</a>
        </td>
        <td class="stat-value">${member.level || "?"}</td>
        <td>
          <span class="member-status ${statusClass}">${this.escapeHtml(status.state || "Unknown")}</span>
        </td>
        <td>${timerHtml}</td>
        ${statsHtml}
        <td>
          <a href="${attackUrl}" target="_blank" class="attack-link ${attackDisabled ? "disabled" : ""}" title="Attack ${this.escapeHtml(member.name || "")}">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/>
              <line x1="12" y1="8" x2="12" y2="16"/>
              <line x1="8" y1="12" x2="16" y2="12"/>
            </svg>
          </a>
        </td>
      </tr>
    `
  }

  renderTimer(member) {
    const status = member.status
    if (!status?.until) return '<span class="stat-value no-data">-</span>'

    const expiresAt = new Date(status.until)
    const now = new Date()
    const remaining = Math.floor((expiresAt - now) / 1000)

    if (remaining <= 0) return '<span class="stat-value no-data">-</span>'

    const expiringSoon = remaining < 60
    const cssClass = expiringSoon ? "hospital-timer expiring-soon" : "hospital-timer"

    return `<span class="${cssClass}" data-timer-until="${status.until}">${this.formatCountdown(remaining)}</span>`
  }

  renderStats(member) {
    const stats = member.stats
    if (!stats) {
      return `
        <td class="stat-value no-data">-</td>
        <td class="stat-value no-data">-</td>
        <td class="stat-value no-data">-</td>
        <td class="stat-value no-data">-</td>
        <td class="stat-value no-data">-</td>
      `
    }

    return `
      <td class="stat-value stat-total">${this.formatStat(stats.total)}</td>
      <td class="stat-value">${this.formatStat(stats.strength)}</td>
      <td class="stat-value">${this.formatStat(stats.defense)}</td>
      <td class="stat-value">${this.formatStat(stats.speed)}</td>
      <td class="stat-value">${this.formatStat(stats.dexterity)}</td>
    `
  }

  // --- Timer tick ---

  tickTimers() {
    if (!this.hasMembersBodyTarget) return

    const timerElements = this.membersBodyTarget.querySelectorAll("[data-timer-until]")
    timerElements.forEach(el => {
      const expiresAt = new Date(el.dataset.timerUntil)
      const now = new Date()
      const remaining = Math.floor((expiresAt - now) / 1000)

      if (remaining <= 0) {
        el.textContent = "-"
        el.className = "stat-value no-data"
        el.removeAttribute("data-timer-until")
      } else {
        el.textContent = this.formatCountdown(remaining)
        if (remaining < 60) {
          el.className = "hospital-timer expiring-soon"
        } else {
          el.className = "hospital-timer"
        }
      }
    })
  }

  // --- Helpers ---

  statusCssClass(state) {
    const map = {
      "Okay": "status-okay",
      "Hospital": "status-hospital",
      "Jail": "status-jail",
      "Traveling": "status-traveling",
      "Abroad": "status-traveling",
      "Fallen": "status-fallen"
    }
    return map[state] || "status-unknown"
  }

  formatCountdown(totalSeconds) {
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, "0")}`
  }

  formatDuration(totalSeconds) {
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60

    if (hours > 0) {
      return `${hours}h ${minutes}m ${seconds}s`
    }
    return `${minutes}m ${seconds}s`
  }

  formatStat(value) {
    if (value === null || value === undefined || value === 0) return "-"

    if (value >= 1_000_000_000) {
      return `${(value / 1_000_000_000).toFixed(1)}B`
    } else if (value >= 1_000_000) {
      return `${(value / 1_000_000).toFixed(1)}M`
    } else if (value >= 1_000) {
      return `${(value / 1_000).toFixed(1)}K`
    }
    return value.toLocaleString()
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
