import { TornDirect } from "./TornDirect.js";
import { MugKey } from "./MugKey.js";

const LOGS_KEY = "tm_mug_logs";
const CALLS_KEY = "tm_mug_api_calls";
const MUG_LOG_TYPE = 8155;
const PAGE_LIMIT = 100;
const MAX_PAGES = 150;
const PAGE_DELAY_MS = 350;
const ATTACK_LOG_RE = /ID=([A-Za-z0-9]+)/;

export const EARLIEST_DATE = "2026-01-01";

export const MugLogs = {
  apiCalls() {
    const n = parseInt(localStorage.getItem(CALLS_KEY) || "0", 10);
    return Number.isFinite(n) ? n : 0;
  },

  bumpApiCalls() {
    const total = this.apiCalls() + 1;
    try {
      localStorage.setItem(CALLS_KEY, String(total));
    } catch {
      return total;
    }
    return total;
  },

  stored() {
    try {
      const raw = localStorage.getItem(LOGS_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  },

  store(result) {
    try {
      localStorage.setItem(LOGS_KEY, JSON.stringify(result));
    } catch {
      return;
    }
  },

  clear() {
    try {
      localStorage.removeItem(LOGS_KEY);
    } catch {
      return;
    }
  },

  // Walks the log endpoint page by page (newest first), following the older
  // pages until the start date is reached. onProgress(count) reports progress.
  async fetch(startTs, endTs, onProgress) {
    const key = MugKey.get();
    if (!key) throw new Error("No Full Access key is connected.");

    const seen = new Set();
    const logs = [];
    let to = endTs;

    for (let page = 0; page < MAX_PAGES; page++) {
      let data;
      try {
        data = await TornDirect.get(`/user/log?log=${MUG_LOG_TYPE}&limit=${PAGE_LIMIT}&to=${to}`, key);
      } catch (err) {
        throw MugKey.invalidKeyError(err) || err;
      }
      this.bumpApiCalls();

      const entries = Array.isArray(data.log) ? data.log : [];
      if (!entries.length) break;

      let oldest = Infinity;
      for (const entry of entries) {
        if (entry.timestamp < oldest) oldest = entry.timestamp;
        if (seen.has(entry.id)) continue;
        seen.add(entry.id);
        if (entry.timestamp >= startTs && entry.timestamp <= endTs) {
          logs.push(this.trim(entry));
        }
      }

      onProgress?.(logs.length);

      if (oldest <= startTs) break;
      if (entries.length < PAGE_LIMIT) break;
      if (!data._metadata?.links?.prev) break;

      to = oldest;
      await delay(PAGE_DELAY_MS);
    }

    logs.sort((a, b) => b.timestamp - a.timestamp);
    return logs;
  },

  trim(entry) {
    const d = entry.data || {};
    const match = ATTACK_LOG_RE.exec(d.log || "");
    return {
      timestamp: entry.timestamp,
      energy: d.energy_used || 0,
      money: d.money_mugged || 0,
      defender: d.defender || 0,
      attackId: match ? match[1] : null,
    };
  },

  stats(logs) {
    let energy = 0;
    let money = 0;
    let largest = null;
    for (const log of logs) {
      energy += log.energy;
      money += log.money;
      if (!largest || log.money > largest.money) largest = log;
    }
    return { mugs: logs.length, energy, money, largest };
  },
};

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
