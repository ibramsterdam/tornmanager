// Sort orders and travel timing ported from app/javascript/controllers/war_dashboard_controller.js.
const FLIGHT_TIMES = {
  "Mexico":         { standard: 1560,  airstrip: 1080,  wlt: 780,  bct: 480 },
  "Cayman Islands": { standard: 2100,  airstrip: 1500,  wlt: 1080, bct: 660 },
  "Canada":         { standard: 2460,  airstrip: 1740,  wlt: 1200, bct: 720 },
  "Hawaii":         { standard: 8040,  airstrip: 5640,  wlt: 4020, bct: 2400 },
  "United Kingdom": { standard: 9540,  airstrip: 6660,  wlt: 4800, bct: 2880 },
  "Argentina":      { standard: 10020, airstrip: 7020,  wlt: 4980, bct: 3000 },
  "Switzerland":    { standard: 10500, airstrip: 7380,  wlt: 5280, bct: 3180 },
  "Japan":          { standard: 13500, airstrip: 9480,  wlt: 6780, bct: 4080 },
  "China":          { standard: 14520, airstrip: 10140, wlt: 7260, bct: 4320 },
  "UAE":            { standard: 16260, airstrip: 11400, wlt: 8100, bct: 4860 },
  "South Africa":   { standard: 17820, airstrip: 12480, wlt: 8940, bct: 5340 },
};

const PLANE_TYPE_MAP = {
  private_jet: ["wlt"],
  light_aircraft: ["airstrip"],
  airliner: ["bct", "standard"],
};

const STATUS_ORDER = { Okay: 0, Traveling: 1, Jail: 2, Hospital: 3, Fallen: 4 };
const ACTION_ORDER = { Online: 0, Idle: 1, Offline: 2 };

const STATUS_CLASSES = {
  Okay: "tm-status--okay",
  Hospital: "tm-status--hospital",
  Jail: "tm-status--jail",
  Traveling: "tm-status--traveling",
  Abroad: "tm-status--abroad",
};

const ACTION_CLASSES = {
  Online: "tm-action--online",
  Idle: "tm-action--idle",
  Offline: "tm-action--offline",
};

const COLUMNS = [
  { key: "name", label: "Name" },
  { key: "status", label: "Status" },
  { key: "activity", label: "Activity" },
  {
    key: "timer",
    label: "Timer",
    title: "Hospital/Jail: time until release. Travel: estimated arrival based on destination and plane type.",
  },
  { key: null, label: "" },
];

export class TargetTable {
  constructor({ onRemove }) {
    this.onRemove = onRemove;
    this.rows = [];
    this.sortKey = "status";
    this.sortDirection = "asc";
    this.sortHeaders = {};
    this.tickInterval = null;
  }

  render() {
    const wrap = document.createElement("div");
    wrap.className = "tm-tt-wrap";

    const table = document.createElement("table");
    table.className = "tm-tt";

    const thead = document.createElement("thead");
    const headRow = document.createElement("tr");

    for (const column of COLUMNS) {
      const th = document.createElement("th");
      if (column.title) th.title = column.title;

      if (column.key) {
        th.className = "tm-tt-sortable";
        th.textContent = `${column.label} `;

        const arrow = document.createElement("span");
        arrow.className = "tm-tt-arrow";
        arrow.textContent = "▾";
        th.appendChild(arrow);

        th.onclick = () => this.sort(column.key);
        this.sortHeaders[column.key] = th;
      }

      headRow.appendChild(th);
    }

    thead.appendChild(headRow);
    table.appendChild(thead);

    this.tbody = document.createElement("tbody");
    this.tbody.addEventListener("click", (e) => {
      const button = e.target.closest(".tm-tt-remove");
      if (button) this.onRemove(parseInt(button.dataset.id, 10));
    });
    table.appendChild(this.tbody);

    wrap.appendChild(table);

    this.updateSortIndicators();
    this.tickInterval = setInterval(() => this.tickTimers(), 1000);

    return wrap;
  }

