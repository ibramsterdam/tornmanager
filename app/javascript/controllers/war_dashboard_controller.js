import { Controller } from "@hotwired/stimulus"

const FLIGHT_TIMES = {
  "Mexico":           { standard: 1560,  airstrip: 1080, wlt: 780,  bct: 480  },
  "Cayman Islands":   { standard: 2100,  airstrip: 1500, wlt: 1080, bct: 660  },
  "Canada":           { standard: 2460,  airstrip: 1740, wlt: 1200, bct: 720  },
  "Hawaii":           { standard: 8040,  airstrip: 5640, wlt: 4020, bct: 2400 },
  "United Kingdom":   { standard: 9540,  airstrip: 6660, wlt: 4800, bct: 2880 },
  "Argentina":        { standard: 10020, airstrip: 7020, wlt: 4980, bct: 3000 },
  "Switzerland":      { standard: 10500, airstrip: 7380, wlt: 5280, bct: 3180 },
  "Japan":            { standard: 13500, airstrip: 9480, wlt: 6780, bct: 4080 },
  "China":            { standard: 14520, airstrip: 10140, wlt: 7260, bct: 4320 },
  "UAE":              { standard: 16260, airstrip: 11400, wlt: 8100, bct: 4860 },
  "South Africa":     { standard: 17820, airstrip: 12480, wlt: 8940, bct: 5340 }
}

const PLANE_TYPE_MAP = {
  "private_jet":    ["wlt"],
  "light_aircraft": ["airstrip"],
  "airliner":       ["bct", "standard"]
}

export default class extends Controller {
  static values = {
    initialData: Object,
    ourScore: Number,
    theirScore: Number,
    targetScore: Number,
    factionName: String,
    enemyName: String,
    startedAt: String,
    scheduled: Boolean,
    pollUrl: String,
    pollInterval: { type: Number, default: 6000 },
    hideStats: { type: Boolean, default: false },
    editableStats: { type: Boolean, default: false },
    statsUrl: { type: String, default: "" },
    terminatedUrl: { type: String, default: "" }
  }

  static targets = [
    "ourScore", "theirScore", "targetScore", "currentLead", "leadProgress",
    "warTimer", "connectionStatus", "lastUpdated", "updateCountdown",
    "membersBody", "visibleCount", "totalCount", "filterCount",
    "sortIndicatorName", "sortIndicatorLevel", "sortIndicatorStatus",
    "sortIndicatorLastAction", "sortIndicatorTimer", "sortIndicatorTotal",
    "sortIndicatorStrength", "sortIndicatorDefense",
    "sortIndicatorSpeed", "sortIndicatorDexterity",
    "filterStatusOkay", "filterStatusHospital", "filterStatusJail", "filterStatusTraveling", "filterStatusAbroad",
    "filterActionOnline", "filterActionIdle", "filterActionOffline",
    "filterMaxStats", "filterMaxStatsLabel"
  ]

  connect() {
    this.members = {}
    this.sortKey = "status"
    this.sortDirection = "asc"
    this.timerInterval = null
    this.pollInterval = null
    this.countdownInterval = null
    this.secondsUntilUpdate = this.pollIntervalValue / 1000

    if (this.initialDataValue && Object.keys(this.initialDataValue).length > 0) {
      this.handleData(this.initialDataValue)
      this.updateConnectionStatus("connected", "Live")
    }

    this.startWarTimer()
    this.startPolling()
    this.timerInterval = setInterval(() => this.tickTimers(), 1000)
    this.startUpdateCountdown()
    this.updateSortIndicators()

    if (this.editableStatsValue) {
      this.element.addEventListener("click", this.#handleStatClick)
    }
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
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval)
      this.countdownInterval = null
    }
    this.element.removeEventListener("click", this.#handleStatClick)
  }

  startPolling() {
    if (!this.pollUrlValue) return

    this.fetchWarData()
    this.pollInterval = setInterval(() => this.fetchWarData(), this.pollIntervalValue)
  }

