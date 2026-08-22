import { Dom } from "@shared/core/Dom.js";
import { Settings } from "../core/Settings.js";
import { typeName } from "../core/CompanyTypes.js";
import { ChatOpener } from "./ChatOpener.js";

const STATUS_POLL_MS = 4_000;
const STATUS_POLL_ATTEMPTS = 5;
const STATUS_COMPANIES_PER_REQUEST = 30;

export class OverviewScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
    this.statusFilter = "any";
    this.page = 0;
    this.minStats = 0;
    this.statusByPlayer = {};
  }

  subtitle() {
    const settings = Settings.get();
    const types = settings.typeIds.map(typeName).join(" + ") || "no types";
    return `${types} · ${settings.starMin}-${settings.starMax}★`;
  }

  render(container) {
    this.container = container;
    container.appendChild(this.filterRow());
    this.metaEl = Dom.el("div", "rc-meta");
    this.resultsWrap = Dom.el("div");
    container.append(this.metaEl, this.resultsWrap);
    this.fetchMatches();
  }

  filterRow() {
    const row = Dom.el("div", "rc-row rc-row--filters");

    const statusField = Dom.el("div", "rc-field rc-field--chip");
    statusField.appendChild(Dom.el("div", "rc-label", "Status"));
    this.statusChip = Dom.el("button", "rc-chip rc-chip--filter");
    this.statusChip.addEventListener("click", () => {
      const order = ["any", "online", "active"];
      this.statusFilter = order[(order.indexOf(this.statusFilter) + 1) % order.length];
      this.syncStatusChip();
      this.renderResults();
    });
    this.syncStatusChip();
    statusField.appendChild(this.statusChip);
    row.appendChild(statusField);

    const statsField = Dom.el("div", "rc-field");
    statsField.appendChild(Dom.el("div", "rc-label", "Min working stats"));
    const input = Dom.el("input", "rc-input");
    input.type = "number";
    input.min = 0;
    input.placeholder = "0";
    if (this.minStats > 0) input.value = this.minStats;
    const apply = () => {
      const value = Math.max(0, Number(input.value) || 0);
      if (value === (this.minStats || 0)) return;
      this.minStats = value;
      this.page = 0;
      this.fetchMatches();
    };
    input.addEventListener("blur", apply);
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") input.blur();
    });
    statsField.appendChild(input);
    row.appendChild(statsField);

    return row;
  }

  syncStatusChip() {
    const labels = { any: "Any", online: "Online", active: "Online + idle" };
    this.statusChip.textContent = labels[this.statusFilter];
    this.statusChip.classList.toggle("rc-chip--on", this.statusFilter !== "any");
  }

  async fetchMatches() {
    if (!this.resultsWrap) return;
    this.resultsWrap.replaceChildren(Dom.el("div", "rc-empty", "Loading matches…"));

    const settings = Settings.get();
    try {
      this.response = await this.api.matches({
        type_ids: settings.typeIds,
        star_min: settings.starMin,
        star_max: settings.starMax,
        min_stats: this.minStats || 0,
        page: this.page,
      });
    } catch (error) {
      this.resultsWrap.replaceChildren(Dom.el("div", "rc-empty", error.message));
      return;
    }

    this.renderResults();
    this.refreshStatuses();
  }

  renderResults() {
    if (!this.resultsWrap || !this.response) return;
    const { matches, total, page_size: pageSize } = this.response;
    const visible = this.filterByStatus(matches);
    const totalPages = Math.max(1, Math.ceil(total / pageSize));
    this.page = Math.min(this.page, totalPages - 1);

    this.metaEl.replaceChildren(
      Dom.el("span", null, `${total.toLocaleString()} matches · sorted by working stats`),
      Dom.el("span", "rc-dim", this.freshness())
    );

    const parts = [this.table(visible)];
    if (totalPages > 1) {
      const pager = Dom.el("div", "rc-pager");
      const prev = Dom.el("button", "rc-btn rc-btn--ghost", "‹ Prev");
      const next = Dom.el("button", "rc-btn rc-btn--ghost", "Next ›");
      prev.disabled = this.page === 0;
      next.disabled = this.page >= totalPages - 1;
      prev.addEventListener("click", () => {
        this.page -= 1;
        this.fetchMatches();
      });
      next.addEventListener("click", () => {
        this.page += 1;
        this.fetchMatches();
      });
      pager.append(prev, Dom.el("span", "rc-dim", `page ${this.page + 1} of ${totalPages}`), next);
      parts.push(pager);
    }

    this.resultsWrap.replaceChildren(...parts);
  }

  freshness() {
    const meta = this.response?.meta || {};
    const parts = [];
    if (meta.roster_synced_at) parts.push(`roster ${shortAge(Date.parse(meta.roster_synced_at))}`);
    if (meta.stats_swept_at) parts.push(`stats ${shortAge(Date.parse(meta.stats_swept_at))}`);
    return parts.join(" · ") || "no data yet — the server syncs daily";
  }

  async refreshStatuses(attempt = 0) {
    const matches = this.response?.matches || [];
    const companyIds = [...new Set(matches.map((m) => m.company.torn_id))].slice(0, STATUS_COMPANIES_PER_REQUEST);
    if (!companyIds.length) return;

    let data;
    try {
      data = await this.api.status(companyIds);
    } catch {
      return;
    }

    for (const employees of Object.values(data.statuses || {})) {
      for (const employee of employees || []) {
        this.statusByPlayer[employee.torn_id] = employee;
      }
    }
    this.renderResults();

    if (data.pending?.length && attempt < STATUS_POLL_ATTEMPTS && this.container?.isConnected) {
      setTimeout(() => this.refreshStatuses(attempt + 1), STATUS_POLL_MS);
    }
  }

  filterByStatus(matches) {
    if (this.statusFilter === "online") {
      return matches.filter((m) => this.statusByPlayer[m.torn_id]?.status === "Online");
    }
    if (this.statusFilter === "active") {
      return matches.filter((m) => {
        const status = this.statusByPlayer[m.torn_id];
        return status && status.status !== "Offline";
      });
    }
    return matches;
  }

  table(rows) {
    const table = Dom.el("div", "rc-table");
    const head = Dom.el("div", "rc-thead");
    for (const label of ["Player", "Working stats", "Status", "Company", ""]) {
      head.appendChild(Dom.el("span", null, label));
    }
    table.appendChild(head);

    if (!rows.length) {
      table.appendChild(Dom.el("div", "rc-empty", "No matches. Adjust the company types and stars in Setup — the server refreshes data daily."));
      return table;
    }

    for (const match of rows) {
      const status = this.statusByPlayer[match.torn_id];
      const row = Dom.el("div", "rc-trow");

      const who = Dom.el("div");
      const playerLink = Dom.el("a", "rc-name rc-link", match.name);
      playerLink.href = `https://www.torn.com/profiles.php?XID=${match.torn_id}`;
      playerLink.target = "_blank";
      playerLink.rel = "noopener";
      const whoDetail = Dom.el("div", "rc-dim", `Lv ${match.level} · ${match.torn_id}`);
      who.append(playerLink, whoDetail);
      if (match.faction_mate_of_director) {
        const badge = Dom.el("span", "rc-badge rc-badge--aging", "director's faction");
        badge.title = "In the same faction as the company director — probably loyal";
        who.appendChild(badge);
      }

      const ws = Dom.el("div", "rc-ws", (match.working_stats || 0).toLocaleString());

      const state = Dom.el("div", "rc-state");
      const dotClass = status?.status === "Online" ? "rc-dot--on" : status?.status === "Idle" ? "rc-dot--idle" : "rc-dot--off";
      state.append(
        Dom.el("span", `rc-dot ${dotClass}`),
        Dom.el("span", null, status ? `${status.status} · ${status.relative}` : "unknown")
      );

      const co = Dom.el("div");
      const coLink = Dom.el("a", "rc-name rc-name--co rc-link", match.company.name || "?");
      coLink.href = `https://www.torn.com/joblist.php#/p=corpinfo&ID=${match.company.torn_id}`;
      coLink.target = "_blank";
      coLink.rel = "noopener";
      coLink.appendChild(Dom.el("span", "rc-star", ` ★ ${match.company.rating}`));
      const detail = [typeName(match.company.company_type_id), status?.position, status?.days_in_company != null ? `${status.days_in_company}d` : null]
        .filter(Boolean)
        .join(" · ");
      co.append(coLink, Dom.el("div", "rc-dim", detail));

      const acts = Dom.el("div", "rc-acts");
      const chat = Dom.el("a", "rc-act");
      chat.title = "Start Torn chat";
      chat.innerHTML =
        '<svg viewBox="0 0 16 16" width="12" height="12" fill="currentColor" aria-hidden="true"><path d="M8 1.5c-4 0-7 2.6-7 5.8 0 1.8.9 3.4 2.4 4.5-.1 1-.5 1.9-1.2 2.7 1.5-.1 2.8-.6 3.8-1.3.6.2 1.3.2 2 .2 4 0 7-2.6 7-5.8s-3-6.1-7-6.1z"/></svg>';
      chat.href = ChatOpener.chatUrl(match.torn_id);
      chat.target = "_blank";
      chat.rel = "noopener";
      acts.appendChild(chat);

      row.append(who, ws, state, co, acts);
      table.appendChild(row);
    }
    return table;
  }
}

function shortAge(fetchedAt) {
  if (!fetchedAt) return "";
  const minutes = Math.floor((Date.now() - fetchedAt) / 60_000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 48) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}