  destroy() {
    if (this.tickInterval) {
      clearInterval(this.tickInterval);
      this.tickInterval = null;
    }
  }

  update(rows) {
    this.rows = rows;
    this.renderBody();
  }

  sort(key) {
    if (this.sortKey === key) {
      this.sortDirection = this.sortDirection === "asc" ? "desc" : "asc";
    } else {
      this.sortKey = key;
      this.sortDirection = "asc";
    }

    this.updateSortIndicators();
    this.renderBody();
  }

  updateSortIndicators() {
    for (const [key, th] of Object.entries(this.sortHeaders)) {
      th.classList.toggle("tm-tt-sort-active", key === this.sortKey);
      th.classList.toggle("tm-tt-sort-asc", key === this.sortKey && this.sortDirection === "asc");
    }
  }

  renderBody() {
    if (!this.tbody) return;

    const sorted = [...this.rows].sort((a, b) => this.compare(a, b));
    this.tbody.innerHTML = sorted.map((row) => this.renderRow(row)).join("");
  }

  compare(a, b) {
    const dir = this.sortDirection === "asc" ? 1 : -1;

    switch (this.sortKey) {
      case "name": {
        const aVal = (a.member?.name || `ID ${a.id}`).toLowerCase();
        const bVal = (b.member?.name || `ID ${b.id}`).toLowerCase();
        return aVal < bVal ? -1 * dir : aVal > bVal ? 1 * dir : 0;
      }
      case "status": {
        const aVal = a.member ? STATUS_ORDER[a.member.status?.state] ?? 5 : 6;
        const bVal = b.member ? STATUS_ORDER[b.member.status?.state] ?? 5 : 6;
        return (aVal - bVal) * dir;
      }
      case "activity": {
        const aVal = a.member ? ACTION_ORDER[a.member.last_action?.status] ?? 3 : 4;
        const bVal = b.member ? ACTION_ORDER[b.member.last_action?.status] ?? 3 : 4;
        if (aVal !== bVal) return (aVal - bVal) * dir;
        const aTime = a.member?.last_action?.timestamp || 0;
        const bTime = b.member?.last_action?.timestamp || 0;
        return (bTime - aTime) * dir;
      }
      case "timer": {
        const aVal = a.member ? this.getTimerSeconds(a.member) : -1;
        const bVal = b.member ? this.getTimerSeconds(b.member) : -1;
        return (aVal - bVal) * dir;
      }
      default:
        return 0;
    }
  }

  getTimerSeconds(member) {
    const status = member.status;
    if (!status) return -1;

    if (status.state === "Traveling") {
      if (!status.travel_started_at || !status.destination) return 999999;

      const flightData = FLIGHT_TIMES[status.destination];
      if (flightData) {
        const ticketTypes = PLANE_TYPE_MAP[status.plane_type] || ["standard"];
        const duration = flightData[ticketTypes[0]];
        const elapsed = Math.floor((Date.now() - new Date(status.travel_started_at)) / 1000);
        const remaining = duration - elapsed;
        return remaining > 0 ? remaining : -1;
      }
    }

    if (!status.until) return -1;
    const remaining = Math.floor((new Date(status.until) - Date.now()) / 1000);
    return remaining > 0 ? remaining : -1;
  }

