import { Store } from "./Store.js";
import { TornApiError } from "./Api.js";

const STAT_MAX_AGE_MS = 10 * 86_400_000;
const WINDOW_MS = 61_000;

export class Stats {
  constructor(api) {
    this.api = api;
    this.data = Store.get("stats", { byId: {}, fetchedAt: null });
    Store.remove("sweep_progress");
  }

  stalePlayers(players) {
    const byId = this.data.byId || {};
    const now = Date.now();
    return players.filter((p) => {
      const stat = byId[p.id];
      return !(stat?.t && now - stat.t < STAT_MAX_AGE_MS);
    });
  }

  async run(players, { onProgress, shouldStop } = {}) {
    const byId = { ...(this.data.byId || {}) };
    const stale = this.stalePlayers(players);
    const total = stale.length;
    let done = 0;
    let index = 0;

    while (index < stale.length) {
      if (shouldStop?.()) break;

      const windowStart = Date.now();
      const capacity = Math.max(1, this.api.capacityPerWindow());
      const slice = stale.slice(index, index + capacity);
      const tasks = slice.map((p) => ({ path: `/user/${p.id}/hof` }));

      const results = await this.api.runBatch(tasks, {
        onProgress: (doneInWindow) => onProgress?.(done + doneInWindow, total),
        shouldStop,
      });

      results.forEach((result, i) => {
        const player = slice[i];
        if (!result) return;
        if (result instanceof TornApiError) {
          if (result.code !== 5) byId[player.id] = { v: 0, t: Date.now(), n: player.name, lvl: player.level };
          return;
        }
        if (result instanceof Error) return;
        const hof = result.hof || {};
        const workstats = hof.working_stats || hof.workstats || hof.workingstats;
        if (workstats?.value != null) {
          byId[player.id] = { v: workstats.value, lvl: player.level, n: player.name, t: Date.now() };
        }
      });

      done += slice.length;
      index += slice.length;
      this.data = { byId, fetchedAt: Date.now() };
      try {
        Store.set("stats", this.data);
      } catch {
        Store.remove("stats");
      }
      onProgress?.(done, total);

      if (index < stale.length) {
        const elapsed = Date.now() - windowStart;
        if (elapsed < WINDOW_MS) await sleep(WINDOW_MS - elapsed);
      }
    }

    return this.data;
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
