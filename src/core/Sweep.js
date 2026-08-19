import { Store } from "./Store.js";

const PAGE_SIZE = 100;
const WINDOW_MS = 61_000;
const STAT_MAX_AGE_MS = 10 * 86_400_000;

// Measured value-at-rank samples from the workstats leaderboard (Aug 2026),
// used to predict how many pages a sweep to a given floor costs.
const RANK_CURVE = [
  [565_457, 100],
  [483_000, 200],
  [452_000, 300],
  [403_000, 500],
  [279_000, 1_000],
  [36_000, 3_000],
  [7_500, 6_000],
];

export function estimateSweepPages(floor) {
  if (floor >= RANK_CURVE[0][0]) return RANK_CURVE[0][1];
  for (let i = 1; i < RANK_CURVE.length; i++) {
    const [hiValue, hiPages] = RANK_CURVE[i - 1];
    const [loValue, loPages] = RANK_CURVE[i];
    if (floor >= loValue) {
      const t = (hiValue - floor) / (hiValue - loValue);
      return Math.round(hiPages + t * (loPages - hiPages));
    }
  }
  return RANK_CURVE[RANK_CURVE.length - 1][1] * 2;
}

export class Sweep {
  constructor(api) {
    this.api = api;
    this.stats = Store.get("stats", { byId: {}, fetchedAt: null, floor: null });
  }

  pausedProgress(floor) {
    const progress = Store.get("sweep_progress");
    if (!progress || progress.floor > floor) return null;
    return progress;
  }

  staleDirectPlayers(players) {
    const byId = this.stats.byId || {};
    const now = Date.now();
    return players.filter((p) => {
      const stat = byId[p.id];
      return !(stat?.t && now - stat.t < STAT_MAX_AGE_MS);
    });
  }

  async runDirect(players, { onProgress, shouldStop } = {}) {
    const byId = { ...(this.stats.byId || {}) };
    const stale = this.staleDirectPlayers(players);

    if (stale.length) {
      const tasks = stale.map((p) => ({ path: `/user/${p.id}/hof` }));
      const results = await this.api.runBatch(tasks, {
        onProgress: (done, total) => onProgress?.(done, total),
        shouldStop,
      });

      results.forEach((result, i) => {
        if (!result || result instanceof Error) return;
        const hof = result.hof || {};
        const workstats = hof.working_stats || hof.workstats || hof.workingstats;
        if (workstats?.value != null) {
          byId[stale[i].id] = { v: workstats.value, la: null, lvl: stale[i].level, n: stale[i].name, t: Date.now() };
        }
      });
    }

    this.stats = { byId, fetchedAt: Date.now(), floor: 0 };
    Store.set("stats", this.stats);
    return this.stats;
  }

  async run(floor, { rosterIds, onProgress, shouldStop } = {}) {
    const resume = this.pausedProgress(floor);
    let offset = resume ? resume.offset : 0;
    const byId = {};
    if (resume?.byId) {
      for (const [id, stat] of Object.entries(resume.byId)) {
        if (!rosterIds || rosterIds.has(Number(id))) byId[id] = stat;
      }
    }
    let lowest = resume ? resume.lowest ?? null : null;
    let lastSample = resume ? resume.lastSample ?? null : null;
    let etaPages = resume ? resume.etaPages ?? null : null;
    let reachedFloor = false;

    const report = (rank) => {
      const donePages = Math.max(0, (rank - offset) / PAGE_SIZE);
      const remainingPages = etaPages === null ? null : Math.max(1, etaPages - donePages);
      onProgress?.({ rank, found: Object.keys(byId).length, lowest, floor, remainingPages });
    };

    while (!reachedFloor) {
      if (shouldStop?.()) return null;

      const windowStart = Date.now();
      const pages = Math.max(1, this.api.capacityPerWindow());
      const tasks = Array.from({ length: pages }, (_, i) => ({
        path: "/torn/hof",
        params: { cat: "workstats", limit: PAGE_SIZE, offset: offset + i * PAGE_SIZE },
      }));

      const results = await this.api.runBatch(tasks, {
        onProgress: (done) => report(offset + done * PAGE_SIZE),
        shouldStop,
      });

      for (const result of results) {
        if (result instanceof Error) throw result;
        const rows = result.hof || [];
        for (const row of rows) {
          if (lowest === null || row.value < lowest) lowest = row.value;
          if (row.value >= floor) {
            if (!rosterIds || rosterIds.has(row.id)) {
              byId[row.id] = { v: row.value, la: row.last_action, lvl: row.level, n: row.username, t: Date.now() };
            }
          } else {
            reachedFloor = true;
          }
        }
        if (rows.length < PAGE_SIZE) reachedFloor = true;
      }

      offset += pages * PAGE_SIZE;

      if (lastSample && lowest !== null && lastSample.lowest > lowest && offset > lastSample.rank) {
        const valuePerRank = (lastSample.lowest - lowest) / (offset - lastSample.rank);
        etaPages = lowest > floor && valuePerRank > 0 ? Math.ceil((lowest - floor) / valuePerRank / PAGE_SIZE) : 1;
      }
      lastSample = { rank: offset, lowest };

      try {
        Store.set("sweep_progress", { floor, offset, byId, lowest, lastSample, etaPages });
      } catch {
        Store.remove("sweep_progress");
      }
      report(offset);

      if (!reachedFloor) {
        const elapsed = Date.now() - windowStart;
        if (elapsed < WINDOW_MS) await sleep(WINDOW_MS - elapsed);
      }
    }

    this.stats = { byId, fetchedAt: Date.now(), floor };
    Store.set("stats", this.stats);
    Store.remove("sweep_progress");
    return this.stats;
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
