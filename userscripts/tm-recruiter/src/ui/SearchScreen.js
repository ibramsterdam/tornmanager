import { Dom } from "@shared/core/Dom.js";
import { Settings, STAR_RANGE } from "../core/Settings.js";
import { COMPANY_TYPES, typeName } from "../core/CompanyTypes.js";
import { ChatOpener } from "./ChatOpener.js";

const STATUS_POLL_MS = 4_000;
const STATUS_POLL_ATTEMPTS = 5;
const STATUS_COMPANIES_PER_REQUEST = 30;
const SECONDS_PER_COMPANY = 2.5;

export class SearchScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
    this.statusFilter = "any";
    this.page = 0;
    this.minStats = 0;
    this.filtersOpen = false;
    this.excludeFactionMates = false;
    this.statusByPlayer = {};
    this.statusRefresh = null;
  }

  subtitle() {
    const settings = Settings.get();
    const types = settings.typeIds.map(typeName).join(" + ") || "no types";
    return `${types} · ${settings.starMin}-${settings.starMax}★`;
  }

  render(container) {
    this.container = container;
    container.appendChild(this.filterRow());
    this.filtersCard = this.buildFiltersCard();
    container.appendChild(this.filtersCard);
    this.metaEl = Dom.el("div", "rc-meta");
    this.resultsWrap = Dom.el("div");
    container.append(this.metaEl, this.resultsWrap);
    this.syncFiltersChip();
    this.fetchMatches();
  }

  filterRow() {
    const row = Dom.el("div", "rc-row rc-row--filters");

    const filtersField = Dom.el("div", "rc-field rc-field--chip");
    filtersField.appendChild(Dom.el("div", "rc-label", "Companies"));
    this.filtersChip = Dom.el("button", "rc-chip rc-chip--filter");
    this.filtersChip.addEventListener("click", () => {
      this.filtersOpen = !this.filtersOpen;
      this.syncFiltersChip();
    });
    filtersField.appendChild(this.filtersChip);
    row.appendChild(filtersField);

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

    const loyaltyField = Dom.el("div", "rc-field rc-field--chip");
    loyaltyField.appendChild(Dom.el("div", "rc-label", "Faction mates"));
    this.loyaltyChip = Dom.el("button", "rc-chip rc-chip--filter");
    this.loyaltyChip.title = "Hide players who share a faction with their company director";
    this.loyaltyChip.addEventListener("click", () => {
      this.excludeFactionMates = !this.excludeFactionMates;
      this.page = 0;
      this.syncLoyaltyChip();
      this.fetchMatches();
    });
    this.syncLoyaltyChip();
    loyaltyField.appendChild(this.loyaltyChip);
    row.appendChild(loyaltyField);

    return row;
  }

  syncLoyaltyChip() {
    this.loyaltyChip.textContent = this.excludeFactionMates ? "Hidden" : "Shown";
    this.loyaltyChip.classList.toggle("rc-chip--on", this.excludeFactionMates);
  }

  syncStatusChip() {
    const labels = { any: "Any", online: "Online", active: "Online + idle" };
    this.statusChip.textContent = labels[this.statusFilter];
    this.statusChip.classList.toggle("rc-chip--on", this.statusFilter !== "any");
  }

  syncFiltersChip() {
    const settings = Settings.get();
    const count = settings.typeIds.length;
    this.filtersChip.textContent = `${count} ${count === 1 ? "type" : "types"} · ${settings.starMin}-${settings.starMax}★`;
    this.filtersChip.classList.toggle("rc-chip--on", this.filtersOpen);
    if (this.filtersCard) this.filtersCard.classList.toggle("rc-filters--open", this.filtersOpen);
  }

  buildFiltersCard() {
    const settings = Settings.get();
    const selected = new Set(settings.typeIds);

    const card = Dom.el("div", "rc-card rc-filters");
    if (this.filtersOpen) card.classList.add("rc-filters--open");
    const inner = Dom.el("div", "rc-filters-inner");
    card.appendChild(inner);

    inner.appendChild(Dom.el("div", "rc-label", "Company types to search"));
    const chips = Dom.el("div", "rc-chips");
    for (const type of COMPANY_TYPES) {
      const chip = Dom.el("button", "rc-chip", type.name);
      if (selected.has(type.id)) chip.classList.add("rc-chip--on");
      chip.addEventListener("click", () => {
        if (selected.has(type.id)) {
          selected.delete(type.id);
        } else {
          selected.add(type.id);
        }
        chip.classList.toggle("rc-chip--on");
        Settings.set({ typeIds: [...selected].sort((a, b) => a - b) });
        this.page = 0;
        this.syncFiltersChip();
        this.overlay.refresh();
      });
      chips.appendChild(chip);
    }
    inner.appendChild(chips);

    const row = Dom.el("div", "rc-row rc-filters-stars");
    row.appendChild(
      this.stepper("Min stars", settings.starMin, STAR_RANGE.min, settings.starMax, (value) => {
        Settings.set({ starMin: value });
      })
    );
    row.appendChild(
      this.stepper("Max stars", settings.starMax, settings.starMin, STAR_RANGE.max, (value) => {
        Settings.set({ starMax: value });
      })
    );
    const hint = Dom.el("div", "rc-field rc-filters-hint");
    hint.appendChild(Dom.el("div", "rc-hint", `The server collects working stats for ${STAR_RANGE.min}★ companies and up, refreshed daily.`));
    row.appendChild(hint);
    inner.appendChild(row);
    return card;
  }

  stepper(labelText, value, min, max, onChange) {
    const wrap = Dom.el("div", "rc-field");
    wrap.appendChild(Dom.el("div", "rc-label", labelText));

    const control = Dom.el("div", "rc-stepper");
    const minus = Dom.el("button", "rc-stepper-btn", "−");
    const display = Dom.el("span", "rc-stepper-value", String(value));
    const plus = Dom.el("button", "rc-stepper-btn", "+");

    const apply = (next) => {
      onChange(next);
      this.page = 0;
      this.overlay.refresh();
    };
    minus.addEventListener("click", () => {
      if (value > min) apply(value - 1);
    });
    plus.addEventListener("click", () => {
      if (value < max) apply(value + 1);
    });
    minus.disabled = value <= min;
    plus.disabled = value >= max;

    control.append(minus, display, plus);
    wrap.appendChild(control);
    return wrap;
  }

  async fetchMatches() {
    if (!this.resultsWrap) return;
    this.resultsWrap.replaceChildren(Dom.el("div", "rc-empty", "Loading matches…"));

    const settings = Settings.get();
    try {
      const filters = {
        type_ids: settings.typeIds,
        star_min: settings.starMin,
        star_max: settings.starMax,
        min_stats: this.minStats || 0,
        page: this.page,
      };
      if (this.excludeFactionMates) filters.exclude_faction_mates = true;
      this.response = await this.api.matches(filters);
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

    this.renderMeta(total);

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

  renderMeta(total) {
    const right = Dom.el("div", "rc-meta-right");
    if (this.statusRefresh) {
      const { total: refreshTotal, pending } = this.statusRefresh;
      const eta = Math.ceil(pending * SECONDS_PER_COMPANY);
      right.appendChild(
        Dom.el("span", "rc-dim", `Refreshing status · ${refreshTotal - pending} of ${refreshTotal} companies · ~${eta}s left`)
      );
    } else {
      right.appendChild(Dom.el("span", "rc-dim", this.freshness()));
      const refresh = Dom.el("button", "rc-btn rc-btn--ghost rc-btn--sm", "↻ Refresh status");
      refresh.title = "Fetch the live online state of every company in these results";
      refresh.disabled = !(this.response?.matches || []).length;
      refresh.addEventListener("click", () => this.forceRefreshStatus());
      right.appendChild(refresh);
    }

    this.metaEl.replaceChildren(
      Dom.el("span", null, `${total.toLocaleString()} matches · sorted by working stats`),
      right
    );
  }

  freshness() {
    const meta = this.response?.meta || {};
    const parts = [];
    if (meta.roster_synced_at) parts.push(`roster ${shortAge(Date.parse(meta.roster_synced_at))}`);
    if (meta.stats_swept_at) parts.push(`stats ${shortAge(Date.parse(meta.stats_swept_at))}`);
    return parts.join(" · ") || "no data yet — the server syncs daily";
  }

  pageCompanyIds() {
    const matches = this.response?.matches || [];
    return [...new Set(matches.map((m) => m.company.torn_id))];
  }

  companyChunks() {
    const ids = this.pageCompanyIds();
    const chunks = [];
    for (let i = 0; i < ids.length; i += STATUS_COMPANIES_PER_REQUEST) {
      chunks.push(ids.slice(i, i + STATUS_COMPANIES_PER_REQUEST));
    }
    return chunks;
  }

  async statusForAllChunks({ refresh = false } = {}) {
    let pending = 0;
    for (const chunk of this.companyChunks()) {
      const data = await this.api.status(chunk, { refresh });
      this.applyStatuses(data);
      pending += data.pending?.length || 0;
    }
    return pending;
  }

  applyStatuses(data) {
    for (const employees of Object.values(data.statuses || {})) {
      for (const employee of employees || []) {
        this.statusByPlayer[employee.torn_id] = employee;
      }
    }
  }

  async refreshStatuses(attempt = 0) {
    if (!this.pageCompanyIds().length || this.statusRefresh) return;

    let pending;
    try {
      pending = await this.statusForAllChunks();
    } catch {
      return;
    }

    this.renderResults();

    if (pending > 0 && attempt < STATUS_POLL_ATTEMPTS && this.container?.isConnected) {
      setTimeout(() => this.refreshStatuses(attempt + 1), STATUS_POLL_MS);
    }
  }

  async forceRefreshStatus() {
    const total = this.pageCompanyIds().length;
    if (!total || this.statusRefresh) return;

    this.statusRefresh = { total, pending: total };
    this.renderResults();

    try {
      await this.statusForAllChunks({ refresh: true });
      await this.pollStatusRefresh(total);
    } catch {
      return;
    } finally {
      this.statusRefresh = null;
      if (this.container?.isConnected) this.renderResults();
    }
  }

  async pollStatusRefresh(total) {
    const maxAttempts = Math.ceil((total * SECONDS_PER_COMPANY * 1000) / STATUS_POLL_MS) + 10;

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      if (!this.container?.isConnected) return;
      await sleep(STATUS_POLL_MS);

      let pending;
      try {
        pending = await this.statusForAllChunks();
      } catch {
        continue;
      }

      this.statusRefresh = { total, pending };
      this.renderResults();
      if (pending === 0) return;
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
      table.appendChild(Dom.el("div", "rc-empty", "No matches. Adjust the company types and stars in the filters above — the server refreshes data daily."));
      return table;
    }

    for (const match of rows) {
      const status = this.statusByPlayer[match.torn_id];
      const row = Dom.el("div", "rc-trow");

      const who = Dom.el("div");
      const playerLink = Dom.el("a", "rc-name rc-link", match.name);
      playerLink.href = `/profiles.php?XID=${match.torn_id}`;
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

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
