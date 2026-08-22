import { TornDirect } from "./TornDirect.js";
import { MugKey } from "./MugKey.js";
import { MugLogs } from "./MugLogs.js";

const CACHE_KEY = "tm_mug_targets_cache";
const SCAN_KEY = "tm_mug_targets_scan";
const MARKET_PRICE_KEY = "tm_mug_market_prices";
const BUDGET_KEY = "tm_mug_buy_budget";
const CLOTHING_STORE_TYPE = 5;
const CACHE_TTL_MS = 5 * 60 * 1000;
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

  onItemMarket() {
    return /[?&]sid=ItemMarket/i.test(location.href);
  },

  currentItemId() {
    const match = /itemID=(\d+)/i.exec(location.href);
    return match ? match[1] : null;
  },

  collectSellers() {
    const sellers = [];
    const seen = new Set();
    for (const row of document.querySelectorAll(".sellerRow___PaRgK")) {
      const link = row.querySelector('a[href*="profiles.php?XID="]');
      const match = link && /XID=(\d+)/.exec(link.getAttribute("href") || "");
      if (!match || seen.has(match[1])) continue;

      const price = parseInt((row.querySelector(".price___cFwLC")?.textContent || "").replace(/[^0-9]/g, ""), 10);
      const available = parseInt(
        (row.querySelector(".available___XH9yl")?.textContent || "").replace(/[^0-9]/g, ""),
        10,
      );
      if (!Number.isFinite(price) || price <= 0) continue;

      seen.add(match[1]);
      sellers.push({
        id: match[1],
        name: (link.getAttribute("aria-label") || "").replace(/^View profile of\s*/i, "") || `User ${match[1]}`,
        price,
        available: Number.isFinite(available) ? available : 1,
      });
    }
    return sellers;
  },

  marketPrice(itemId) {
    try {
      const raw = localStorage.getItem(MARKET_PRICE_KEY);
      const map = raw ? JSON.parse(raw) : {};
      return map && typeof map === "object" ? map[itemId] || null : null;
    } catch {
      return null;
    }
  },

  setMarketPrice(itemId, value) {
    let map = {};
    try {
      const raw = localStorage.getItem(MARKET_PRICE_KEY);
      const parsed = raw ? JSON.parse(raw) : {};
      if (parsed && typeof parsed === "object") map = parsed;
    } catch {
      map = {};
    }
    map[itemId] = value;
    try {
      localStorage.setItem(MARKET_PRICE_KEY, JSON.stringify(map));
    } catch {
      return;
    }
  },

  clearMarketPrice(itemId) {
    try {
      const raw = localStorage.getItem(MARKET_PRICE_KEY);
      const map = raw ? JSON.parse(raw) : {};
      if (!map || typeof map !== "object" || !(itemId in map)) return;
      delete map[itemId];
      localStorage.setItem(MARKET_PRICE_KEY, JSON.stringify(map));
    } catch {
      return;
    }
  },

  async fetchMarketValue(itemId) {
    const key = MugKey.get();
    if (!key) throw new Error("Connect your Full Access key on the Mugging tab first.");
    let data;
    try {
      data = await TornDirect.get(`/market/${itemId}/itemmarket`, key);
    } catch (err) {
      throw MugKey.invalidKeyError(err) || err;
    }
    MugLogs.bumpApiCalls();
    const value = data?.itemmarket?.item?.average_price;
    if (!value) throw new Error("Torn returned no market value for this item.");
    return value;
  },

  buyBudget() {
    try {
      const raw = localStorage.getItem(BUDGET_KEY);
      return raw ? Number(raw) || 0 : 0;
    } catch {
      return 0;
    }
  },

  setBuyBudget(value) {
    try {
      localStorage.setItem(BUDGET_KEY, String(value));
    } catch {
      return;
    }
  },

  async scanSellers(sellers, { marketValue, budget, mugRate, force = false, onProgress, onTarget } = {}) {
    const key = MugKey.get();
    if (!key) throw new Error("Connect your Full Access key on the Mugging tab first.");

    const limited = sellers.slice(0, MAX_TARGETS);
    const cache = this.readCache();
    let done = 0;

    for (const seller of limited) {
      const id = seller.id;
      const cached = cache[id];
      const fresh = cached && !cached.error && Date.now() - cached.at < CACHE_TTL_MS;

      if (force || !fresh) {
        try {
          const data = await TornDirect.getV1(`/user/${id}?selections=profile`, key);
          MugLogs.bumpApiCalls();
          cache[id] = this.evaluate(id, data);
        } catch (err) {
          const dead = MugKey.invalidKeyError(err);
          if (dead) throw dead;
          cache[id] = { id, name: cached?.name || seller.name, error: true, at: Date.now() };
        }
        if (done < limited.length - 1) await delay(SCAN_DELAY_MS);
      }

      done += 1;
      const profile = cache[id];
      if (profile?.muggable) {
        const deal = buyMugDeal(seller, { marketValue, budget, mugRate });
        if (deal.qty > 0 && deal.profit > 0) {
          onTarget?.({ ...seller, ...deal });
        }
      }
      onProgress?.(done, limited.length);
    }

    this.writeCache(cache);
  },

  async scan(ids, { force = false, onProgress, onTarget } = {}) {
    const key = MugKey.get();
    if (!key) throw new Error("Connect your Full Access key on the Mugging tab first.");

    const limited = ids.slice(0, MAX_TARGETS);
    const cache = this.readCache();
    let done = 0;

    for (const id of limited) {
      const cached = cache[id];
      const fresh = cached && !cached.error && Date.now() - cached.at < CACHE_TTL_MS;

      if (force || !fresh) {
        try {
          const data = await TornDirect.getV1(`/user/${id}?selections=profile`, key);
          MugLogs.bumpApiCalls();
          cache[id] = this.evaluate(id, data);
        } catch (err) {
          const dead = MugKey.invalidKeyError(err);
          if (dead) throw dead;
          cache[id] = { id, name: cached?.name || `User ${id}`, error: true, at: Date.now() };
        }
        if (done < limited.length - 1) await delay(SCAN_DELAY_MS);
      }

      done += 1;
      if (cache[id]?.muggable) onTarget?.(cache[id]);
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
    const entries = scan.ids.map((id) => cache[id]).filter((e) => e && !e.error);
    return {
      at: scan.at,
      truncated: scan.truncated,
      found: scan.found,
      scanned: entries.length,
      targets: entries.filter((e) => e.muggable),
      clothing: entries.filter((e) => e.clothingStore),
      hospital: entries.filter((e) => e.state === "Hospital"),
    };
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

function buyMugDeal(seller, { marketValue, budget, mugRate }) {
  const price = seller.price;
  const affordable = price > 0 ? Math.floor(budget / price) : 0;
  const qty = Math.max(0, Math.min(seller.available, affordable));
  const spend = qty * price;
  const estMug = mugRate * spend;
  const resale = qty * marketValue;
  const profit = estMug + resale - spend;
  return { qty, spend, estMug, profit };
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