  renderRow({ id, member }) {
    const attackUrl = `https://www.torn.com/loader.php?sid=attack&user2ID=${id}`;
    const removeCell = `<td class="tm-tt-remove-cell"><button type="button" class="tm-tt-remove" data-id="${id}" title="Remove target">×</button></td>`;

    if (!member) {
      return `
        <tr>
          <td><a href="${attackUrl}" class="tm-tt-name tm-tt-name--unknown" title="Not in the current war data">ID ${id}</a></td>
          <td><span class="tm-tt-nodata">-</span></td>
          <td><span class="tm-tt-nodata">-</span></td>
          <td><span class="tm-tt-nodata">-</span></td>
          ${removeCell}
        </tr>`;
    }

    const status = member.status || { state: "Unknown" };
    const statusClass = STATUS_CLASSES[status.state] || "tm-status--unknown";
    const name = this.escapeHtml(member.name || `ID ${id}`);

    return `
      <tr>
        <td><a href="${attackUrl}" class="tm-tt-name" title="Attack ${name}">${name}</a></td>
        <td><span class="tm-status ${statusClass}">${this.escapeHtml(status.state || "Unknown")}</span></td>
        <td>${this.renderActivity(member)}</td>
        <td>${this.renderTimer(member)}</td>
        ${removeCell}
      </tr>`;
  }

  renderActivity(member) {
    const lastAction = member.last_action;
    if (!lastAction?.status) return '<span class="tm-tt-nodata">-</span>';

    const actionClass = ACTION_CLASSES[lastAction.status] || "tm-action--offline";
    return `<span class="tm-action ${actionClass}" title="${this.escapeHtml(lastAction.relative || "")}">${this.escapeHtml(lastAction.status)}</span>`;
  }

  renderTimer(member) {
    const status = member.status;
    if (!status) return '<span class="tm-tt-nodata">-</span>';

    if (status.state === "Traveling") return this.renderTravelTimer(status);

    if (status.state === "Abroad") {
      const description = status.description || "";
      const location = description.replace(/^In\s+/i, "") || "Abroad";
      return `<span class="tm-timer tm-timer--abroad" title="${this.escapeHtml(description)}">${this.escapeHtml(location)}</span>`;
    }

    if (!status.until) return '<span class="tm-tt-nodata">-</span>';

    const remaining = Math.floor((new Date(status.until) - Date.now()) / 1000);
    if (remaining <= 0) return '<span class="tm-tt-nodata">-</span>';

    const soonClass = remaining < 60 ? " tm-timer--soon" : "";
    return `<span class="tm-timer tm-timer--hospital${soonClass}" data-timer-until="${status.until}">${this.formatCountdown(remaining)}</span>`;
  }

  renderTravelTimer(status) {
    const destination = status.destination;
    const description = status.description || "";
    const isReturning = status.returning === true || description.toLowerCase().includes("returning");
    const prefix = isReturning ? "← " : "";
    const suffix = isReturning ? "" : " →";

    const flightData = FLIGHT_TIMES[destination];
    if (!status.travel_started_at || !flightData) {
      const displayText = isReturning ? "← Torn" : `${destination || "Unknown"} →`;
      return `<span class="tm-timer tm-timer--travel" title="${this.escapeHtml(description)}">${this.escapeHtml(displayText)}</span>`;
    }

    const ticketTypes = PLANE_TYPE_MAP[status.plane_type] || ["standard"];
    const startedAt = new Date(status.travel_started_at).getTime();
    const now = Date.now();

    if (ticketTypes.length === 2) {
      const fastEtaMs = startedAt + flightData[ticketTypes[0]] * 1000;
      const slowEtaMs = startedAt + flightData[ticketTypes[1]] * 1000;
      const fastRemaining = Math.max(0, Math.floor((fastEtaMs - now) / 1000));
      const slowRemaining = Math.max(0, Math.floor((slowEtaMs - now) / 1000));

      if (slowRemaining <= 0) return '<span class="tm-timer tm-timer--landing">About to land</span>';

      const fastText = fastRemaining <= 0 ? "About to land" : this.formatCountdown(fastRemaining);
      const soonClass = fastRemaining > 0 && fastRemaining < 60 ? " tm-timer--soon" : "";

      return `<span class="tm-timer tm-timer--travel${soonClass}" data-travel-fast-eta="${new Date(fastEtaMs).toISOString()}" data-travel-slow-eta="${new Date(slowEtaMs).toISOString()}" data-travel-returning="${isReturning}" title="${this.escapeHtml(description)}">`
        + `<span class="tm-tt-travel-fast">${prefix}${fastText}</span>`
        + `<span class="tm-timer-sep"> / </span>`
        + `<span class="tm-tt-travel-slow">${this.formatCountdown(slowRemaining)}${suffix}</span>`
        + `</span>`;
    }

    const etaMs = startedAt + flightData[ticketTypes[0]] * 1000;
    const remaining = Math.max(0, Math.floor((etaMs - now) / 1000));

    if (remaining <= 0) return '<span class="tm-timer tm-timer--landing">About to land</span>';

    const soonClass = remaining < 60 ? " tm-timer--soon" : "";
    return `<span class="tm-timer tm-timer--travel${soonClass}" data-travel-eta="${new Date(etaMs).toISOString()}" data-travel-returning="${isReturning}" title="${this.escapeHtml(description)}">${prefix}${this.formatCountdown(remaining)}${suffix}</span>`;
  }

