import { Dom } from "../core/Dom.js";
import { Settings } from "../core/Settings.js";
import { typeName } from "../core/CompanyTypes.js";
import { ChatOpener } from "./ChatOpener.js";

const PAGE_SIZE = 100;

export class OverviewScreen {
  constructor({ roster, stats, status, api, overlay }) {
    this.roster = roster;
    this.stats = stats;
    this.status = status;
    this.api = api;
    this.overlay = overlay;
    this.running = null;
    this.stopRequested = false;
    this.statusFilter = "any";
    this.page = 0;
  }

  subtitle() {
    const settings = Settings.get();
    const types = settings.typeIds.map(typeName).join(" + ") || "no types";
    return `${types} · ${settings.starMin}-${settings.starMax}★`;
  }

  render(container) {
    this.container = container;
    const settings = Settings.get();
    const matches = this.matches(settings);

    container.appendChild(this.syncRows(matches));
    this.progress = Dom.el("div", "rc-progress");
    container.appendChild(this.progress);
    if (this.barState) this.renderBar();

    container.appendChild(this.filterRow());
    this.resultsWrap = Dom.el("div");
    container.appendChild(this.resultsWrap);
    this.renderResults();
  }

  filterRow() {
    const row = Dom.el("div", "rc-row rc-row--filters");

    const statusField = Dom.el("div", "rc-field rc-field--chip");
    statusField.appendChild(Dom.el("div", "rc-label", "Status"));
    this.statusChip = Dom.el("button", "rc-chip rc-chip--filter");
    this.statusChip.addEventListener("click", () => {
      const order = ["any", "online", "active"];
      this.statusFilter = order[(order.indexOf(this.statusFilter) + 1) % order.length];
      this.page = 0;
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
      this.renderResults();
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

  renderResults() {
    if (!this.resultsWrap) return;
    const matches = this.matches(Settings.get());
    const visible = this.filterByStatus(matches).filter((m) => m.stat.v >= (this.minStats || 0));

    const totalPages = Math.max(1, Math.ceil(visible.length / PAGE_SIZE));
    this.page = Math.min(Math.max(0, this.page), totalPages - 1);

    const meta = Dom.el("div", "rc-meta");
    meta.append(
      Dom.el("span", null, `${visible.length} of ${matches.length} matches shown`),
      Dom.el("span", "rc-dim", "sorted by working stats")
    );

    const parts = [meta, this.table(visible.slice(this.page * PAGE_SIZE, (this.page + 1) * PAGE_SIZE))];

    if (totalPages > 1) {
      const pager = Dom.el("div", "rc-pager");
      const prev = Dom.el("button", "rc-btn rc-btn--ghost", "‹ Prev");
      const next = Dom.el("button", "rc-btn rc-btn--ghost", "Next ›");
      prev.disabled = this.page === 0;
      next.disabled = this.page >= totalPages - 1;
      prev.addEventListener("click", () => {
        this.page -= 1;
        this.renderResults();
      });
      next.addEventListener("click", () => {
        this.page += 1;
        this.renderResults();
      });
      pager.append(prev, Dom.el("span", "rc-dim", `page ${this.page + 1} of ${totalPages}`), next);
      parts.push(pager);
    }

    this.resultsWrap.replaceChildren(...parts);
  }

  syncRows(matches) {
    const wrap = Dom.el("div", "rc-syncs");
    const companyCount = new Set(matches.map((m) => m.player.companyId)).size;
    const capacity = Math.max(1, this.api.capacityPerWindow());

    wrap.appendChild(this.syncRow({
      name: "Roster",
      desc: "who works where, ratings · 2 calls",
      fetchedAt: this.roster.data?.fetchedAt,
      staleAfterHours: 24,
      action: () => this.updateRoster(),
    }));

    let statsDesc = "needs a roster update first";
    if (this.roster.data) {
      const players = this.roster.data.players.filter((p) => !p.director);
      const stale = this.stats.stalePlayers(players).length;
      if (stale === 0) {
        statsDesc = `all ${players.length.toLocaleString()} employees fresh (10 day cache)`;
      } else {
        const minutes = Math.max(1, Math.ceil(stale / capacity));
        statsDesc = `${stale.toLocaleString()} of ${players.length.toLocaleString()} employees to fetch · ~${minutes} min`;
      }
    }
    wrap.appendChild(this.syncRow({
      name: "Working stats",
      desc: statsDesc,
      fetchedAt: this.stats.data?.fetchedAt,
      staleAfterHours: 24 * 10,
      action: () => this.updateStats(),
    }));

    wrap.appendChild(this.syncRow({
      name: "Status",
      desc: `online state of ${matches.length} matches · ${companyCount} calls`,
      fetchedAt: this.status.data?.fetchedAt,
      staleAfterHours: 1,
      action: () => this.updateStatus(matches),
    }));
    return wrap;
  }

  syncRow({ name, desc, fetchedAt, staleAfterHours, action }) {
    const row = Dom.el("div", "rc-sync");
    const isRunning = this.running === name;
    const button = Dom.el("button", "rc-btn rc-btn--ghost", isRunning ? "Pause" : "Update");
    button.disabled = !!this.running && !isRunning;

    button.addEventListener("click", async () => {
      if (this.running === name) {
        this.stopRequested = true;
        button.textContent = "Pausing…";
        button.disabled = true;
        return;
      }
      if (this.running) return;

      this.running = name;
      this.stopRequested = false;
      button.textContent = "Pause";

      let message = null;
      let paused = false;
      try {
        message = await action();
      } catch (error) {
        this.setProgress(`${name} failed: ${error.message}`);
        return;
      } finally {
        paused = this.stopRequested;
        this.running = null;
        this.stopRequested = false;
        this.stopTicker();
        this.barState = null;
      }
      this.overlay.refresh();
      this.setProgress(paused ? `${name} paused, progress so far is saved.` : message || "");
    });

    row.append(
      Dom.el("span", "rc-sync-name", name),
      Dom.el("span", "rc-dim", desc),
      ageBadge(fetchedAt, staleAfterHours),
      button
    );
    return row;
  }

  async updateRoster() {
    await this.roster.update(Settings.get(), { onProgress: (text) => this.setProgress(text) });
    return "Roster updated.";
  }

  async updateStats() {
    const roster = this.roster.data;
    if (!roster) return "Update the roster first, stats are fetched for the employees in your tracked companies.";

    const players = roster.players.filter((p) => !p.director);
    const staleCount = this.stats.stalePlayers(players).length;

    await this.stats.run(players, {
      shouldStop: () => this.stopRequested,
      onProgress: (done, total) => this.setBar({ done, total, unit: "employees" }),
    });
    return staleCount
      ? `Working stats fetched for ${staleCount.toLocaleString()} employees (${(players.length - staleCount).toLocaleString()} were still fresh).`
      : "All employees were already fresh, nothing to fetch.";
  }

  async updateStatus(matches) {
    const companyIds = [...new Set(matches.map((m) => m.player.companyId))];
    if (!companyIds.length) return "No matches yet. Update the roster and working stats first.";

    await this.status.refresh(companyIds, {
      shouldStop: () => this.stopRequested,
      onProgress: (done, total) => this.setBar({ done, total, unit: "companies" }),
    });
    return `Status refreshed for ${companyIds.length} companies.`;
  }

  setProgress(text) {
    this.stopTicker();
    this.barState = null;
    if (this.progress) this.progress.textContent = text;
  }

  setBar({ done, total, unit }) {
    this.barState = { done, total, unit, at: Date.now() };
    if (!this.ticker) this.ticker = setInterval(() => this.renderBar(), 1000);
    this.renderBar();
  }

  stopTicker() {
    if (this.ticker) {
      clearInterval(this.ticker);
      this.ticker = null;
    }
  }

  renderBar() {
    if (!this.progress || !this.barState) return;
    const { done, total, unit, at } = this.barState;

    if (!this.barEl?.isConnected || this.barEl.parentElement !== this.progress) {
      this.barEl = Dom.el("div", "rc-bar");
      this.barFill = Dom.el("div", "rc-bar-fill");
      this.barText = Dom.el("span", "rc-bar-text");
      this.barEl.append(this.barFill, this.barText);
      this.progress.replaceChildren(this.barEl);
    }

    // Calls land in one burst per minute-window; between bursts the counter
    // advances at the pool's average rate and snaps to the real number on
    // every progress event.
    const ratePerSecond = Math.max(1, this.api.capacityPerWindow()) / 60;
    const elapsed = (Date.now() - at) / 1000;
    const displayed = Math.min(total, Math.floor(done + ratePerSecond * elapsed));

    const fraction = total ? displayed / total : 1;
    this.barFill.style.width = `${Math.min(97, Math.max(3, fraction * 100)).toFixed(1)}%`;

    const remaining = (total - displayed) / ratePerSecond;
    const countdown = remaining < 1 ? "any moment now" : `~${formatDuration(remaining)} left`;
    this.barText.textContent = `${countdown} · ${displayed.toLocaleString()} of ${total.toLocaleString()} ${unit} fetched`;
  }

  matches(settings) {
    const roster = this.roster.data;
    const stats = this.stats.data?.byId || {};
    const statuses = this.status.data?.byId || {};
    if (!roster) return [];

    const cutoff = Date.now() / 1000 - settings.inactiveDays * 86_400;
    const result = [];
    for (const player of roster.players) {
      if (player.director) continue;
      const stat = stats[player.id];
      if (!stat || !(stat.v > 0)) continue;
      const status = statuses[player.id];
      const lastAction = status?.timestamp || stat.la;
      if (lastAction && lastAction < cutoff) continue;
      result.push({ player, company: roster.companies[player.companyId], stat, status });
    }
    return result.sort((a, b) => b.stat.v - a.stat.v);
  }

  filterByStatus(matches) {
    if (this.statusFilter === "online") return matches.filter((m) => m.status?.status === "Online");
    if (this.statusFilter === "active") return matches.filter((m) => m.status && m.status.status !== "Offline");
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
      const empty = Dom.el("div", "rc-empty", "Nothing to show yet. Run the three updates above, top to bottom.");
      table.appendChild(empty);
      return table;
    }

    for (const { player, company, stat, status } of rows) {
      const row = Dom.el("div", "rc-trow");

      const who = Dom.el("div");
      const playerLink = Dom.el("a", "rc-name rc-link", player.name);
      playerLink.href = `https://www.torn.com/profiles.php?XID=${player.id}`;
      playerLink.target = "_blank";
      playerLink.rel = "noopener";
      who.append(playerLink, Dom.el("div", "rc-dim", `Lv ${player.level} · ${player.id}`));

      const ws = Dom.el("div", "rc-ws", stat.v.toLocaleString());
      ws.appendChild(Dom.el("small", null, stat.t ? shortAge(stat.t) : ""));

      const state = Dom.el("div", "rc-state");
      const dotClass = status?.status === "Online" ? "rc-dot--on" : status?.status === "Idle" ? "rc-dot--idle" : "rc-dot--off";
      state.append(Dom.el("span", `rc-dot ${dotClass}`), Dom.el("span", null, status ? `${status.status} · ${status.relative}` : "unknown"));

      const co = Dom.el("div");
      const coLink = Dom.el("a", "rc-name rc-name--co rc-link", company?.name || "?");
      if (player.companyId) {
        coLink.href = `https://www.torn.com/joblist.php#/p=corpinfo&ID=${player.companyId}`;
        coLink.target = "_blank";
        coLink.rel = "noopener";
      }
      coLink.appendChild(Dom.el("span", "rc-star", ` ★ ${company?.rating ?? "?"}`));
      const detail = [typeName(company?.typeId), status?.position, status?.days != null ? `${status.days}d` : null]
        .filter(Boolean)
        .join(" · ");
      co.append(coLink, Dom.el("div", "rc-dim", detail));

      const acts = Dom.el("div", "rc-acts");
      const chat = Dom.el("a", "rc-act");
      chat.title = "Start Torn chat";
      chat.innerHTML =
        '<svg viewBox="0 0 16 16" width="12" height="12" fill="currentColor" aria-hidden="true"><path d="M8 1.5c-4 0-7 2.6-7 5.8 0 1.8.9 3.4 2.4 4.5-.1 1-.5 1.9-1.2 2.7 1.5-.1 2.8-.6 3.8-1.3.6.2 1.3.2 2 .2 4 0 7-2.6 7-5.8s-3-6.1-7-6.1z"/></svg>';
      chat.href = ChatOpener.chatUrl(player.id);
      chat.target = "_blank";
      chat.rel = "noopener";
      acts.appendChild(chat);

      row.append(who, ws, state, co, acts);
      table.appendChild(row);
    }
    return table;
  }
}

function ageBadge(fetchedAt, staleAfterHours) {
  if (!fetchedAt) return Dom.el("span", "rc-badge rc-badge--stale", "never");
  const hours = (Date.now() - fetchedAt) / 3_600_000;
  const cls = hours < staleAfterHours ? "rc-badge--fresh" : hours < staleAfterHours * 2 ? "rc-badge--aging" : "rc-badge--stale";
  return Dom.el("span", `rc-badge ${cls}`, shortAge(fetchedAt));
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

function formatDuration(seconds) {
  seconds = Math.round(seconds);
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;
  if (hours) return `${hours}h ${String(minutes).padStart(2, "0")}m ${String(secs).padStart(2, "0")}s`;
  if (minutes) return `${minutes}m ${String(secs).padStart(2, "0")}s`;
  return `${secs}s`;
}
