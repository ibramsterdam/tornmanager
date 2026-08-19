import { Dom } from "../core/Dom.js";
import { Settings } from "../core/Settings.js";
import { typeName } from "../core/CompanyTypes.js";

export class OverviewScreen {
  constructor({ roster, sweep, status, api, overlay }) {
    this.roster = roster;
    this.sweep = sweep;
    this.status = status;
    this.api = api;
    this.overlay = overlay;
    this.busy = false;
    this.statusFilter = "any";
  }

  subtitle() {
    const settings = Settings.get();
    const types = settings.typeIds.map(typeName).join(" + ") || "no types";
    return `${types} · ${settings.starMin}-${settings.starMax}★ · ${formatStat(settings.floor)}+`;
  }

  render(container) {
    this.container = container;
    const settings = Settings.get();
    const matches = this.matches(settings);

    container.appendChild(this.syncRows(matches));
    this.progress = Dom.el("div", "rc-progress");
    container.appendChild(this.progress);

    const filterRow = Dom.el("div", "rc-row rc-row--filters");
    const filterField = Dom.el("div", "rc-field");
    filterField.appendChild(Dom.el("div", "rc-label", "Status"));
    const select = Dom.el("select", "rc-input");
    for (const [value, label] of [["any", "Any"], ["online", "Online"], ["active", "Online or idle"]]) {
      const option = Dom.el("option", null, label);
      option.value = value;
      if (value === this.statusFilter) option.selected = true;
      select.appendChild(option);
    }
    select.addEventListener("change", () => {
      this.statusFilter = select.value;
      this.overlay.refresh();
    });
    filterField.appendChild(select);
    filterRow.appendChild(filterField);
    container.appendChild(filterRow);

    const visible = this.filterByStatus(matches);
    const meta = Dom.el("div", "rc-meta");
    meta.append(
      Dom.el("span", null, `${visible.length} of ${matches.length} matches shown`),
      Dom.el("span", "rc-dim", "sorted by working stats")
    );
    container.appendChild(meta);
    container.appendChild(this.table(visible.slice(0, 300)));
  }

  syncRows(matches) {
    const wrap = Dom.el("div", "rc-syncs");
    const companyCount = new Set(matches.map((m) => m.player.companyId)).size;

    wrap.appendChild(this.syncRow({
      name: "Roster",
      desc: "who works where, ratings · 2 calls",
      fetchedAt: this.roster.data?.fetchedAt,
      staleAfterHours: 24,
      action: () => this.updateRoster(),
    }));
    const paused = this.sweep.pausedProgress(Settings.get().floor);
    wrap.appendChild(this.syncRow({
      name: "Working stats",
      desc: paused
        ? `paused at rank ~${paused.offset.toLocaleString()} · Update continues where it left off`
        : "HoF sweep down to the floor",
      fetchedAt: this.sweep.stats?.fetchedAt,
      staleAfterHours: 24 * 10,
      badge: paused ? pausedBadge() : null,
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

  syncRow({ name, desc, fetchedAt, staleAfterHours, badge, action }) {
    const row = Dom.el("div", "rc-sync");
    const button = Dom.el("button", "rc-btn rc-btn--ghost", "Update");
    button.addEventListener("click", async () => {
      if (this.busy) return;
      this.busy = true;
      try {
        await action();
      } catch (error) {
        this.setProgress(`${name} failed: ${error.message}`);
        return;
      } finally {
        this.busy = false;
      }
      this.overlay.refresh();
    });
    row.append(
      Dom.el("span", "rc-sync-name", name),
      Dom.el("span", "rc-dim", desc),
      badge || ageBadge(fetchedAt, staleAfterHours),
      button
    );
    return row;
  }

  async updateRoster() {
    await this.roster.update(Settings.get(), { onProgress: (text) => this.setProgress(text) });
  }

  async updateStats() {
    const floor = Settings.get().floor;
    await this.sweep.run(floor, {
      onProgress: ({ rank, found, lowest }) => {
        const depth = lowest === null ? "" : ` · now at ${formatStat(lowest)}, sweeping down to ${formatStat(floor)}`;
        this.setProgress(`Sweeping Hall of Fame · rank ~${rank.toLocaleString()} · ${found.toLocaleString()} players collected${depth}`);
      },
    });
    this.setProgress("Working stats sweep finished.");
  }

  async updateStatus(matches) {
    const companyIds = [...new Set(matches.map((m) => m.player.companyId))];
    if (!companyIds.length) {
      this.setProgress("No matches yet. Update the roster and working stats first.");
      return;
    }
    await this.status.refresh(companyIds, {
      onProgress: (done, total) => this.setProgress(`Refreshing status · ${done} of ${total} companies`),
    });
  }

  setProgress(text) {
    if (this.progress) this.progress.textContent = text;
  }

  matches(settings) {
    const roster = this.roster.data;
    const stats = this.sweep.stats?.byId || {};
    const statuses = this.status.data?.byId || {};
    if (!roster) return [];

    const cutoff = Date.now() / 1000 - settings.inactiveDays * 86_400;
    const result = [];
    for (const player of roster.players) {
      if (player.director) continue;
      const stat = stats[player.id];
      if (!stat || stat.v < settings.floor) continue;
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

    const statsAge = shortAge(this.sweep.stats?.fetchedAt);
    for (const { player, company, stat, status } of rows) {
      const row = Dom.el("div", "rc-trow");

      const who = Dom.el("div");
      who.append(Dom.el("div", "rc-name", player.name), Dom.el("div", "rc-dim", `Lv ${player.level} · ${player.id}`));

      const ws = Dom.el("div", "rc-ws", stat.v.toLocaleString());
      ws.appendChild(Dom.el("small", null, statsAge ? `${statsAge} old` : ""));

      const state = Dom.el("div", "rc-state");
      const dotClass = status?.status === "Online" ? "rc-dot--on" : status?.status === "Idle" ? "rc-dot--idle" : "rc-dot--off";
      state.append(Dom.el("span", `rc-dot ${dotClass}`), Dom.el("span", null, status ? `${status.status} · ${status.relative}` : "unknown"));

      const co = Dom.el("div");
      const coName = Dom.el("div", "rc-name rc-name--co", company?.name || "?");
      coName.appendChild(Dom.el("span", "rc-star", ` ★ ${company?.rating ?? "?"}`));
      const detail = [typeName(company?.typeId), status?.position, status?.days != null ? `${status.days}d` : null]
        .filter(Boolean)
        .join(" · ");
      co.append(coName, Dom.el("div", "rc-dim", detail));

      const acts = Dom.el("div", "rc-acts");
      const profile = Dom.el("a", "rc-act", "↗");
      profile.href = `https://www.torn.com/profiles.php?XID=${player.id}`;
      profile.target = "_blank";
      profile.rel = "noopener";
      acts.appendChild(profile);

      row.append(who, ws, state, co, acts);
      table.appendChild(row);
    }
    return table;
  }
}

function pausedBadge() {
  return Dom.el("span", "rc-badge rc-badge--aging", "paused");
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

function formatStat(value) {
  return value >= 1000 ? `${Math.round(value / 1000)}k` : String(value);
}