  tickTimers() {
    if (!this.tbody) return;

    this.tbody.querySelectorAll("[data-timer-until]").forEach((el) => {
      const remaining = Math.floor((new Date(el.dataset.timerUntil) - Date.now()) / 1000);

      if (remaining <= 0) {
        el.textContent = "-";
        el.className = "tm-tt-nodata";
        el.removeAttribute("data-timer-until");
      } else {
        el.textContent = this.formatCountdown(remaining);
        el.className = remaining < 60 ? "tm-timer tm-timer--hospital tm-timer--soon" : "tm-timer tm-timer--hospital";
      }
    });

    this.tbody.querySelectorAll("[data-travel-eta]").forEach((el) => {
      const remaining = Math.max(0, Math.floor((new Date(el.dataset.travelEta) - Date.now()) / 1000));
      const isReturning = el.dataset.travelReturning === "true";

      if (remaining <= 0) {
        el.textContent = "About to land";
        el.className = "tm-timer tm-timer--landing";
        el.removeAttribute("data-travel-eta");
      } else {
        el.textContent = `${isReturning ? "← " : ""}${this.formatCountdown(remaining)}${isReturning ? "" : " →"}`;
        el.className = remaining < 60 ? "tm-timer tm-timer--travel tm-timer--soon" : "tm-timer tm-timer--travel";
      }
    });

    this.tbody.querySelectorAll("[data-travel-fast-eta]").forEach((el) => {
      const now = Date.now();
      const fastRemaining = Math.max(0, Math.floor((new Date(el.dataset.travelFastEta) - now) / 1000));
      const slowRemaining = Math.max(0, Math.floor((new Date(el.dataset.travelSlowEta) - now) / 1000));
      const isReturning = el.dataset.travelReturning === "true";

      if (slowRemaining <= 0) {
        el.textContent = "About to land";
        el.className = "tm-timer tm-timer--landing";
        el.removeAttribute("data-travel-fast-eta");
        el.removeAttribute("data-travel-slow-eta");
      } else {
        const fastEl = el.querySelector(".tm-tt-travel-fast");
        const slowEl = el.querySelector(".tm-tt-travel-slow");
        const prefix = isReturning ? "← " : "";
        const suffix = isReturning ? "" : " →";
        if (fastEl) fastEl.textContent = fastRemaining <= 0 ? "About to land" : `${prefix}${this.formatCountdown(fastRemaining)}`;
        if (slowEl) slowEl.textContent = `${this.formatCountdown(slowRemaining)}${suffix}`;
        el.className = fastRemaining > 0 && fastRemaining < 60 ? "tm-timer tm-timer--travel tm-timer--soon" : "tm-timer tm-timer--travel";
      }
    });
  }

  formatCountdown(totalSeconds) {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    if (hours > 0) return `${hours}h ${minutes}m ${seconds}s`;
    return `${minutes}m ${seconds}s`;
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
}
