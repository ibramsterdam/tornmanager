// ==UserScript==
// @name         Torn Manager Recruiter
// @namespace    torn-recruiter
// @version      0.4.1
// @author       Bram [2728237]
// @description  Company recruiting scout for Torn
// @license      All rights reserved
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%230070f3'/%3E%3Ctext x='32' y='43' text-anchor='middle' font-family='Arial,Helvetica,sans-serif' font-weight='900' font-size='34' fill='white'%3ER%3C/text%3E%3C/svg%3E
// @downloadURL  https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-recruiter.user.js
// @updateURL    https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-recruiter.user.js
// @match        https://www.torn.com/*
// @connect      torn.com
// @connect      api.torn.com
// @connect      tornmanager.com
// @grant        GM.xmlHttpRequest
// @grant        GM_addStyle
// @run-at       document-start
// @noframes
// ==/UserScript==

(r=>{if(typeof GM_addStyle=="function"){GM_addStyle(r);return}const e=document.createElement("style");e.textContent=r,document.head.append(e)})(` .recruiter-icon{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='18' fill='white'%3ER%3C/text%3E%3C/svg%3E")!important;background-position:center!important;background-size:contain!important;background-repeat:no-repeat!important;cursor:pointer!important}.recruiter-icon:before,.recruiter-icon:after{content:none!important;display:none!important}.recruiter-menu-item a{display:flex!important;align-items:center;gap:8px;background-image:none!important}.recruiter-menu-icon{flex:none;width:16px;height:16px;border-radius:4px;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='17' fill='white'%3ER%3C/text%3E%3C/svg%3E");background-size:contain;background-repeat:no-repeat;background-position:center}.rc-backdrop{position:fixed;top:0;right:0;bottom:0;left:0;z-index:999998;display:flex;align-items:center;justify-content:center;background:#0000;pointer-events:none;transition:background .25s ease}.rc-backdrop--visible{background:#0009;pointer-events:auto}.rc-panel{width:680px;max-width:94vw;max-height:82vh;display:flex;flex-direction:column;background:#1c1c1e;border:1px solid #333;border-radius:12px;box-shadow:0 24px 64px #00000080;color:#fff;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:13px;line-height:1.45;opacity:0;transform:translateY(20px) scale(.97);transition:opacity .25s ease,transform .25s ease;overflow:hidden}.rc-backdrop--visible .rc-panel{opacity:1;transform:translateY(0) scale(1)}.rc-head{display:flex;align-items:center;gap:10px;padding:12px 16px;background:#161618;border-bottom:1px solid #2e2e30}.rc-logo{display:inline-flex;align-items:center;justify-content:center;width:22px;height:22px;border-radius:6px;background:#0070f3;font-size:12px;font-weight:800}.rc-head-title{font-size:14.5px;font-weight:700}.rc-head-sub{font-size:11px;color:#6a6a70}.rc-nav{display:flex;gap:2px;margin-left:auto}.rc-nav-link{padding:6px 11px;background:none;border:none;border-radius:7px;font-size:12.5px;font-weight:600;color:#9a9aa2;cursor:pointer}.rc-nav-link:hover{color:#d6d6db}.rc-nav-link--active{background:#0070f3;color:#fff}.rc-close{background:none;border:none;color:#888;font-size:20px;line-height:1;padding:2px 8px;border-radius:4px;cursor:pointer}.rc-close:hover{color:#fff;background:#ffffff1a}.rc-body{padding:16px 18px 18px;overflow-y:auto;scrollbar-width:thin;scrollbar-color:#3a3a3e transparent}.rc-card{padding:13px 14px;background:#161618;border:1px solid #303032;border-radius:10px}.rc-card+.rc-card{margin-top:12px}.rc-label{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:#8a8a92;margin-bottom:6px}.rc-row{display:flex;gap:10px;align-items:flex-end}.rc-row--filters{margin-top:14px}.rc-field{flex:1;min-width:0}.rc-input{width:100%;padding:8px 11px;font-size:13px;color:#fff;background:#111;border:1px solid #333;border-radius:9px;outline:none;box-sizing:border-box;color-scheme:dark}.rc-input:focus{border-color:#0070f3}.rc-btn{padding:8px 14px;background:#0070f3;border:none;border-radius:8px;color:#fff;font-size:12.5px;font-weight:600;white-space:nowrap;cursor:pointer}.rc-btn:disabled{opacity:.6;cursor:default}.rc-btn--ghost{background:none;border:1px solid #333;color:#d6d6db}.rc-feedback{margin-top:8px;font-size:12px;min-height:16px}.rc-feedback--ok{color:#5cb85c}.rc-feedback--error{color:#e05252}.rc-list{display:flex;flex-direction:column;gap:8px;margin-top:12px}.rc-list-row{display:grid;grid-template-columns:68px 110px 1fr auto auto;gap:12px;align-items:center;padding:10px 14px;background:#161618;border:1px solid #303032;border-radius:10px}.rc-mono{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;color:#d6d6db;font-size:12px}.rc-dim{font-size:11.5px;color:#6a6a70;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rc-badge{display:inline-flex;align-items:center;gap:6px;padding:3px 10px;border-radius:999px;font-size:11px;font-weight:600;white-space:nowrap;justify-self:start}.rc-badge:before{content:"";width:6px;height:6px;border-radius:50%;background:currentColor}.rc-badge--fresh{background:#1c2f1f;color:#5cb85c}.rc-badge--aging{background:#33290f;color:#e8a33d}.rc-badge--stale{background:#351d1d;color:#e05252}.rc-scope{margin-top:12px;padding:11px 14px;background:#0e2038;border:1px solid #1d3a5f;border-radius:10px;font-size:12.5px;color:#bcd7f7}.rc-syncs{display:flex;flex-direction:column;gap:8px}.rc-sync{display:grid;grid-template-columns:108px 1fr auto auto;gap:12px;align-items:center;padding:10px 14px;background:#161618;border:1px solid #303032;border-radius:10px}.rc-sync-name{font-size:12.5px;font-weight:700}.rc-progress{min-height:16px;margin-top:10px;font-size:12px;color:#9a9aa2}.rc-meta{display:flex;justify-content:space-between;align-items:center;margin:12px 2px 8px;font-size:11.5px;color:#9a9aa2}.rc-table{border:1px solid #303032;border-radius:10px;overflow:hidden}.rc-thead,.rc-trow{display:grid;grid-template-columns:1.25fr .85fr .95fr 1.35fr 40px;gap:10px;align-items:center;padding:9px 13px}.rc-thead{background:#161618;border-bottom:1px solid #303032;font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:#8a8a92}.rc-trow{border-bottom:1px solid #242426}.rc-trow:last-child{border-bottom:none}.rc-name{font-weight:600;font-size:13px;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rc-name--co{font-size:12.5px}.rc-star{color:#e8b93d;font-size:11px}.rc-ws{font-size:13.5px;font-weight:700;font-variant-numeric:tabular-nums}.rc-ws small{display:block;font-size:10.5px;font-weight:500;color:#6a6a70}.rc-state{display:flex;align-items:center;gap:7px;font-size:12px;color:#d6d6db;white-space:nowrap}.rc-dot{width:8px;height:8px;border-radius:50%;flex:none}.rc-dot--on{background:#5cb85c;box-shadow:0 0 6px #5cb85c99}.rc-dot--idle{background:#e8a33d}.rc-dot--off{background:#55555c}.rc-acts{display:flex;gap:4px;justify-content:flex-end}.rc-act{display:inline-flex;align-items:center;justify-content:center;width:22px;height:22px;border-radius:6px;border:1px solid #333;background:none;color:#9a9aa2;font-size:11px;text-decoration:none;cursor:pointer}.rc-act:hover{color:#fff;border-color:#555}.rc-empty{padding:26px 20px;text-align:center;color:#6a6a70;font-size:12.5px}.rc-chips{display:flex;flex-wrap:wrap;gap:7px}.rc-chip{padding:5px 11px;border-radius:999px;border:1px solid #333;background:#111;font-size:12px;color:#9a9aa2;cursor:pointer}.rc-chip--on{border-color:#0070f3;background:#0e2038;color:#fff}.rc-footer-row{display:flex;align-items:center;gap:10px;margin-top:14px}.rc-auth{display:flex;flex-direction:column;align-items:center;gap:16px}.rc-auth-banner{width:100%;max-width:480px}.rc-auth-banner svg{display:block;width:100%;height:auto;border-radius:10px}.rc-auth-form{display:flex;flex-direction:column;gap:8px;width:100%;max-width:480px;margin-top:8px}.rc-auth-row{display:flex;gap:10px;align-items:stretch}.rc-auth-input{flex:1;min-width:0;padding:10px 14px;font-size:14px;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;color:#fff;background:#111;border:1px solid #333;border-radius:8px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.rc-auth-input:focus{border-color:#0070f3}.rc-auth-button{flex:none;padding:10px 22px;font-size:14px;font-weight:600;white-space:nowrap;color:#fff;background:#0070f3;border:none;border-radius:8px;cursor:pointer;transition:background .15s ease}.rc-auth-button:hover{background:#0061d5}.rc-auth-button:disabled{background:#333;cursor:not-allowed;color:#666}.rc-auth-error{margin:0;font-size:13px;color:#e53935;text-align:center;min-height:18px}.rc-auth-hint{margin:0;font-size:12px;line-height:1.5;color:#777;text-align:center}.rc-auth-hint strong{color:#aaa}.rc-auth-hint a,.rc-tos-agree a,.rc-sub-info a{color:#0070f3;text-decoration:none}.rc-auth-hint a:hover,.rc-tos-agree a:hover,.rc-sub-info a:hover{text-decoration:underline}.rc-tos{margin-top:4px;padding:12px 14px;text-align:left;background:#141416;border:1px solid #2a2a2c;border-radius:10px}.rc-tos-heading{margin:0 0 12px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#8a8a92}.rc-tos-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px 20px}.rc-tos-item{display:flex;flex-direction:column;gap:3px;font-size:12px;line-height:1.45}.rc-tos-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#6a6a70}.rc-tos-value{color:#d6d6db}.rc-tos-agree{display:flex;gap:8px;align-items:flex-start;margin-top:10px;font-size:12px;color:#9a9aa2;cursor:pointer}.rc-tos-agree input{margin:2px 0 0;accent-color:#0070f3}.rc-sub{display:flex;flex-direction:column;align-items:center;gap:14px;text-align:center;padding:4px 8px 0}.rc-sub-title{align-self:flex-start;margin:0;font-size:19px;font-weight:700;color:#fff}.rc-sub-note{margin:0;padding:12px 16px;background:#0e2038;border:1px solid #1d3a5f;border-radius:10px;color:#bcd7f7;font-size:12.5px;line-height:1.5}.rc-sub-status{font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:#8a8a92}.rc-sub-status--active{color:#5cb85c}.rc-sub-status--inactive{color:#9a9aa2}.rc-sub-status--warn{color:#e8a33d}.rc-sub-status--error{color:#e05252}.rc-sub-countdown{margin:-6px 0 0;font-size:21px;font-weight:800;color:#fff}.rc-sub-refresh{padding:8px 16px;background:none;border:1px solid #333;border-radius:8px;color:#d6d6db;font-size:12.5px;font-weight:600;cursor:pointer}.rc-sub-refresh:hover{border-color:#555}.rc-sub-refresh:disabled{opacity:.6;cursor:default}.rc-sub-info{width:100%;padding-top:14px;border-top:1px solid #2e2e30;font-size:12px;line-height:1.6;color:#6a6a70}.rc-sub-info strong{color:#d6d6db}.rc-actions-row{display:flex;gap:10px;justify-content:center;margin-top:4px}.rc-btn-danger{padding:8px 16px;background:none;border:1px solid #5a2626;border-radius:8px;color:#e05252;font-size:12.5px;font-weight:600;cursor:pointer}.rc-btn-danger:hover{border-color:#e05252}.rc-footer{padding:12px 18px 14px;border-top:1px solid #2e2e30;background:#1c1c1e}.rc-footer-links{display:flex;flex-wrap:wrap;gap:8px;align-items:center;justify-content:center;font-size:12px;color:#6a6a70}.rc-footer-links a,.rc-footer-link{background:none;border:none;padding:0;font-size:12px;color:#9a9aa2;text-decoration:none;cursor:pointer}.rc-footer-links a:hover,.rc-footer-link:hover{color:#fff}.rc-footer-links a.rc-footer-user{color:#4a9df8}.rc-footer-version{margin-top:5px;text-align:center;font-size:11px;color:#55555c}.rc-legal{display:flex;flex-direction:column;gap:14px;align-items:flex-start}.rc-legal-docs{width:100%;font-size:12.5px;line-height:1.6;color:#9a9aa2}.rc-legal-docs h2{margin:4px 0 2px;font-size:17px;font-weight:700;color:#fff}.rc-legal-docs h3{margin:16px 0 4px;font-size:13px;font-weight:700;color:#d6d6db}.rc-legal-docs p{margin:0 0 8px}.rc-legal-docs strong{color:#d6d6db}.rc-legal-sub{font-size:11px;color:#6a6a70}.rc-legal-divider{margin:22px 0;border:none;border-top:1px solid #2e2e30}.rc-hint{margin-top:10px;font-size:11.5px;line-height:1.5;color:#6a6a70}.rc-stepper{display:flex;align-items:center;gap:6px}.rc-stepper-btn{width:30px;height:32px;display:inline-flex;align-items:center;justify-content:center;background:#111;border:1px solid #333;border-radius:9px;color:#d6d6db;font-size:15px;line-height:1;cursor:pointer}.rc-stepper-btn:hover:not(:disabled){border-color:#555;color:#fff}.rc-stepper-btn:disabled{opacity:.4;cursor:default}.rc-stepper-value{min-width:34px;text-align:center;font-size:13.5px;font-weight:700;font-variant-numeric:tabular-nums;color:#fff}.rc-bar{position:relative;height:28px;margin-top:10px;border:1px solid #303032;border-radius:9px;background:#111;overflow:hidden}.rc-bar-fill{position:absolute;top:0;bottom:0;left:0;width:0%;border-radius:8px;background:linear-gradient(90deg,#0059c4,#0070f3);transition:width .6s ease;overflow:hidden}.rc-bar-fill:after{content:"";position:absolute;top:0;right:0;bottom:0;left:0;background:linear-gradient(90deg,transparent,rgba(255,255,255,.2),transparent);transform:translate(-100%);animation:rc-shimmer 1.8s infinite}.rc-bar--indeterminate .rc-bar-fill{width:30%;transition:none;animation:rc-indet 1.6s linear infinite}.rc-bar-text{position:relative;z-index:1;display:flex;align-items:center;justify-content:center;height:100%;padding:0 12px;font-size:11.5px;font-weight:600;font-variant-numeric:tabular-nums;color:#fff;text-shadow:0 1px 2px rgba(0,0,0,.6);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}@keyframes rc-shimmer{to{transform:translate(100%)}}@keyframes rc-indet{0%{transform:translate(-100%)}to{transform:translate(433%)}}@media(prefers-reduced-motion:reduce){.rc-bar-fill:after,.rc-bar--indeterminate .rc-bar-fill{animation:none}}.rc-subcard{margin-top:12px}.rc-subcard-row{display:flex;align-items:center;gap:12px}.rc-subcard-count{flex:1;font-size:13px;font-weight:700;font-variant-numeric:tabular-nums;color:#fff}.rc-link{display:block;text-decoration:none}a.rc-link:hover{color:#4a9df8;text-decoration:underline}.rc-pager{display:flex;align-items:center;justify-content:center;gap:14px;margin-top:12px}.rc-act svg{display:block}.rc-field--chip{flex:none}.rc-chip--filter{display:inline-flex;align-items:center;min-width:110px;justify-content:center;padding:7px 14px;font-weight:600} `);

