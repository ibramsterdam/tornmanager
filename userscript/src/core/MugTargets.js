import { TornDirect } from "./TornDirect.js";
import { MugKey } from "./MugKey.js";
import { MugLogs } from "./MugLogs.js";

const CACHE_KEY = "tm_mug_targets_cache";
const SCAN_KEY = "tm_mug_targets_scan";
const DISMISS_KEY = "tm_mug_targets_dismissed";
const CLOTHING_STORE_TYPE = 5;
const CACHE_TTL_MS = 5 * 60 * 1000;
const DISMISS_TTL_MS = 12 * 60 * 60 * 1000;
const SCAN_DELAY_MS = 750;
const MAX_TARGETS = 120;

export const MugTargets = {
  onBazaarDirectory() {
    return (
      location.pathname.endsWith("/page.php") && new URLSearchParams(location.search).get("sid") === "bazaar"
    );
  },

  collectUserIds() {
    const ids = [];
    const seen = new Set();
    for (const link of document.querySelectorAll('a[href*="bazaar.php?userId="]')) {
      const match = /userId=(\d+)/.exec(link.getAttribute("href") || "");
      if (!match || seen.has(match[1])) continue;
      seen.add(match[1]);
      ids.push(match[1]);
    }
    return ids;
  },

  async scan(ids, { force = false, onProgress, onTarget } = {}) {
    const key = MugKey.get();
    if (!key) throw new Error("Connect your Full Access key on the Mugging tab first.");

    const limited = ids.slice(0, MAX_TARGETS);
    const cache = this.readCache();
    const dismissed = this.dismissed();
    let done = 0;

    for (const id of limited) {
      const cached = cache[id];
      const fresh = cached && !cached.error && Date.now() - cached.at < CACHE_TTL_MS;

      if (force || !fresh) {
        try {
          const data = await TornDirect.getV1(`/user/${id}?selections=profile`, key);
          MugLogs.bumpApiCalls();
          cache[id] = this.evaluate(id, data);
        } catch {
          cache[id] = { id, name: cached?.name || `User ${id}`, error: true, at: Date.now() };
        }
        if (done < limited.length - 1) await delay(SCAN_DELAY_MS);
      }

      done += 1;
      if (cache[id]?.muggable && !dismissed[id]) onTarget?.(cache[id]);
      onProgress?.(done, limited.length);
    }

    this.writeCache(cache);
    const scan = { ids: limited, at: Date.now(), truncated: ids.length > limited.length, found: ids.length };
    this.writeScan(scan);
    return this.buildResult(scan, cache);
  },

  evaluate(id, data) {
    const status = data.status || {};
    const job = data.job || {};
    const clothingStore = (job.company_type || 0) === CLOTHING_STORE_TYPE;
    const state = status.state || "Unknown";

    return {
      id,
      name: data.name || `User ${id}`,
      state,
      until: status.until || 0,
      clothingStore,
      companyName: clothingStore ? job.company_name || "Clothing Store" : "",
      muggable: state === "Okay" && !clothingStore,
      at: Date.now(),
    };
  },

  lastResult() {
    const scan = this.readScan();
    return scan ? this.buildResult(scan, this.readCache()) : null;
  },

  buildResult(scan, cache) {
    const dismissed = this.dismissed();
    const entries = scan.ids.map((id) => cache[id]).filter((e) => e && !e.error);
    return {
      at: scan.at,
      truncated: scan.truncated,
      found: scan.found,
      scanned: entries.length,
      targets: entries.filter((e) => e.muggable && !dismissed[e.id]),
      clothing: entries.filter((e) => e.clothingStore),
      hospital: entries.filter((e) => e.state === "Hospital"),
    };
  },

  dismissed() {
    let map = {};
    try {
      const raw = localStorage.getItem(DISMISS_KEY);
      const parsed = raw ? JSON.parse(raw) : {};
      if (parsed && typeof parsed === "object") map = parsed;
    } catch {
      map = {};
    }

    const now = Date.now();
    let changed = false;
    for (const id of Object.keys(map)) {
      if (now - map[id] > DISMISS_TTL_MS) {
        delete map[id];
        changed = true;
      }
    }
    if (changed) {
      try {
        localStorage.setItem(DISMISS_KEY, JSON.stringify(map));
      } catch {
        return map;
      }
    }
    return map;
  },

  dismiss(id) {
    const map = this.dismissed();
    map[String(id)] = Date.now();
    try {
      localStorage.setItem(DISMISS_KEY, JSON.stringify(map));
    } catch {
      return;
    }
  },

  readCache() {
    try {
      const raw = localStorage.getItem(CACHE_KEY);
      const cache = raw ? JSON.parse(raw) : {};
      return cache && typeof cache === "object" ? cache : {};
    } catch {
      return {};
    }
  },

  writeCache(cache) {
    try {
      localStorage.setItem(CACHE_KEY, JSON.stringify(cache));
    } catch {
      return;
    }
  },

  readScan() {
    try {
      const raw = localStorage.getItem(SCAN_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  },

  writeScan(scan) {
    try {
      localStorage.setItem(SCAN_KEY, JSON.stringify(scan));
    } catch {
      return;
    }
  },
};

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
