import { Store } from "./Store.js";

const PAGE_SIZE = 100;
const WINDOW_MS = 61_000;

export class Sweep {
  constructor(api) {
    this.api = api;
    this.stats = Store.get("stats", { byId: {}, fetchedAt: null, floor: null });
  }

  async run(floor, { onProgress, shouldStop } = {}) {
    const progress = Store.get("sweep_progress");
    const resuming = progress && progress.floor === floor;
    let offset = resuming ? progress.offset : 0;
    const byId = resuming ? progress.byId : {};
    let reachedFloor = false;

    while (!reachedFloor) {
      if (shouldStop?.()) return null;

      const windowStart = Date.now();
      const pages = Math.max(1, this.api.capacityPerWindow());
      const tasks = Array.from({ length: pages }, (_, i) => ({
        path: "/torn/hof",
        params: { cat: "workstats", limit: PAGE_SIZE, offset: offset + i * PAGE_SIZE },
      }));

      const results = await this.api.runBatch(tasks, {
        onProgress: () => onProgress?.(offset, byId),
        shouldStop,
      });

      for (const result of results) {
        if (result instanceof Error) throw result;
        const rows = result.hof || [];
        for (const row of rows) {
          if (row.value >= floor) {
            byId[row.id] = { v: row.value, la: row.last_action, lvl: row.level, n: row.username };
          } else {
            reachedFloor = true;
          }
        }
        if (rows.length < PAGE_SIZE) reachedFloor = true;
      }

      offset += pages * PAGE_SIZE;
      Store.set("sweep_progress", { floor, offset, byId });
      onProgress?.(offset, byId);

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