(function () {
  'use strict';

  const API_BASE = "https://tornmanager.com";
  function post(path, body = {}, { token = null } = {}) {
    const headers = {
      "Content-Type": "application/json",
      Accept: "application/json"
    };
    if (token) headers.Authorization = `Bearer ${token}`;
    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "POST",
        url: `${API_BASE}${path}`,
        headers,
        data: JSON.stringify(body),
        onload(response) {
          let data = null;
          try {
            data = JSON.parse(response.responseText);
          } catch {
            data = null;
          }
          if (response.status >= 200 && response.status < 300 && data) {
            resolve(data);
          } else {
            const error = new Error((data == null ? void 0 : data.error) || "Request failed");
            error.status = response.status;
            if (response.status === 429) error.rateLimited = true;
            if (data == null ? void 0 : data.suspended) error.suspended = true;
            reject(error);
          }
        },
        onerror() {
          reject(new Error("Network error. Could not reach Tornmanager."));
        }
      });
    });
  }
  class Auth {
    constructor(store) {
      this.store = store;
    }
    getUser() {
      return this.store.get("user");
    }
    getToken() {
      var _a;
      return ((_a = this.getUser()) == null ? void 0 : _a.token) || null;
    }
    isAuthenticated() {
      return this.getToken() != null;
    }
    clear() {
      this.store.remove("user");
      this.store.remove("subscription");
    }
    authenticate(apiKey) {
      return post("/api/session", { api_key: apiKey }).then((data) => {
        this.store.set("user", { ...data.user, token: data.token });
        return data.user;
      });
    }
    fetchSubscription({ refresh = false } = {}) {
      const token = this.getToken();
      if (!token) return Promise.reject(new Error("Not signed in"));
      const body = {};
      if (refresh) body.refresh = true;
      return post("/api/subscription", body, { token }).then((data) => {
        const subscription = { ...data.subscription, checkedAt: Date.now() };
        this.store.set("subscription", subscription);
        return subscription;
      });
    }
    subscription() {
      return this.store.get("subscription");
    }
    isSubscribed() {
      const sub = this.subscription();
      if (!(sub == null ? void 0 : sub.active)) return false;
      return !sub.expires_at || new Date(sub.expires_at) > /* @__PURE__ */ new Date();
    }
  }
  function createStore(prefix) {
    return {
      get(key, fallback = null) {
        try {
          const raw = localStorage.getItem(prefix + key);
          return raw === null ? fallback : JSON.parse(raw);
        } catch {
          return fallback;
        }
      },
      set(key, value) {
        localStorage.setItem(prefix + key, JSON.stringify(value));
      },
      remove(key) {
        localStorage.removeItem(prefix + key);
      }
    };
  }
  const Store = createStore("rc_");
  class Keys {
    constructor() {
      this.list = Store.get("keys", []);
      this.cursor = 0;
    }
    save() {
      Store.set("keys", this.list);
    }
    all() {
      return this.list;
    }
    active() {
      return this.list.filter((k) => k.valid).map((k) => k.key);
    }
    next() {
      const pool = this.active();
      if (!pool.length) return null;
      this.cursor = (this.cursor + 1) % pool.length;
      return pool[this.cursor];
    }
    async add(key, api) {
      var _a;
      key = key.trim();
      if (!key) throw new Error("Paste a key first");
      if (this.list.some((k) => k.key === key)) throw new Error("That key is already in the pool");
      const info = await api.call("/key/info", {}, key);
      const access = ((_a = info.info) == null ? void 0 : _a.access) || info.access || {};
      const accessType = String(access.type || "Unknown");
      if (!/public/i.test(accessType)) {
        throw new Error(`That key has ${accessType} access. Only Public access keys are accepted.`);
      }
      const basic = await api.call("/user/basic", {}, key);
      const owner = basic.basic || basic.profile || basic;
      if (!(owner == null ? void 0 : owner.id)) throw new Error("Could not resolve the key's owner");
      const duplicate = this.list.find((k) => k.ownerId === owner.id);
      if (duplicate) {
        throw new Error(`Also owned by ${owner.name} [${owner.id}], same player as an existing key. Extra keys from one player share the same 100/min limit.`);
      }
      const entry = {
        key,
        ownerId: owner.id,
        ownerName: owner.name,
        accessType,
        valid: true,
        addedAt: Date.now(),
        callsToday: 0,
        dayStamp: todayStamp()
      };
      this.list.push(entry);
      this.save();
      return entry;
    }
    remove(key) {
      this.list = this.list.filter((k) => k.key !== key);
      this.save();
    }
    markInvalid(key) {
      const entry = this.list.find((k) => k.key === key);
      if (entry) {
        entry.valid = false;
        this.save();
      }
    }
    recordCall(key) {
      const entry = this.list.find((k) => k.key === key);
      if (!entry) return;
      const stamp = todayStamp();
      if (entry.dayStamp !== stamp) {
        entry.dayStamp = stamp;
        entry.callsToday = 0;
      }
      entry.callsToday += 1;
      this.save();
    }
  }
  function todayStamp() {
    return (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
  }
  const BASE = "https://api.torn.com/v2";
  const CALLS_PER_KEY_PER_MINUTE$1 = 75;
  const WINDOW_MS$1 = 61e3;
  const MAX_TRIES = 3;
  class TornApiError extends Error {
    constructor(code, message) {
      super(message);
      this.name = "TornApiError";
      this.code = code;
    }
  }
  class Api {
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
      return this.keys.active().length * CALLS_PER_KEY_PER_MINUTE$1;
    }
    // One burst per minute-window, round-robin across the key pool. Burst
    // pacing instead of a 1/sec timer chain: background tabs throttle timers
    // to ~1/min, so the fewer timer ticks a long fetch needs, the better.
    async runBatch(tasks, { onProgress, shouldStop } = {}) {
      const results = new Array(tasks.length);
      const queue = tasks.map((task, index) => ({ task, index, tries: 0 }));
      let completed = 0;
      while (queue.length) {
        if (shouldStop == null ? void 0 : shouldStop()) break;
        const pool = this.keys.active();
        if (!pool.length) throw new Error("No valid API key configured");
        const windowStart = Date.now();
        const slice = queue.splice(0, pool.length * CALLS_PER_KEY_PER_MINUTE$1);
        await Promise.all(
          slice.map(async (item, i) => {
            try {
              results[item.index] = await this.call(item.task.path, item.task.params, pool[i % pool.length]);
              completed += 1;
              onProgress == null ? void 0 : onProgress(completed, tasks.length);
            } catch (error) {
              item.tries += 1;
              if (error instanceof TornApiError && error.code === 5 && item.tries < MAX_TRIES) {
                queue.push(item);
              } else {
                results[item.index] = error;
                completed += 1;
                onProgress == null ? void 0 : onProgress(completed, tasks.length);
              }
            }
          })
        );
        if (queue.length) {
          const elapsed = Date.now() - windowStart;
          if (elapsed < WINDOW_MS$1) await interruptibleSleep(WINDOW_MS$1 - elapsed, shouldStop);
        }
      }
      return results;
    }
  }
  async function interruptibleSleep(ms, shouldStop) {
    const until = Date.now() + ms;
    while (Date.now() < until) {
      if (shouldStop == null ? void 0 : shouldStop()) return;
      await sleep(Math.min(1e3, until - Date.now()));
    }
  }
  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
  function parseCsv(text) {
    const rows = [];
    let field = "";
    let row = [];
    let inQuotes = false;
    for (let i = 0; i < text.length; i++) {
      const char = text[i];
      if (inQuotes) {
        if (char === '"') {
          if (text[i + 1] === '"') {
            field += '"';
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field += char;
        }
      } else if (char === '"') {
        inQuotes = true;
      } else if (char === ",") {
        row.push(field);
        field = "";
      } else if (char === "\n") {
        row.push(field.endsWith("\r") ? field.slice(0, -1) : field);
        rows.push(row);
        field = "";
        row = [];
      } else {
        field += char;
      }
    }
    if (field !== "" || row.length) {
      row.push(field);
      rows.push(row);
    }
    const header = rows.shift() || [];
    return rows.filter((r) => r.length === header.length).map((r) => Object.fromEntries(header.map((name, i) => [name, r[i]])));
  }
  class Roster {
    constructor(api) {
      this.api = api;
      this.data = Store.get("roster");
    }
    async update(settings, { onProgress } = {}) {
      onProgress == null ? void 0 : onProgress("Downloading company snapshot…");
      const companyCsv = await this.api.call("/company/snapshot");
      onProgress == null ? void 0 : onProgress("Downloading player snapshot…");
      const userCsv = await this.api.call("/user/snapshot");
      onProgress == null ? void 0 : onProgress("Building roster…");
      const wantedTypes = new Set(settings.typeIds.map(String));
      const companies = {};
      for (const row of parseCsv(companyCsv)) {
        const rating = Number(row.rating || 0);
        if (!wantedTypes.has(row.type)) continue;
        if (rating < settings.starMin || rating > settings.starMax) continue;
        companies[row.id] = {
          name: row.name,
          typeId: Number(row.type),
          rating,
          hired: Number(row.employees_hired || 0)
        };
      }
      const players = [];
      for (const row of parseCsv(userCsv)) {
        const company = companies[row.company];
        if (!company) continue;
        players.push({
          id: Number(row.id),
          name: row.name,
          level: Number(row.level || 0),
          companyId: Number(row.company),
          director: row.job === "Director"
        });
      }
      this.data = { companies, players, fetchedAt: Date.now() };
      Store.set("roster", this.data);
      return this.data;
    }
  }
  const STAT_MAX_AGE_MS = 10 * 864e5;
  const WINDOW_MS = 61e3;
  class Stats {
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
        return !((stat == null ? void 0 : stat.t) && now - stat.t < STAT_MAX_AGE_MS);
      });
    }
    async run(players, { onProgress, shouldStop } = {}) {
      const byId = { ...this.data.byId || {} };
      const stale = this.stalePlayers(players);
      const total = stale.length;
      let done = 0;
      let index = 0;
      while (index < stale.length) {
        if (shouldStop == null ? void 0 : shouldStop()) break;
        const windowStart = Date.now();
        const capacity = Math.max(1, this.api.capacityPerWindow());
        const slice = stale.slice(index, index + capacity);
        const tasks = slice.map((p) => ({ path: `/user/${p.id}/hof` }));
        const results = await this.api.runBatch(tasks, {
          onProgress: (doneInWindow) => onProgress == null ? void 0 : onProgress(done + doneInWindow, total),
          shouldStop
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
          if ((workstats == null ? void 0 : workstats.value) != null) {
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
        onProgress == null ? void 0 : onProgress(done, total);
        if (index < stale.length) {
          const elapsed = Date.now() - windowStart;
          if (elapsed < WINDOW_MS) await interruptibleSleep(WINDOW_MS - elapsed, shouldStop);
        }
      }
      return this.data;
    }
  }
  class StatusRefresh {
    constructor(api) {
      this.api = api;
      this.data = Store.get("status", { byId: {}, fetchedAt: null });
    }
    async refresh(companyIds, { onProgress, shouldStop } = {}) {
      var _a;
      const tasks = companyIds.map((id) => ({ path: `/company/${id}/employees` }));
      const results = await this.api.runBatch(tasks, { onProgress, shouldStop });
      const byId = this.data.byId || {};
      for (const result of results) {
        if (!result || result instanceof Error) continue;
        for (const employee of result.employees || []) {
          const action = employee.last_action || {};
          byId[employee.id] = {
            status: action.status || "Offline",
            relative: action.relative || "",
            timestamp: action.timestamp || null,
            position: typeof employee.position === "object" ? (_a = employee.position) == null ? void 0 : _a.name : employee.position,
            days: employee.days_in_company ?? null
          };
        }
      }
      this.data = { byId, fetchedAt: Date.now() };
      Store.set("status", this.data);
      return this.data;
    }
  }
  class Dom {
    static ready(selector, callback) {
      const el = document.querySelector(selector);
      if (el) return callback(el);
      new MutationObserver((_, observer) => {
        const el2 = document.querySelector(selector);
        if (el2) {
          observer.disconnect();
          callback(el2);
        }
      }).observe(document.documentElement, { childList: true, subtree: true });
    }
    static el(tag, className, text) {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== void 0) node.textContent = text;
      return node;
    }
  }
  const SUBSCRIPTION_RECHECK_MS = 6 * 36e5;
  class Overlay {
    constructor(auth) {
      this.auth = auth;
      this.screens = {};
      this.current = null;
      this.backdrop = null;
      this.panel = null;
      this.body = null;
    }
    register(name, screen) {
      this.screens[name] = screen;
    }
    mount() {
      if (this.backdrop) return;
      this.backdrop = Dom.el("div", "rc-backdrop");
      this.backdrop.addEventListener("click", (e) => {
        if (e.target === this.backdrop) this.close();
      });
      this.panel = Dom.el("div", "rc-panel");
      const head = Dom.el("div", "rc-head");
      const logo = Dom.el("span", "rc-logo", "R");
      const title = Dom.el("div", "rc-head-text");
      title.append(Dom.el("div", "rc-head-title", "Recruiter"), this.subtitle = Dom.el("div", "rc-head-sub", ""));
      this.nav = Dom.el("div", "rc-nav");
      for (const [name, label] of [["overview", "Overview"], ["setup", "Setup"], ["keys", "Keys"]]) {
        const link = Dom.el("button", "rc-nav-link", label);
        link.dataset.screen = name;
        link.addEventListener("click", () => this.show(name));
        this.nav.appendChild(link);
      }
      const close = Dom.el("button", "rc-close", "×");
      close.addEventListener("click", () => this.close());
      head.append(logo, title, this.nav, close);
      this.body = Dom.el("div", "rc-body");
      this.footer = Dom.el("div", "rc-footer");
      this.panel.append(head, this.body, this.footer);
      this.backdrop.appendChild(this.panel);
      document.body.appendChild(this.backdrop);
    }
    renderFooter() {
      this.footer.replaceChildren();
      const links = Dom.el("div", "rc-footer-links");
      const user = this.auth.getUser();
      if (user) {
        const profile = Dom.el("a", "rc-footer-user", `${user.name} [${user.torn_id}]`);
        profile.href = `https://www.torn.com/profiles.php?XID=${user.torn_id}`;
        profile.target = "_blank";
        profile.rel = "noopener";
        links.append(profile, Dom.el("span", null, "·"));
      }
      const privacy = Dom.el("button", "rc-footer-link", "Privacy Policy");
      privacy.addEventListener("click", () => this.openLegal("rc-privacy"));
      const terms = Dom.el("button", "rc-footer-link", "Terms of Service");
      terms.addEventListener("click", () => this.openLegal("rc-terms"));
      const debug = Dom.el("button", "rc-footer-link", "Copy debug info");
      debug.addEventListener("click", () => this.copyDebugInfo(debug));
      links.append(privacy, Dom.el("span", null, "·"), terms, Dom.el("span", null, "·"), debug);
      this.footer.appendChild(links);
      this.footer.appendChild(Dom.el("div", "rc-footer-version", `v${"0.4.1"}`));
    }
    openLegal(anchor) {
      const legal = this.screens.legal;
      if (legal) legal.anchor = anchor;
      this.show("legal");
    }
    copyDebugInfo(button) {
      const roster = Store.get("roster");
      const stats = Store.get("stats");
      const status = Store.get("status");
      const info = {
        version: "0.4.1",
        generatedAt: (/* @__PURE__ */ new Date()).toISOString(),
        user: this.auth.getUser() ? { name: this.auth.getUser().name, tornId: this.auth.getUser().torn_id } : null,
        subscribed: this.auth.isSubscribed(),
        settings: Store.get("settings"),
        keys: (Store.get("keys", []) || []).map((k) => ({
          key: `${k.key.slice(0, 4)}…${k.key.slice(-4)}`,
          owner: `${k.ownerName} [${k.ownerId}]`,
          accessType: k.accessType,
          valid: k.valid,
          callsToday: k.callsToday
        })),
        roster: roster ? { companies: Object.keys(roster.companies).length, players: roster.players.length, fetchedAt: roster.fetchedAt } : null,
        stats: (stats == null ? void 0 : stats.fetchedAt) ? { entries: Object.keys(stats.byId).length, floor: stats.floor, fetchedAt: stats.fetchedAt } : null,
        status: (status == null ? void 0 : status.fetchedAt) ? { entries: Object.keys(status.byId).length, fetchedAt: status.fetchedAt } : null,
        userAgent: navigator.userAgent
      };
      navigator.clipboard.writeText(JSON.stringify(info, null, 2)).then(() => button.textContent = "Copied!").catch(() => button.textContent = "Copy failed").finally(() => setTimeout(() => button.textContent = "Copy debug info", 2e3));
    }
    gateScreen() {
      if (!this.auth.isAuthenticated()) return "auth";
      if (!this.auth.isSubscribed()) return "subscription";
      return null;
    }
    show(name) {
      var _a;
      this.mount();
      const gate = this.gateScreen();
      if (gate && name !== "legal") name = gate;
      this.current = name;
      this.nav.style.display = gate || name === "legal" ? "none" : "flex";
      this.nav.querySelectorAll(".rc-nav-link").forEach((link) => {
        link.classList.toggle("rc-nav-link--active", link.dataset.screen === name);
      });
      const screen = this.screens[name];
      this.subtitle.textContent = ((_a = screen.subtitle) == null ? void 0 : _a.call(screen)) || "";
      this.body.replaceChildren();
      screen.render(this.body);
      this.renderFooter();
    }
    open(name = null) {
      this.mount();
      this.backdrop.classList.add("rc-backdrop--visible");
      this.show(name || this.defaultScreen());
      this.recheckSubscription();
    }
    recheckSubscription() {
      var _a;
      if (this.gateScreen()) return;
      const checkedAt = ((_a = this.auth.subscription()) == null ? void 0 : _a.checkedAt) || 0;
      if (Date.now() - checkedAt < SUBSCRIPTION_RECHECK_MS) return;
      this.auth.fetchSubscription().then(() => {
        if (this.gateScreen()) this.open();
      }).catch(() => null);
    }
    close() {
      var _a;
      (_a = this.backdrop) == null ? void 0 : _a.classList.remove("rc-backdrop--visible");
    }
    toggle() {
      this.mount();
      if (this.backdrop.classList.contains("rc-backdrop--visible")) {
        this.close();
      } else {
        this.open();
      }
    }
    defaultScreen() {
      var _a;
      return ((_a = this.screens.keys) == null ? void 0 : _a.hasKeys()) ? "overview" : "keys";
    }
    refresh() {
      var _a;
      if (this.current && ((_a = this.backdrop) == null ? void 0 : _a.classList.contains("rc-backdrop--visible"))) {
        this.show(this.current);
      }
    }
  }
  class Sidebar {
    constructor(overlay) {
      this.overlay = overlay;
    }
    init() {
      Dom.ready("#sidebar", (sidebar) => this.onReady(sidebar));
    }
    onReady(sidebar) {
      const icons = sidebar.querySelector("ul[class^='status-icon']");
      if (!icons || document.getElementById("recruiter-icon")) return;
      const icon = document.createElement("li");
      icon.id = "recruiter-icon";
      icon.className = "recruiter-icon";
      icon.onclick = () => this.overlay.toggle();
      icons.appendChild(icon);
    }
  }
  class MenuEntry {
    constructor(overlay) {
      this.overlay = overlay;
    }
    init() {
      Dom.ready("ul.settings-menu", (menu) => this.inject(menu));
      document.addEventListener("click", (e) => {
        if (e.target.closest(".avatar, .settings-menu")) this.injectAll();
      });
    }
    injectAll() {
      document.querySelectorAll("ul.settings-menu").forEach((menu) => this.inject(menu));
    }
    inject(menu) {
      if (menu.querySelector(".recruiter-menu-item")) return;
      const item = document.createElement("li");
      item.className = "link recruiter-menu-item";
      const link = document.createElement("a");
      link.href = window.location.href;
      link.innerHTML = '<span class="recruiter-menu-icon"></span><span>Recruiter</span>';
      link.addEventListener("click", (e) => {
        e.preventDefault();
        this.overlay.open();
      });
      item.appendChild(link);
      const serverInfo = menu.querySelector(".server-info");
      if (serverInfo) {
        menu.insertBefore(item, serverInfo);
      } else {
        menu.appendChild(item);
      }
    }
  }
  class ChatOpener {
    static chatUrl(playerId) {
      return `https://www.torn.com/profiles.php?XID=${playerId}#rc-chat`;
    }
    init() {
      if (!location.pathname.startsWith("/profiles.php")) return;
      if (!location.hash.includes("rc-chat")) return;
      Dom.ready(".profile-button-initiateChat", (button) => {
        history.replaceState(null, "", location.href.replace("#rc-chat", ""));
        setTimeout(() => button.click(), 600);
      });
    }
  }
  const bannerSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 180" role="img" aria-label="Recruiter scanning players">\n  <style>\n    .rb-fill { fill: #3a3a3e; }\n    .rb-barbg { fill: #232326; }\n    .rb-bar { fill: #3f3f45; }\n    .rb-bar--top { fill: #0070f3; }\n    .rb-lens { animation: rb-move 10s ease-in-out infinite, rb-fade 10s linear infinite; }\n    .rb-star { opacity: 0; transform-box: fill-box; transform-origin: center; animation: rb-star 10s ease-out infinite; animation-delay: 6s; }\n    .rb-p1 .rb-fill { animation: rb-lit 10s linear infinite; }\n    .rb-p2 .rb-fill { animation: rb-lit 10s linear infinite; animation-delay: 2s; }\n    .rb-p3 .rb-fill { animation: rb-lit 10s linear infinite; animation-delay: 4s; }\n    .rb-p4 .rb-fill { animation: rb-lit 10s linear infinite; animation-delay: 6s; }\n    .rb-p5 .rb-fill { animation: rb-lit 10s linear infinite; animation-delay: 8s; }\n\n    @keyframes rb-move {\n      0%, 14% { transform: translateX(0); }\n      20%, 34% { transform: translateX(75px); }\n      40%, 54% { transform: translateX(150px); }\n      60%, 74% { transform: translateX(225px); }\n      80%, 100% { transform: translateX(300px); }\n    }\n    @keyframes rb-fade {\n      0% { opacity: 0; }\n      3%, 93% { opacity: 1; }\n      98%, 100% { opacity: 0; }\n    }\n    @keyframes rb-lit {\n      0%, 16% { fill: #4a9df8; }\n      19%, 100% { fill: #3a3a3e; }\n    }\n    @keyframes rb-star {\n      0%, 2% { opacity: 0; transform: scale(0.4); }\n      6%, 16% { opacity: 1; transform: scale(1); }\n      20%, 100% { opacity: 0; transform: scale(0.6); }\n    }\n\n    @media (prefers-reduced-motion: reduce) {\n      .rb-lens, .rb-star,\n      .rb-p1 .rb-fill, .rb-p2 .rb-fill, .rb-p3 .rb-fill, .rb-p4 .rb-fill, .rb-p5 .rb-fill { animation: none; }\n      .rb-lens { transform: translateX(225px); opacity: 1; }\n      .rb-p4 .rb-fill { fill: #4a9df8; }\n      .rb-star { opacity: 1; }\n    }\n  </style>\n\n  <rect x="0.5" y="0.5" width="479" height="179" rx="10" fill="#141416" stroke="#2a2a2c"/>\n\n  <rect x="20" y="18" width="16" height="16" rx="4" fill="#0070f3"/>\n  <text x="28" y="30.5" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-weight="900" font-size="11" fill="#ffffff">R</text>\n  <text x="46" y="30.5" font-family="Arial, Helvetica, sans-serif" font-weight="700" font-size="11" letter-spacing="3.5" fill="#9a9aa2">RECRUITER</text>\n\n  <g class="rb-p1">\n    <circle class="rb-fill" cx="90" cy="88" r="11"/>\n    <path class="rb-fill" d="M72 132q0-26 18-26q18 0 18 26z"/>\n    <rect class="rb-barbg" x="73" y="140" width="34" height="5" rx="2.5"/>\n    <rect class="rb-bar" x="73" y="140" width="14" height="5" rx="2.5"/>\n  </g>\n  <g class="rb-p2">\n    <circle class="rb-fill" cx="165" cy="88" r="11"/>\n    <path class="rb-fill" d="M147 132q0-26 18-26q18 0 18 26z"/>\n    <rect class="rb-barbg" x="148" y="140" width="34" height="5" rx="2.5"/>\n    <rect class="rb-bar" x="148" y="140" width="22" height="5" rx="2.5"/>\n  </g>\n  <g class="rb-p3">\n    <circle class="rb-fill" cx="240" cy="88" r="11"/>\n    <path class="rb-fill" d="M222 132q0-26 18-26q18 0 18 26z"/>\n    <rect class="rb-barbg" x="223" y="140" width="34" height="5" rx="2.5"/>\n    <rect class="rb-bar" x="223" y="140" width="10" height="5" rx="2.5"/>\n  </g>\n  <g class="rb-p4">\n    <circle class="rb-fill" cx="315" cy="88" r="11"/>\n    <path class="rb-fill" d="M297 132q0-26 18-26q18 0 18 26z"/>\n    <rect class="rb-barbg" x="298" y="140" width="34" height="5" rx="2.5"/>\n    <rect class="rb-bar rb-bar--top" x="298" y="140" width="31" height="5" rx="2.5"/>\n  </g>\n  <g class="rb-p5">\n    <circle class="rb-fill" cx="390" cy="88" r="11"/>\n    <path class="rb-fill" d="M372 132q0-26 18-26q18 0 18 26z"/>\n    <rect class="rb-barbg" x="373" y="140" width="34" height="5" rx="2.5"/>\n    <rect class="rb-bar" x="373" y="140" width="18" height="5" rx="2.5"/>\n  </g>\n\n  <path class="rb-star" d="M338 52l2.9 6.2 6.8.9-5 4.7 1.3 6.7-6-3.3-6 3.3 1.3-6.7-5-4.7 6.8-.9z" fill="#e8b93d"/>\n\n  <g class="rb-lens">\n    <circle cx="90" cy="90" r="26" fill="rgba(0,112,243,0.10)" stroke="#0070f3" stroke-width="4"/>\n    <line x1="109" y1="109" x2="124" y2="124" stroke="#0070f3" stroke-width="6" stroke-linecap="round"/>\n  </g>\n</svg>\n';
  const DISCLOSURE = [
    ["Data Storage", "Persistent until you remove your key"],
    ["Data Sharing", "Nobody (your data is private)"],
    ["Purpose of Use", "Signing in and verifying your TornManager subscription"],
    ["Key Storage & Sharing", "Stored in the TornManager database, used only for verification"],
    ["Key Access Level", "Public access (required)"]
  ];
  class AuthScreen {
    constructor(auth, overlay, keys, api) {
      this.auth = auth;
      this.overlay = overlay;
      this.keys = keys;
      this.api = api;
    }
    subtitle() {
      return "sign in";
    }
    render(container) {
      const wrap = Dom.el("div", "rc-auth");
      const banner = Dom.el("div", "rc-auth-banner");
      banner.innerHTML = bannerSvg;
      wrap.appendChild(banner);
      const form = Dom.el("form", "rc-auth-form");
      const row = Dom.el("div", "rc-auth-row");
      const input = Dom.el("input", "rc-auth-input");
      input.type = "text";
      input.placeholder = "Add Public Torn API key";
      input.autocomplete = "off";
      input.spellcheck = false;
      const button = Dom.el("button", "rc-auth-button", "Sign in");
      button.type = "submit";
      button.disabled = true;
      const error = Dom.el("p", "rc-auth-error");
      row.append(input, button);
      form.append(row, error);
      const tos = Dom.el("div", "rc-tos");
      tos.appendChild(Dom.el("p", "rc-tos-heading", "How your key and data are handled"));
      const grid = Dom.el("div", "rc-tos-grid");
      for (const [label, value] of DISCLOSURE) {
        const item = Dom.el("div", "rc-tos-item");
        item.append(Dom.el("span", "rc-tos-label", label), Dom.el("span", "rc-tos-value", value));
        grid.appendChild(item);
      }
      tos.appendChild(grid);
      const agree = Dom.el("label", "rc-tos-agree");
      const checkbox = Dom.el("input");
      checkbox.type = "checkbox";
      checkbox.addEventListener("change", () => {
        button.disabled = !checkbox.checked;
      });
      const agreeText = Dom.el("span");
      agreeText.append("I agree to the ", this.legalLink("Privacy Policy", "rc-privacy"), " and ", this.legalLink("Terms of Service", "rc-terms"), ".");
      agree.append(checkbox, agreeText);
      tos.appendChild(agree);
      form.appendChild(tos);
      form.addEventListener("submit", async (e) => {
        e.preventDefault();
        if (!checkbox.checked) return;
        const apiKey = input.value.trim();
        if (!apiKey) {
          error.textContent = "Please enter an API key.";
          return;
        }
        button.disabled = true;
        button.textContent = "Signing in...";
        error.textContent = "";
        try {
          await this.requirePublicAccess(apiKey);
          await this.auth.authenticate(apiKey);
          await this.auth.fetchSubscription().catch(() => null);
          await this.addToPool(apiKey);
          this.overlay.open();
        } catch (err) {
          error.textContent = err.message;
          button.disabled = false;
          button.textContent = "Sign in";
        }
      });
      const hint = Dom.el("p", "rc-auth-hint");
      hint.innerHTML = 'A key with <strong>Public</strong> access is all this script needs, and it accepts nothing else. <a href="https://www.torn.com/preferences.php#tab=api" target="_blank" rel="noopener">Create one here</a>.';
      wrap.append(form, hint);
      container.appendChild(wrap);
    }
    legalLink(label, anchor) {
      const link = Dom.el("a", null, label);
      link.href = "#";
      link.addEventListener("click", (e) => {
        e.preventDefault();
        this.overlay.openLegal(anchor);
      });
      return link;
    }
    async requirePublicAccess(apiKey) {
      var _a;
      let access;
      try {
        const info = await this.api.call("/key/info", {}, apiKey);
        access = ((_a = info.info) == null ? void 0 : _a.access) || info.access || {};
      } catch (err) {
        throw new Error(err.message || "Could not validate the key with Torn", { cause: err });
      }
      const type = String(access.type || "");
      if (!/public/i.test(type)) {
        throw new Error(`This key has ${type || "unknown"} access. Recruiter only accepts Public access keys.`);
      }
    }
    async addToPool(apiKey) {
      const user = this.auth.getUser();
      if (!user) return;
      const pool = this.keys.all();
      if (pool.some((k) => k.ownerId === user.torn_id || k.key === apiKey)) return;
      await this.keys.add(apiKey, this.api).catch(() => null);
    }
  }
  class SubscriptionScreen {
    constructor(auth, overlay) {
      this.auth = auth;
      this.overlay = overlay;
      this.countdownInterval = null;
    }
    subtitle() {
      return "subscription";
    }
    render(container) {
      this.stopCountdown();
      const wrap = Dom.el("div", "rc-sub");
      wrap.appendChild(Dom.el("h2", "rc-sub-title", "Subscription"));
      const note = Dom.el("p", "rc-sub-note");
      note.textContent = "Recruiter is a TornManager subscriber extra. The script stays locked until your subscription is active.";
      wrap.appendChild(note);
      this.statusEl = Dom.el("div", "rc-sub-status");
      this.countdownEl = Dom.el("p", "rc-sub-countdown");
      wrap.append(this.statusEl, this.countdownEl);
      this.refreshBtn = Dom.el("button", "rc-sub-refresh", "Check for new payments");
      this.refreshBtn.onclick = () => this.load(true);
      wrap.appendChild(this.refreshBtn);
      const info = Dom.el("div", "rc-sub-info");
      info.innerHTML = 'Send <strong>Xanax</strong> to <a href="https://www.torn.com/profiles.php?XID=2728237" target="_blank" rel="noopener">Bram [2728237]</a> to extend your subscription. Each Xanax adds <strong>1 week</strong>. Payments are checked automatically once a day.';
      wrap.appendChild(info);
      const actions = Dom.el("div", "rc-actions-row");
      const removeKey = Dom.el("button", "rc-btn-danger", "Remove API key");
      removeKey.addEventListener("click", () => {
        this.stopCountdown();
        this.auth.clear();
        this.overlay.open();
      });
      actions.appendChild(removeKey);
      wrap.appendChild(actions);
      container.appendChild(wrap);
      this.renderState(this.auth.subscription());
      this.load(false);
    }
    load(refresh) {
      this.refreshBtn.disabled = true;
      this.refreshBtn.textContent = refresh ? "Checking..." : "Loading...";
      this.auth.fetchSubscription({ refresh }).then((sub) => {
        if (sub.active && this.auth.isSubscribed()) {
          this.stopCountdown();
          this.overlay.open();
          return;
        }
        this.renderState(sub);
      }).catch((err) => {
        this.statusEl.textContent = err.message;
        this.statusEl.className = `rc-sub-status ${err.rateLimited ? "rc-sub-status--warn" : "rc-sub-status--error"}`;
        this.countdownEl.textContent = "";
      }).finally(() => {
        this.refreshBtn.disabled = false;
        this.refreshBtn.textContent = "Check for new payments";
      });
    }
    renderState(sub) {
      this.stopCountdown();
      if ((sub == null ? void 0 : sub.active) && sub.expires_at) {
        this.statusEl.textContent = "Active";
        this.statusEl.className = "rc-sub-status rc-sub-status--active";
        this.startCountdown(new Date(sub.expires_at));
      } else {
        this.statusEl.textContent = "Inactive";
        this.statusEl.className = "rc-sub-status rc-sub-status--inactive";
        this.countdownEl.textContent = "No active subscription.";
      }
    }
    startCountdown(expiresAt) {
      const tick = () => {
        const diff = expiresAt - Date.now();
        if (diff <= 0) {
          this.countdownEl.textContent = "Expired";
          this.stopCountdown();
          return;
        }
        const days = Math.floor(diff / 864e5);
        const hours = Math.floor(diff % 864e5 / 36e5);
        const minutes = Math.floor(diff % 36e5 / 6e4);
        const seconds = Math.floor(diff % 6e4 / 1e3);
        const parts = [];
        if (days > 0) parts.push(`${days}d`);
        parts.push(`${hours}h`, `${minutes}m`, `${seconds}s`);
        this.countdownEl.textContent = parts.join(" ") + " remaining";
      };
      tick();
      this.countdownInterval = setInterval(tick, 1e3);
    }
    stopCountdown() {
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
      }
    }
  }
  const PRIVACY_HTML = `
<h2 id="rc-privacy">Privacy Policy</h2>
<p class="rc-legal-sub">Last updated: 19 August 2026</p>

<h3>Introduction</h3>
<p>Hi, I'm Bram, the creator of Recruiter and TornManager. This Privacy Policy covers the <strong>Recruiter userscript</strong>, the script you install in a userscript manager (such as Tampermonkey) or in Torn PDA. It runs on Torn.com pages and helps you find recruitable players in Torn companies.</p>

<h3>Information I collect</h3>
<p>When you sign in you provide your <strong>Torn API key</strong> (Public access only). The key is sent to the TornManager server to check who you are with the official Torn API and to verify your subscription. On the server, your account consists of your Torn ID, player name, level, your API key as the sign-in credential, and Xanax payments with subscription expiration dates. Recruiter shares this account with the TornManager userscript: one subscription covers both.</p>

<h3>What stays in your browser</h3>
<p>Everything Recruiter collects to do its job stays on your device: additional API keys you add to the key pool, company rosters, player working stats, online status data, and your settings. None of it is uploaded anywhere. Additional pool keys are <strong>never sent to the TornManager server</strong>; they are used only for direct calls to the official Torn API.</p>

<h3>Calls to the Torn API</h3>
<p>Recruiter fetches public data (company listings, employee lists, Hall of Fame working stats) directly from api.torn.com using the keys in your pool. Every call carries the comment "Recruiter" so any key owner can see in their own Torn log what the key was used for. Only add keys that their owners gave you willingly.</p>

<h3>Data sharing</h3>
<p>Nobody. I do not sell, rent, or share any of this data. The recruiting data on your device is yours.</p>

<h3>Data removal</h3>
<p>Use "Remove API key" to sign out and delete your local session, or remove individual pool keys on the Keys screen. To remove your account and key from the TornManager server, contact me in Torn: <strong>Bram [2728237]</strong>.</p>
`;
  const TOS_HTML = `
<h2 id="rc-terms">Terms of Service</h2>
<p class="rc-legal-sub">Last updated: 19 August 2026</p>

<h3>The service</h3>
<p>Recruiter is a Torn userscript that surfaces publicly available game data (company rosters, working stats from the Hall of Fame, online status) to help with company recruiting. It is provided as is, without warranty of any kind. It is a hobby project, not a company.</p>

<h3>Subscription</h3>
<p>Recruiter requires an active <strong>TornManager subscription</strong>. Send Xanax to Bram [2728237] in Torn to extend it; each Xanax adds one week. The same subscription unlocks the TornManager userscript extras. Payments are voluntary, non-refundable, and are not purchases of goods or services outside of Torn.</p>

<h3>Your responsibilities</h3>
<p>You are responsible for complying with Torn's own rules while using Recruiter. Only Public access keys are accepted, and you may only add pool keys that their owners handed you voluntarily. Do not use Recruiter to harass players. What you do with the information it shows you is your responsibility.</p>

<h3>Fair use</h3>
<p>Recruiter paces its Torn API usage to stay well inside Torn's rate limits per key owner. Do not attempt to modify the script to exceed those limits.</p>

<h3>Changes and termination</h3>
<p>I may update, change, or discontinue Recruiter at any time. I may suspend accounts that abuse the service. If a suspension or discontinuation happens with time left on your subscription, contact me and we will sort it out.</p>

<h3>Contact</h3>
<p>Questions about these terms: message <strong>Bram [2728237]</strong> in Torn.</p>
`;
  class LegalScreen {
    constructor(overlay) {
      this.overlay = overlay;
      this.anchor = null;
    }
    subtitle() {
      return "privacy & terms";
    }
    render(container) {
      const wrap = Dom.el("div", "rc-legal");
      const back = Dom.el("button", "rc-btn rc-btn--ghost", "← Back");
      back.addEventListener("click", () => this.overlay.open());
      wrap.appendChild(back);
      const docs = Dom.el("div", "rc-legal-docs");
      docs.innerHTML = PRIVACY_HTML + '<hr class="rc-legal-divider">' + TOS_HTML;
      wrap.appendChild(docs);
      container.appendChild(wrap);
      if (this.anchor) {
        const target = docs.querySelector(`#${this.anchor}`);
        if (target) requestAnimationFrame(() => target.scrollIntoView({ block: "start" }));
        this.anchor = null;
      }
    }
  }
  const CALLS_PER_KEY_PER_MINUTE = 75;
  class KeysScreen {
    constructor(keys, api, overlay, auth) {
      this.keys = keys;
      this.api = api;
      this.overlay = overlay;
      this.auth = auth;
    }
    hasKeys() {
      return this.keys.active().length > 0;
    }
    subtitle() {
      return "api keys";
    }
    render(container) {
      var _a;
      const addCard = Dom.el("div", "rc-card");
      const label = Dom.el("div", "rc-label", "Add a key (public access is enough)");
      const row = Dom.el("div", "rc-row");
      const input = Dom.el("input", "rc-input");
      input.type = "text";
      input.placeholder = "paste key…";
      const button = Dom.el("button", "rc-btn", "Add & validate");
      const feedback = Dom.el("div", "rc-feedback");
      button.addEventListener("click", async () => {
        button.disabled = true;
        button.textContent = "Validating…";
        feedback.textContent = "";
        feedback.className = "rc-feedback";
        try {
          const entry = await this.keys.add(input.value, this.api);
          feedback.textContent = `Added ${entry.ownerName} [${entry.ownerId}] · ${entry.accessType}`;
          feedback.classList.add("rc-feedback--ok");
          input.value = "";
          this.overlay.refresh();
        } catch (error) {
          feedback.textContent = error.message;
          feedback.classList.add("rc-feedback--error");
        } finally {
          button.disabled = false;
          button.textContent = "Add & validate";
        }
      });
      row.append(input, button);
      addCard.append(label, row, feedback);
      container.appendChild(addCard);
      const list = Dom.el("div", "rc-list");
      for (const entry of this.keys.all()) {
        const item = Dom.el("div", "rc-list-row");
        const badge = Dom.el("span", `rc-badge ${entry.valid ? "rc-badge--fresh" : "rc-badge--stale"}`, entry.valid ? "valid" : "invalid");
        const masked = Dom.el("span", "rc-mono", `${entry.key.slice(0, 4)}…${entry.key.slice(-4)}`);
        const isSignIn = entry.ownerId === ((_a = this.auth.getUser()) == null ? void 0 : _a.torn_id);
        const owner = Dom.el("span", "rc-dim", `${entry.ownerName} [${entry.ownerId}] · ${entry.accessType}${isSignIn ? " · sign-in key" : ""}`);
        const usage = Dom.el("span", "rc-dim", `${entry.callsToday.toLocaleString()} calls today`);
        const remove = Dom.el("button", "rc-act", "✕");
        remove.addEventListener("click", () => {
          this.keys.remove(entry.key);
          this.overlay.refresh();
        });
        item.append(badge, masked, owner, usage, remove);
        list.appendChild(item);
      }
      container.appendChild(list);
      const count = this.keys.active().length;
      const budget = count * CALLS_PER_KEY_PER_MINUTE;
      const summary = Dom.el(
        "div",
        "rc-scope",
        count ? `${count} key${count === 1 ? "" : "s"}, ${count} player${count === 1 ? "" : "s"} · budget ~${budget} calls/min (${CALLS_PER_KEY_PER_MINUTE} per key, headroom kept)` : "No keys yet. Every key must come from a different player, Torn's 100/min limit is per player."
      );
      container.appendChild(summary);
      container.appendChild(this.subscriptionCard());
    }
    subscriptionCard() {
      this.stopCountdown();
      const card = Dom.el("div", "rc-card rc-subcard");
      card.appendChild(Dom.el("div", "rc-label", "TornManager subscription"));
      const row = Dom.el("div", "rc-subcard-row");
      const badge = Dom.el("span", "rc-badge");
      const countdown = Dom.el("span", "rc-subcard-count");
      const check = Dom.el("button", "rc-btn rc-btn--ghost", "Check for new payments");
      row.append(badge, countdown, check);
      card.appendChild(row);
      const info = Dom.el("div", "rc-hint");
      info.innerHTML = 'Send <strong>Xanax</strong> to <a href="https://www.torn.com/profiles.php?XID=2728237" target="_blank" rel="noopener">Bram [2728237]</a> to extend it. Each Xanax adds <strong>1 week</strong>.';
      card.appendChild(info);
      const apply = (sub) => {
        this.stopCountdown();
        if ((sub == null ? void 0 : sub.active) && sub.expires_at) {
          badge.className = "rc-badge rc-badge--fresh";
          badge.textContent = "active";
          const expiresAt = new Date(sub.expires_at);
          const tick = () => {
            const diff = expiresAt - Date.now();
            if (diff <= 0) {
              countdown.textContent = "Expired";
              this.stopCountdown();
              return;
            }
            const days = Math.floor(diff / 864e5);
            const hours = Math.floor(diff % 864e5 / 36e5);
            const minutes = Math.floor(diff % 36e5 / 6e4);
            const seconds = Math.floor(diff % 6e4 / 1e3);
            const parts = [];
            if (days > 0) parts.push(`${days}d`);
            parts.push(`${hours}h`, `${minutes}m`, `${seconds}s`);
            countdown.textContent = parts.join(" ") + " remaining";
          };
          tick();
          this.countdownInterval = setInterval(tick, 1e3);
        } else {
          badge.className = "rc-badge rc-badge--stale";
          badge.textContent = "inactive";
          countdown.textContent = "No active subscription.";
        }
      };
      check.addEventListener("click", () => {
        check.disabled = true;
        check.textContent = "Checking...";
        this.auth.fetchSubscription({ refresh: true }).then((sub) => apply(sub)).catch((err) => {
          countdown.textContent = err.message;
        }).finally(() => {
          check.disabled = false;
          check.textContent = "Check for new payments";
        });
      });
      apply(this.auth.subscription());
      return card;
    }
    stopCountdown() {
      if (this.countdownInterval) {
        clearInterval(this.countdownInterval);
        this.countdownInterval = null;
      }
    }
  }
  const COMPANY_TYPES = [
    { id: 1, name: "Hair Salon" },
    { id: 2, name: "Law Firm" },
    { id: 3, name: "Flower Shop" },
    { id: 4, name: "Car Dealership" },
    { id: 5, name: "Clothing Store" },
    { id: 6, name: "Gun Shop" },
    { id: 7, name: "Game Shop" },
    { id: 8, name: "Candle Shop" },
    { id: 9, name: "Toy Shop" },
    { id: 10, name: "Adult Novelties" },
    { id: 11, name: "Cyber Cafe" },
    { id: 12, name: "Grocery Store" },
    { id: 13, name: "Theater" },
    { id: 14, name: "Sweet Shop" },
    { id: 15, name: "Cruise Line" },
    { id: 16, name: "Television Network" },
    { id: 18, name: "Zoo" },
    { id: 19, name: "Firework Stand" },
    { id: 20, name: "Property Broker" },
    { id: 21, name: "Furniture Store" },
    { id: 22, name: "Gas Station" },
    { id: 23, name: "Music Store" },
    { id: 24, name: "Nightclub" },
    { id: 25, name: "Pub" },
    { id: 26, name: "Gents Strip Club" },
    { id: 27, name: "Restaurant" },
    { id: 28, name: "Oil Rig" },
    { id: 29, name: "Fitness Center" },
    { id: 30, name: "Mechanic Shop" },
    { id: 31, name: "Amusement Park" },
    { id: 32, name: "Lingerie Store" },
    { id: 33, name: "Meat Warehouse" },
    { id: 34, name: "Farm" },
    { id: 35, name: "Software Corporation" },
    { id: 36, name: "Ladies Strip Club" },
    { id: 37, name: "Private Security Firm" },
    { id: 38, name: "Mining Corporation" },
    { id: 39, name: "Detective Agency" },
    { id: 40, name: "Logistics Management" }
  ];
  function typeName(id) {
    var _a;
    return ((_a = COMPANY_TYPES.find((t) => t.id === Number(id))) == null ? void 0 : _a.name) || `Type ${id}`;
  }
  const DEFAULTS = {
    typeIds: [10],
    starMin: 8,
    starMax: 10,
    inactiveDays: 7
  };
  const STAR_RANGE = { min: 1, max: 10 };
  const INACTIVE_RANGE = { min: 1, max: 14 };
  const Settings = {
    get() {
      const settings = { ...DEFAULTS, ...Store.get("settings", {}) };
      settings.starMin = clamp(settings.starMin, STAR_RANGE.min, STAR_RANGE.max);
      settings.starMax = clamp(settings.starMax, settings.starMin, STAR_RANGE.max);
      settings.inactiveDays = clamp(settings.inactiveDays, INACTIVE_RANGE.min, INACTIVE_RANGE.max);
      delete settings.floor;
      return settings;
    },
    set(patch) {
      Store.set("settings", { ...this.get(), ...patch });
    }
  };
  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, Number(value) || min));
  }
  class SetupScreen {
    constructor(overlay) {
      this.overlay = overlay;
    }
    subtitle() {
      return "setup";
    }
    render(container) {
      const settings = Settings.get();
      const selected = new Set(settings.typeIds);
      const typeCard = Dom.el("div", "rc-card");
      typeCard.appendChild(Dom.el("div", "rc-label", "Company types to track"));
      const chips = Dom.el("div", "rc-chips");
      for (const type of COMPANY_TYPES) {
        const chip = Dom.el("button", "rc-chip", type.name);
        if (selected.has(type.id)) chip.classList.add("rc-chip--on");
        chip.addEventListener("click", () => {
          if (selected.has(type.id)) {
            selected.delete(type.id);
            chip.classList.remove("rc-chip--on");
          } else {
            selected.add(type.id);
            chip.classList.add("rc-chip--on");
          }
          Settings.set({ typeIds: [...selected].sort((a, b) => a - b) });
        });
        chips.appendChild(chip);
      }
      typeCard.appendChild(chips);
      container.appendChild(typeCard);
      const rangeCard = Dom.el("div", "rc-card");
      const row = Dom.el("div", "rc-row");
      row.appendChild(
        this.stepper("Min stars", settings.starMin, STAR_RANGE.min, settings.starMax, (value) => {
          Settings.set({ starMin: value });
        })
      );
      row.appendChild(
        this.stepper("Max stars", settings.starMax, settings.starMin, STAR_RANGE.max, (value) => {
          Settings.set({ starMax: value });
        })
      );
      row.appendChild(
        this.stepper("Ignore inactive over (days)", settings.inactiveDays, INACTIVE_RANGE.min, INACTIVE_RANGE.max, (value) => {
          Settings.set({ inactiveDays: value });
        })
      );
      rangeCard.appendChild(row);
      rangeCard.appendChild(
        Dom.el(
          "div",
          "rc-hint",
          "Everything saves automatically. Working stats are fetched once per employee of the tracked companies and cached for 10 days, so the cost scales with how many companies you track."
        )
      );
      container.appendChild(rangeCard);
      container.appendChild(Dom.el("div", "rc-hint", "Company type and star changes apply after the next roster update."));
    }
    stepper(labelText, value, min, max, onChange) {
      const wrap = Dom.el("div", "rc-field");
      wrap.appendChild(Dom.el("div", "rc-label", labelText));
      const control = Dom.el("div", "rc-stepper");
      const minus = Dom.el("button", "rc-stepper-btn", "−");
      const display = Dom.el("span", "rc-stepper-value", String(value));
      const plus = Dom.el("button", "rc-stepper-btn", "+");
      const apply = (next) => {
        onChange(next);
        this.overlay.refresh();
      };
      minus.addEventListener("click", () => {
        if (value > min) apply(value - 1);
      });
      plus.addEventListener("click", () => {
        if (value < max) apply(value + 1);
      });
      minus.disabled = value <= min;
      plus.disabled = value >= max;
      control.append(minus, display, plus);
      wrap.appendChild(control);
      return wrap;
    }
  }
  const PAGE_SIZE = 100;
  class OverviewScreen {
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
      var _a, _b, _c;
      const wrap = Dom.el("div", "rc-syncs");
      const companyCount = new Set(matches.map((m) => m.player.companyId)).size;
      const capacity = Math.max(1, this.api.capacityPerWindow());
      wrap.appendChild(this.syncRow({
        name: "Roster",
        desc: "who works where, ratings · 2 calls",
        fetchedAt: (_a = this.roster.data) == null ? void 0 : _a.fetchedAt,
        staleAfterHours: 24,
        action: () => this.updateRoster()
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
        fetchedAt: (_b = this.stats.data) == null ? void 0 : _b.fetchedAt,
        staleAfterHours: 24 * 10,
        action: () => this.updateStats()
      }));
      wrap.appendChild(this.syncRow({
        name: "Status",
        desc: `online state of ${matches.length} matches · ${companyCount} calls`,
        fetchedAt: (_c = this.status.data) == null ? void 0 : _c.fetchedAt,
        staleAfterHours: 1,
        action: () => this.updateStatus(matches)
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
        let message;
        let paused;
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
        onProgress: (done, total) => this.setBar({ done, total, unit: "employees" })
      });
      return staleCount ? `Working stats fetched for ${staleCount.toLocaleString()} employees (${(players.length - staleCount).toLocaleString()} were still fresh).` : "All employees were already fresh, nothing to fetch.";
    }
    async updateStatus(matches) {
      const companyIds = [...new Set(matches.map((m) => m.player.companyId))];
      if (!companyIds.length) return "No matches yet. Update the roster and working stats first.";
      await this.status.refresh(companyIds, {
        shouldStop: () => this.stopRequested,
        onProgress: (done, total) => this.setBar({ done, total, unit: "companies" })
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
      if (!this.ticker) this.ticker = setInterval(() => this.renderBar(), 1e3);
      this.renderBar();
    }
    stopTicker() {
      if (this.ticker) {
        clearInterval(this.ticker);
        this.ticker = null;
      }
    }
    renderBar() {
      var _a;
      if (!this.progress || !this.barState) return;
      const { done, total, unit, at } = this.barState;
      if (!((_a = this.barEl) == null ? void 0 : _a.isConnected) || this.barEl.parentElement !== this.progress) {
        this.barEl = Dom.el("div", "rc-bar");
        this.barFill = Dom.el("div", "rc-bar-fill");
        this.barText = Dom.el("span", "rc-bar-text");
        this.barEl.append(this.barFill, this.barText);
        this.progress.replaceChildren(this.barEl);
      }
      const ratePerSecond = Math.max(1, this.api.capacityPerWindow()) / 60;
      const elapsed = (Date.now() - at) / 1e3;
      const displayed = Math.min(total, Math.floor(done + ratePerSecond * elapsed));
      const fraction = total ? displayed / total : 1;
      this.barFill.style.width = `${Math.min(97, Math.max(3, fraction * 100)).toFixed(1)}%`;
      const remaining = (total - displayed) / ratePerSecond;
      const countdown = remaining < 1 ? "any moment now" : `~${formatDuration(remaining)} left`;
      this.barText.textContent = `${countdown} · ${displayed.toLocaleString()} of ${total.toLocaleString()} ${unit} fetched`;
    }
    matches(settings) {
      var _a, _b;
      const roster = this.roster.data;
      const stats = ((_a = this.stats.data) == null ? void 0 : _a.byId) || {};
      const statuses = ((_b = this.status.data) == null ? void 0 : _b.byId) || {};
      if (!roster) return [];
      const cutoff = Date.now() / 1e3 - settings.inactiveDays * 86400;
      const result = [];
      for (const player of roster.players) {
        if (player.director) continue;
        const stat = stats[player.id];
        if (!stat || !(stat.v > 0)) continue;
        const status = statuses[player.id];
        const lastAction = (status == null ? void 0 : status.timestamp) || stat.la;
        if (lastAction && lastAction < cutoff) continue;
        result.push({ player, company: roster.companies[player.companyId], stat, status });
      }
      return result.sort((a, b) => b.stat.v - a.stat.v);
    }
    filterByStatus(matches) {
      if (this.statusFilter === "online") return matches.filter((m) => {
        var _a;
        return ((_a = m.status) == null ? void 0 : _a.status) === "Online";
      });
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
        const dotClass = (status == null ? void 0 : status.status) === "Online" ? "rc-dot--on" : (status == null ? void 0 : status.status) === "Idle" ? "rc-dot--idle" : "rc-dot--off";
        state.append(Dom.el("span", `rc-dot ${dotClass}`), Dom.el("span", null, status ? `${status.status} · ${status.relative}` : "unknown"));
        const co = Dom.el("div");
        const coLink = Dom.el("a", "rc-name rc-name--co rc-link", (company == null ? void 0 : company.name) || "?");
        if (player.companyId) {
          coLink.href = `https://www.torn.com/joblist.php#/p=corpinfo&ID=${player.companyId}`;
          coLink.target = "_blank";
          coLink.rel = "noopener";
        }
        coLink.appendChild(Dom.el("span", "rc-star", ` ★ ${(company == null ? void 0 : company.rating) ?? "?"}`));
        const detail = [typeName(company == null ? void 0 : company.typeId), status == null ? void 0 : status.position, (status == null ? void 0 : status.days) != null ? `${status.days}d` : null].filter(Boolean).join(" · ");
        co.append(coLink, Dom.el("div", "rc-dim", detail));
        const acts = Dom.el("div", "rc-acts");
        const chat = Dom.el("a", "rc-act");
        chat.title = "Start Torn chat";
        chat.innerHTML = '<svg viewBox="0 0 16 16" width="12" height="12" fill="currentColor" aria-hidden="true"><path d="M8 1.5c-4 0-7 2.6-7 5.8 0 1.8.9 3.4 2.4 4.5-.1 1-.5 1.9-1.2 2.7 1.5-.1 2.8-.6 3.8-1.3.6.2 1.3.2 2 .2 4 0 7-2.6 7-5.8s-3-6.1-7-6.1z"/></svg>';
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
    const hours = (Date.now() - fetchedAt) / 36e5;
    const cls = hours < staleAfterHours ? "rc-badge--fresh" : hours < staleAfterHours * 2 ? "rc-badge--aging" : "rc-badge--stale";
    return Dom.el("span", `rc-badge ${cls}`, shortAge(fetchedAt));
  }
  function shortAge(fetchedAt) {
    if (!fetchedAt) return "";
    const minutes = Math.floor((Date.now() - fetchedAt) / 6e4);
    if (minutes < 1) return "just now";
    if (minutes < 60) return `${minutes} min ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 48) return `${hours}h ago`;
    return `${Math.floor(hours / 24)}d ago`;
  }
  function formatDuration(seconds) {
    seconds = Math.round(seconds);
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor(seconds % 3600 / 60);
    const secs = seconds % 60;
    if (hours) return `${hours}h ${String(minutes).padStart(2, "0")}m ${String(secs).padStart(2, "0")}s`;
    if (minutes) return `${minutes}m ${String(secs).padStart(2, "0")}s`;
    return `${secs}s`;
  }
  function boot() {
    const auth = new Auth(Store);
    const keys = new Keys();
    const api = new Api(keys);
    const roster = new Roster(api);
    const stats = new Stats(api);
    const status = new StatusRefresh(api);
    const overlay = new Overlay(auth);
    overlay.register("auth", new AuthScreen(auth, overlay, keys, api));
    overlay.register("subscription", new SubscriptionScreen(auth, overlay));
    overlay.register("legal", new LegalScreen(overlay));
    overlay.register("keys", new KeysScreen(keys, api, overlay, auth));
    overlay.register("setup", new SetupScreen(overlay));
    overlay.register("overview", new OverviewScreen({ roster, stats, status, api, overlay }));
    new Sidebar(overlay).init();
    new MenuEntry(overlay).init();
    new ChatOpener().init();
    console.log(`%cRecruiter %cv${"0.4.1"} is running.`, "font-weight: 700; color: #0070f3;", "color: inherit;");
  }
  if (window.self === window.top) boot();

})();