  async fetchWarData() {
    try {
      const response = await fetch(this.pollUrlValue, {
        headers: { "Accept": "application/json" }
      })

      if (response.status === 204) return

      if (response.status === 410 && this.terminatedUrlValue) {
        window.location.href = this.terminatedUrlValue
        return
      }

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

  handleData(data) {
    if (data.our_score !== undefined) {
      this.ourScoreValue = data.our_score
      if (this.hasOurScoreTarget) this.ourScoreTarget.textContent = data.our_score
    }
    if (data.their_score !== undefined) {
      this.theirScoreValue = data.their_score
      if (this.hasTheirScoreTarget) this.theirScoreTarget.textContent = data.their_score
    }
    if (data.target_score !== undefined) {
      this.targetScoreValue = data.target_score
      if (this.hasTargetScoreTarget) this.targetScoreTarget.textContent = data.target_score
    }

    if (this.hasOurScoreTarget && this.hasTheirScoreTarget) {
      this.updateScoreClasses()
    }
    this.updateLeadProgress()

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

    if (data.cached_at) {
      this.updateLastUpdated(data.cached_at)
    }
  }

  memberChanged(prev, current) {
    if (!prev) return true
    if (prev.status?.state !== current.status?.state) return true
    if (prev.status?.until !== current.status?.until) return true
    if (prev.level !== current.level) return true
    if (prev.last_action?.status !== current.last_action?.status) return true
    return false
  }

  updateScoreClasses() {
    if (!this.hasOurScoreTarget || !this.hasTheirScoreTarget) return

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

  updateLeadProgress() {
    const lead = this.ourScoreValue - this.theirScoreValue
    const target = this.targetScoreValue

    if (this.hasCurrentLeadTarget) {
      this.currentLeadTarget.textContent = lead.toLocaleString()
    }

    if (this.hasLeadProgressTarget) {
      const percentage = Math.min(Math.max((lead / target) * 100, 0), 100)
      this.leadProgressTarget.style.width = `${percentage}%`
      this.leadProgressTarget.classList.toggle("losing", lead < 0)
    }
  }

  startWarTimer() {
    if (!this.startedAtValue) return

    const startedAt = new Date(this.startedAtValue)
    const updateTimer = () => {
      const now = new Date()

      if (this.scheduledValue) {
        const remaining = Math.floor((startedAt - now) / 1000)
        if (remaining <= 0) {
          window.location.reload()
          return
        }
        if (this.hasWarTimerTarget) {
          this.warTimerTarget.textContent = `Starts in ${this.formatDuration(remaining)}`
        }
      } else {
        const elapsed = Math.floor((now - startedAt) / 1000)
        if (this.hasWarTimerTarget) {
          this.warTimerTarget.textContent = this.formatDuration(elapsed)
        }
      }
    }

    updateTimer()
    this.warTimerInterval = setInterval(updateTimer, 1000)
  }

  updateConnectionStatus(state, text) {
    if (!this.hasConnectionStatusTarget) return

    this.connectionStatusTarget.classList.remove("connected", "connecting", "offline")
    this.connectionStatusTarget.classList.add(state)

    const textEl = this.connectionStatusTarget.querySelector(".live-polling-text")
    if (textEl) {
      textEl.textContent = text
    }
  }

  updateLastUpdated(isoString) {
    if (!this.hasLastUpdatedTarget) return

    const date = new Date(isoString)
    const hours = date.getHours().toString().padStart(2, "0")
    const minutes = date.getMinutes().toString().padStart(2, "0")
    const seconds = date.getSeconds().toString().padStart(2, "0")
    this.lastUpdatedTarget.textContent = `Updated ${hours}:${minutes}:${seconds}`

    this.secondsUntilUpdate = this.pollIntervalValue / 1000
    this.restartCountdownInterval()
  }

  startUpdateCountdown() {
    this.updateCountdownDisplay()
    this.restartCountdownInterval()
  }

  restartCountdownInterval() {
    if (this.countdownInterval) clearInterval(this.countdownInterval)
    this.updateCountdownDisplay()
    this.countdownInterval = setInterval(() => {
      this.secondsUntilUpdate = Math.max(0, this.secondsUntilUpdate - 1)
      this.updateCountdownDisplay()
    }, 1000)
  }

  updateCountdownDisplay() {
    if (!this.hasUpdateCountdownTarget) return
    this.updateCountdownTarget.textContent = `Next update in ${this.secondsUntilUpdate}s`
  }

  toggleFilter({ currentTarget }) {
    const isActive = currentTarget.dataset.filterActive === "true"
    currentTarget.dataset.filterActive = isActive ? "false" : "true"
    currentTarget.classList.toggle("filter-disabled", isActive)
    this.applyFilters()
  }

  isFilterActive(target) {
    return target.dataset.filterActive === "true"
  }

  applyFilters() {
    if (this.hasFilterMaxStatsTarget && this.hasFilterMaxStatsLabelTarget) {
      const maxVal = parseInt(this.filterMaxStatsTarget.value)
      const sliderMax = parseInt(this.filterMaxStatsTarget.max)
      if (maxVal >= sliderMax) {
        this.filterMaxStatsLabelTarget.textContent = "No limit"
      } else {
        this.filterMaxStatsLabelTarget.textContent = this.formatStat(maxVal)
      }
    }

    this.renderTable()
  }

  getFilteredMembers(members) {
    const statusFilters = {}
    if (this.hasFilterStatusOkayTarget) statusFilters["Okay"] = this.isFilterActive(this.filterStatusOkayTarget)
    if (this.hasFilterStatusHospitalTarget) statusFilters["Hospital"] = this.isFilterActive(this.filterStatusHospitalTarget)
    if (this.hasFilterStatusJailTarget) statusFilters["Jail"] = this.isFilterActive(this.filterStatusJailTarget)
    if (this.hasFilterStatusTravelingTarget) statusFilters["Traveling"] = this.isFilterActive(this.filterStatusTravelingTarget)
    if (this.hasFilterStatusAbroadTarget) statusFilters["Abroad"] = this.isFilterActive(this.filterStatusAbroadTarget)

    const actionFilters = {}
    if (this.hasFilterActionOnlineTarget) actionFilters["Online"] = this.isFilterActive(this.filterActionOnlineTarget)
    if (this.hasFilterActionIdleTarget) actionFilters["Idle"] = this.isFilterActive(this.filterActionIdleTarget)
    if (this.hasFilterActionOfflineTarget) actionFilters["Offline"] = this.isFilterActive(this.filterActionOfflineTarget)

    let maxStats = Infinity
    if (this.hasFilterMaxStatsTarget) {
      const val = parseInt(this.filterMaxStatsTarget.value)
      const sliderMax = parseInt(this.filterMaxStatsTarget.max)
      if (val < sliderMax) maxStats = val
    }

    return members.filter(member => {
      const state = member.status?.state || "Unknown"
      if (statusFilters[state] === false) return false

      const actionStatus = member.last_action?.status || "Offline"
      if (actionFilters[actionStatus] === false) return false

      const total = member.stats?.total || 0
      if (total > 0 && total > maxStats) return false

      return true
    })
  }

  updateFilterCount(visible, total) {
    if (this.hasVisibleCountTarget) this.visibleCountTarget.textContent = visible
    if (this.hasTotalCountTarget) this.totalCountTarget.textContent = total

    if (this.hasFilterCountTarget) {
      if (visible < total) {
        this.filterCountTarget.textContent = `${total - visible} hidden`
      } else {
        this.filterCountTarget.textContent = ""
      }
    }
  }

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
    const keys = ["Name", "Level", "Status", "LastAction", "Timer", "Total", "Strength", "Defense", "Speed", "Dexterity"]

    keys.forEach(key => {
      const targetName = `sortIndicator${key}`
      const hasTarget = this[`has${targetName.charAt(0).toUpperCase() + targetName.slice(1)}Target`]
      const target = hasTarget ? this[`${targetName}Target`] : null

      if (target) {
        target.classList.remove("asc", "desc")
        const sortKeyMatch = key.charAt(0).toLowerCase() + key.slice(1)
        if (this.sortKey === sortKeyMatch) {
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

        case "lastAction":
          aVal = this.actionSortOrder(a.last_action?.status)
          bVal = this.actionSortOrder(b.last_action?.status)
          if (aVal !== bVal) return (aVal - bVal) * dir
          aVal = a.last_action?.timestamp || 0
          bVal = b.last_action?.timestamp || 0
          return (bVal - aVal) * dir

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

  actionSortOrder(status) {
    const order = { "Online": 0, "Idle": 1, "Offline": 2 }
    return order[status] ?? 3
  }

  getTimerSeconds(member) {
    const status = member.status
    if (!status) return -1

    if (status.state === "Traveling") {
      if (!status.travel_started_at || !status.destination) {
        return 999999
      }
      const flightData = FLIGHT_TIMES[status.destination]
      if (flightData) {
        const ticketTypes = PLANE_TYPE_MAP[status.plane_type] || ["standard"]
        const duration = flightData[ticketTypes[0]]
        const elapsed = Math.floor((new Date() - new Date(status.travel_started_at)) / 1000)
        const remaining = duration - elapsed
        return remaining > 0 ? remaining : -1
      }
    }

    if (!status.until) return -1
    const expiresAt = new Date(status.until)
    const remaining = Math.floor((expiresAt - new Date()) / 1000)
    return remaining > 0 ? remaining : -1
  }

  renderTable() {
    if (!this.hasMembersBodyTarget) return

    const sorted = this.getSortedMembers()
    const filtered = this.getFilteredMembers(sorted)

    this.updateFilterCount(filtered.length, sorted.length)

    const activeEdit = this.#captureActiveEdit()

    if (filtered.length === 0) {
      this.membersBodyTarget.innerHTML = `
        <tr>
          <td colspan="${this.hideStatsValue ? 6 : 11}" class="table-empty-text">${sorted.length === 0 ? "No member data available." : "No members match the current filters."}</td>
        </tr>
      `
      return
    }

    const rows = filtered.map(member => this.renderRow(member)).join("")
    this.membersBodyTarget.innerHTML = rows

    if (activeEdit) this.#restoreActiveEdit(activeEdit)
  }

  renderRow(member) {
    const status = member.status || { state: "Unknown" }
    const statusClass = this.statusCssClass(status.state)
    const rowClass = status.state === "Hospital" ? "row-hospital" : "row-okay"
    const changedClass = member._changed ? "row-updated" : ""

    const timerHtml = this.renderTimer(member)
    const lastActionHtml = this.renderLastAction(member)
    const statsHtml = this.hideStatsValue ? "" : this.renderStats(member)
    const attackUrl = `https://www.torn.com/loader.php?sid=attack&user2ID=${member.torn_id}`
    const profileUrl = `https://www.torn.com/profiles.php?XID=${member.torn_id}`

    return `
      <tr class="${rowClass} ${changedClass}" data-member-id="${member.torn_id}">
        <td>
          <a href="${profileUrl}" target="_blank" class="player-link">${this.escapeHtml(member.name || "Unknown")}</a>
        </td>
        <td class="stat-value">${member.level || "?"}</td>
        <td>
          <span class="member-status ${statusClass}">${this.escapeHtml(status.state || "Unknown")}</span>
        </td>
        <td>${lastActionHtml}</td>
        <td>${timerHtml}</td>
        ${statsHtml}
        <td>
          <a href="${attackUrl}" target="_blank" class="attack-link" title="Attack ${this.escapeHtml(member.name || "")}">
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

  renderLastAction(member) {
    const lastAction = member.last_action
    if (!lastAction?.status) return '<span class="stat-value no-data">-</span>'

    const actionClass = this.actionCssClass(lastAction.status)
    const relative = lastAction.relative || ""

    return `<span class="action-badge ${actionClass}" title="${this.escapeHtml(relative)}">${this.escapeHtml(lastAction.status)}</span>`
  }

  renderTimer(member) {
    const status = member.status
    if (!status) return '<span class="stat-value no-data">-</span>'

    if (status.state === "Traveling") {
      return this.renderTravelTimer(status)
    }

    if (status.state === "Abroad") {
      const description = status.description || ""
      const location = description.replace(/^In\s+/i, "") || "Abroad"
      return `<span class="abroad-timer" title="${this.escapeHtml(description)}">${this.escapeHtml(location)}</span>`
    }

    if (!status.until) return '<span class="stat-value no-data">-</span>'

    const expiresAt = new Date(status.until)
    const now = new Date()
    const remaining = Math.floor((expiresAt - now) / 1000)

    if (remaining <= 0) return '<span class="stat-value no-data">-</span>'

    const expiringSoon = remaining < 60
    const cssClass = expiringSoon ? "hospital-timer expiring-soon" : "hospital-timer"

    return `<span class="${cssClass}" data-timer-until="${status.until}">${this.formatCountdown(remaining)}</span>`
  }

  renderTravelTimer(status) {
    const destination = status.destination
    const description = status.description || ""
    const isReturning = description.toLowerCase().includes("returning")
    const directionPrefix = isReturning ? "\u2190 " : ""
    const directionSuffix = isReturning ? "" : " \u2192"

    if (!status.travel_started_at) {
      const destText = destination || "Unknown"
      const displayText = isReturning ? `\u2190 Torn` : `${destText} \u2192`
      return `<span class="travel-timer" title="${this.escapeHtml(description)}">${this.escapeHtml(displayText)}</span>`
    }

    const planeType = status.plane_type
    const startedAt = new Date(status.travel_started_at)

    const flightData = FLIGHT_TIMES[destination]
    if (!flightData) {
      const displayText = isReturning ? `\u2190 Torn` : `${destination} \u2192`
      return `<span class="travel-timer" title="${this.escapeHtml(description)}">${this.escapeHtml(displayText)}</span>`
    }

    const ticketTypes = PLANE_TYPE_MAP[planeType] || ["standard"]
    const now = Date.now()

    if (ticketTypes.length === 2) {
      const fastEtaMs = startedAt.getTime() + flightData[ticketTypes[0]] * 1000
      const slowEtaMs = startedAt.getTime() + flightData[ticketTypes[1]] * 1000
      const fastRemaining = Math.max(0, Math.floor((fastEtaMs - now) / 1000))
      const slowRemaining = Math.max(0, Math.floor((slowEtaMs - now) / 1000))

      const fastEta = new Date(fastEtaMs).toISOString()
      const slowEta = new Date(slowEtaMs).toISOString()

      if (slowRemaining <= 0) {
        return '<span class="travel-timer about-to-land">About to land</span>'
      }

      const fastText = fastRemaining <= 0 ? "About to land" : this.formatCountdown(fastRemaining)
      const slowText = this.formatCountdown(slowRemaining)
      const expiringSoon = fastRemaining > 0 && fastRemaining < 60

      return `<span class="travel-timer ${expiringSoon ? "expiring-soon" : ""}" data-travel-fast-eta="${fastEta}" data-travel-slow-eta="${slowEta}" data-travel-returning="${isReturning}" title="${this.escapeHtml(description)}">`
        + `<span class="travel-fast">${directionPrefix}${fastText}</span>`
        + `<span class="travel-separator"> / </span>`
        + `<span class="travel-slow">${slowText}${directionSuffix}</span>`
        + `</span>`
    } else {
      const etaMs = startedAt.getTime() + flightData[ticketTypes[0]] * 1000
      const remaining = Math.max(0, Math.floor((etaMs - now) / 1000))
      const eta = new Date(etaMs).toISOString()

      if (remaining <= 0) {
        return '<span class="travel-timer about-to-land">About to land</span>'
      }

      const expiringSoon = remaining < 60

      return `<span class="travel-timer ${expiringSoon ? "expiring-soon" : ""}" data-travel-eta="${eta}" data-travel-returning="${isReturning}" title="${this.escapeHtml(description)}">${directionPrefix}${this.formatCountdown(remaining)}${directionSuffix}</span>`
    }
  }

  renderStats(member) {
    const stats = member.stats
    const editable = this.editableStatsValue
    const fields = ["total", "strength", "defense", "speed", "dexterity"]

    if (!stats) {
      return fields.map(field => {
        const extraClass = field === "total" ? " stat-total" : ""
        if (editable) {
          return `<td class="stat-value stat-editable${extraClass} no-data" data-member-id="${member.torn_id}" data-stat-field="${field}" title="Click to enter ${field}">-</td>`
        }
        return `<td class="stat-value${extraClass} no-data">-</td>`
      }).join("")
    }

    return fields.map(field => {
      const value = stats[field]
      const extraClass = field === "total" ? " stat-total" : ""

      if (editable) {
        return `<td class="stat-value stat-editable${extraClass}" data-member-id="${member.torn_id}" data-stat-field="${field}" data-stat-raw="${value || ""}" title="Click to edit">${this.formatStat(value)}</td>`
      }
      return `<td class="stat-value${extraClass}">${this.formatStat(value)}</td>`
    }).join("")
  }

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

    const travelTimers = this.membersBodyTarget.querySelectorAll("[data-travel-eta]")
    travelTimers.forEach(el => {
      const eta = new Date(el.dataset.travelEta)
      const remaining = Math.max(0, Math.floor((eta - new Date()) / 1000))
      const isReturning = el.dataset.travelReturning === "true"
      const prefix = isReturning ? "\u2190 " : ""
      const suffix = isReturning ? "" : " \u2192"

      if (remaining <= 0) {
        el.textContent = "About to land"
        el.className = "travel-timer about-to-land"
        el.removeAttribute("data-travel-eta")
      } else {
        el.textContent = `${prefix}${this.formatCountdown(remaining)}${suffix}`
        el.className = remaining < 60 ? "travel-timer expiring-soon" : "travel-timer"
      }
    })

    const dualTimers = this.membersBodyTarget.querySelectorAll("[data-travel-fast-eta]")
    dualTimers.forEach(el => {
      const fastEta = new Date(el.dataset.travelFastEta)
      const slowEta = new Date(el.dataset.travelSlowEta)
      const now = new Date()
      const fastRemaining = Math.max(0, Math.floor((fastEta - now) / 1000))
      const slowRemaining = Math.max(0, Math.floor((slowEta - now) / 1000))
      const isReturning = el.dataset.travelReturning === "true"
      const prefix = isReturning ? "\u2190 " : ""
      const suffix = isReturning ? "" : " \u2192"

      if (slowRemaining <= 0) {
        el.textContent = "About to land"
        el.className = "travel-timer about-to-land"
        el.removeAttribute("data-travel-fast-eta")
        el.removeAttribute("data-travel-slow-eta")
      } else {
        const fastEl = el.querySelector(".travel-fast")
        const slowEl = el.querySelector(".travel-slow")
        if (fastEl) fastEl.textContent = fastRemaining <= 0 ? "About to land" : `${prefix}${this.formatCountdown(fastRemaining)}`
        if (slowEl) slowEl.textContent = `${this.formatCountdown(slowRemaining)}${suffix}`
        el.className = fastRemaining > 0 && fastRemaining < 60 ? "travel-timer expiring-soon" : "travel-timer"
      }
    })
  }

  #handleStatClick = (event) => {
    const cell = event.target.closest(".stat-editable")
    if (!cell || cell.querySelector("input")) return

    const memberId = cell.dataset.memberId
    const field = cell.dataset.statField
    const rawValue = cell.dataset.statRaw || ""

    const input = document.createElement("input")
    input.type = "text"
    input.className = "stat-edit-input"
    input.value = rawValue
    input.placeholder = "e.g. 1.5B"
    input.dataset.memberId = memberId
    input.dataset.statField = field

    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault()
        this.#saveStat(input, cell)
      } else if (e.key === "Escape") {
        e.preventDefault()
        this.#cancelEdit(cell, rawValue)
      }
    })

    input.addEventListener("blur", () => {
      setTimeout(() => {
        if (document.body.contains(input)) {
          this.#saveStat(input, cell)
        }
      }, 100)
    })

    cell.textContent = ""
    cell.appendChild(input)
    input.focus()
    input.select()
  }

  #parseStat(value) {
    if (!value || value.trim() === "") return 0

    const cleaned = value.trim().toUpperCase()
    const match = cleaned.match(/^([\d.]+)\s*([KMBT]?)$/)
    if (!match) return parseInt(cleaned.replace(/[^0-9]/g, ""), 10) || 0

    const num = parseFloat(match[1])
    const suffix = match[2]
    const multipliers = { "K": 1_000, "M": 1_000_000, "B": 1_000_000_000, "T": 1_000_000_000_000 }

    return Math.round(num * (multipliers[suffix] || 1))
  }

  async #saveStat(input, cell) {
    const memberId = input.dataset.memberId
    const field = input.dataset.statField
    const parsed = this.#parseStat(input.value)

    if (parsed <= 0) {
      this.#cancelEdit(cell, cell.dataset.statRaw || "")
      return
    }

    cell.dataset.statRaw = parsed
    cell.textContent = this.formatStat(parsed)

    const member = this.members[memberId]
    if (member) {
      if (!member.stats) member.stats = {}
      member.stats[field] = parsed
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const body = { torn_id: memberId, [field]: parsed }
      await fetch(this.statsUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify(body)
      })
    } catch {
    }

    this.renderTable()
  }

  #cancelEdit(cell, rawValue) {
    cell.textContent = rawValue ? this.formatStat(parseInt(rawValue, 10)) : "-"
  }

  #captureActiveEdit() {
    const input = this.membersBodyTarget.querySelector(".stat-edit-input")
    if (!input) return null

    return {
      memberId: input.dataset.memberId,
      field: input.dataset.statField,
      value: input.value,
      selectionStart: input.selectionStart,
      selectionEnd: input.selectionEnd
    }
  }

  #restoreActiveEdit(edit) {
    const cell = this.membersBodyTarget.querySelector(
      `.stat-editable[data-member-id="${edit.memberId}"][data-stat-field="${edit.field}"]`
    )
    if (!cell) return

    const input = document.createElement("input")
    input.type = "text"
    input.className = "stat-edit-input"
    input.value = edit.value
    input.placeholder = "e.g. 1.5B"
    input.dataset.memberId = edit.memberId
    input.dataset.statField = edit.field

    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault()
        this.#saveStat(input, cell)
      } else if (e.key === "Escape") {
        e.preventDefault()
        this.#cancelEdit(cell, cell.dataset.statRaw || "")
      }
    })

    input.addEventListener("blur", () => {
      setTimeout(() => {
        if (document.body.contains(input)) {
          this.#saveStat(input, cell)
        }
      }, 100)
    })

    cell.textContent = ""
    cell.appendChild(input)
    input.focus()
    input.setSelectionRange(edit.selectionStart, edit.selectionEnd)
  }

  statusCssClass(state) {
    const map = {
      "Okay": "status-okay",
      "Hospital": "status-hospital",
      "Jail": "status-jail",
      "Traveling": "status-traveling",
      "Abroad": "status-abroad",
      "Fallen": "status-fallen"
    }
    return map[state] || "status-unknown"
  }

  actionCssClass(status) {
    const map = {
      "Online": "action-online",
      "Idle": "action-idle",
      "Offline": "action-offline"
    }
    return map[status] || "action-offline"
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
