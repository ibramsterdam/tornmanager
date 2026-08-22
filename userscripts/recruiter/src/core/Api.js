const BASE = "https://api.torn.com/v2";
const CALLS_PER_KEY_PER_MINUTE = 75;
const WINDOW_MS = 61_000;
const MAX_TRIES = 3;

export class TornApiError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "TornApiError";
    this.code = code;
  }
}

export class Api {
  constructor(keys) {
    this.keys = keys;
  }

  async call(path, params = {}, key = null) {
    const apiKey = key || this.keys.next();
    if (!apiKey) throw new Error("No valid API key configured");

    const url = new URL(BASE + path);
    for (const [k, v] of Object.entries(params)) url.searchParams.set(k, String(v));
    url.searchParams.set("comment", "Recruiter");

    const res = await fetch(url, { headers: { Authorization: `ApiKey ${apiKey}` } });
    this.keys.recordCall(apiKey);

    const text = await res.text();
    if (text.startsWith("{") || text.startsWith("[")) {
      const json = JSON.parse(text);
      if (json.error) throw new TornApiError(json.error.code, json.error.error);
      return json;
    }
    return text;
  }

  capacityPerWindow() {
    return this.keys.active().length * CALLS_PER_KEY_PER_MINUTE;
  }

  // One burst per minute-window, round-robin across the key pool. Burst
  // pacing instead of a 1/sec timer chain: background tabs throttle timers
  // to ~1/min, so the fewer timer ticks a long fetch needs, the better.
  async runBatch(tasks, { onProgress, shouldStop } = {}) {
    const results = new Array(tasks.length);
    const queue = tasks.map((task, index) => ({ task, index, tries: 0 }));
    let completed = 0;

    while (queue.length) {
      if (shouldStop?.()) break;

      const pool = this.keys.active();
      if (!pool.length) throw new Error("No valid API key configured");

      const windowStart = Date.now();
      const slice = queue.splice(0, pool.length * CALLS_PER_KEY_PER_MINUTE);

      await Promise.all(
        slice.map(async (item, i) => {
          try {
            results[item.index] = await this.call(item.task.path, item.task.params, pool[i % pool.length]);
            completed += 1;
            onProgress?.(completed, tasks.length);
          } catch (error) {
            item.tries += 1;
            if (error instanceof TornApiError && error.code === 5 && item.tries < MAX_TRIES) {
              queue.push(item);
            } else {
              results[item.index] = error;
              completed += 1;
              onProgress?.(completed, tasks.length);
            }
          }
        })
      );

      if (queue.length) {
        const elapsed = Date.now() - windowStart;
        if (elapsed < WINDOW_MS) await interruptibleSleep(WINDOW_MS - elapsed, shouldStop);
      }
    }

    return results;
  }
}

export async function interruptibleSleep(ms, shouldStop) {
  const until = Date.now() + ms;
  while (Date.now() < until) {
    if (shouldStop?.()) return;
    await sleep(Math.min(1000, until - Date.now()));
  }
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
