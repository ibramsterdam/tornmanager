import { Store } from "./Store.js";

const PAGE_SIZE = 100;
const WINDOW_MS = 61_000;

export class Sweep {
  constructor(api) {
    this.api = api;
    this.stats = Store.get("stats", { byId: {}, fetchedAt: null, floor: null });
  }

  pausedProgress(floor) {
    const progress = Store.get("sweep_progress");
    if (!progress || progress.floor !== floor) return null;
    return progress;
  }

  async run(floor, { onProgress, shouldStop } = {}) {
    const resume = this.pausedProgress(floor);
    let offset = resume ? resume.offset : 0;
    const byId = resume ? resume.byId : {};
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
            byId[row.id] = { v: row.value, la: row.last_action, lvl: row.level, n: row.username };
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

      Store.set("sweep_progress", { floor, offset, byId, lowest, lastSample, etaPages });
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
