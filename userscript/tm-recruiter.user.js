// ==UserScript==
// @name         Torn Manager Recruiter
// @namespace    torn-recruiter
// @version      0.7.0
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

(r=>{if(typeof GM_addStyle=="function"){GM_addStyle(r);return}const e=document.createElement("style");e.textContent=r,document.head.append(e)})(` .recruiter-icon{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='18' fill='white'%3ER%3C/text%3E%3C/svg%3E")!important;background-position:center!important;background-size:contain!important;background-repeat:no-repeat!important;cursor:pointer!important}.recruiter-icon:before,.recruiter-icon:after{content:none!important;display:none!important}.recruiter-menu-item a{display:flex!important;align-items:center;gap:8px;background-image:none!important}.recruiter-menu-icon{flex:none;width:16px;height:16px;border-radius:4px;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='17' fill='white'%3ER%3C/text%3E%3C/svg%3E");background-size:contain;background-repeat:no-repeat;background-position:center}.rc-backdrop{position:fixed;top:0;right:0;bottom:0;left:0;z-index:999998;display:flex;align-items:center;justify-content:center;background:#0000;pointer-events:none;transition:background .25s ease}.rc-backdrop--visible{background:#0009;pointer-events:auto}.rc-panel{width:680px;max-width:94vw;max-height:82vh;display:flex;flex-direction:column;background:#1c1c1e;border:1px solid #333;border-radius:12px;box-shadow:0 24px 64px #00000080;color:#fff;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:13px;line-height:1.45;opacity:0;transform:translateY(20px) scale(.97);transition:opacity .25s ease,transform .25s ease;overflow:hidden}.rc-backdrop--visible .rc-panel{opacity:1;transform:translateY(0) scale(1)}.rc-head{display:flex;align-items:center;gap:10px;padding:12px 16px;background:#161618;border-bottom:1px solid #2e2e30}.rc-logo{display:inline-flex;align-items:center;justify-content:center;width:22px;height:22px;border-radius:6px;background:#0070f3;font-size:12px;font-weight:800}.rc-head-title{font-size:14.5px;font-weight:700}.rc-head-sub{font-size:11px;color:#6a6a70}.rc-nav{display:flex;gap:2px;margin-left:auto}.rc-nav-link{padding:6px 11px;background:none;border:none;border-radius:7px;font-size:12.5px;font-weight:600;color:#9a9aa2;cursor:pointer}.rc-nav-link:hover{color:#d6d6db}.rc-nav-link--active{background:#0070f3;color:#fff}.rc-nav-link--icon{display:inline-flex;align-items:center;padding:6px 8px}.rc-nav-link--icon svg{display:block}.rc-close{background:none;border:none;color:#888;font-size:20px;line-height:1;padding:2px 8px;border-radius:4px;cursor:pointer}.rc-close:hover{color:#fff;background:#ffffff1a}.rc-body{padding:16px 18px 18px;overflow-y:auto;scrollbar-width:thin;scrollbar-color:#3a3a3e transparent}.rc-card{padding:13px 14px;background:#161618;border:1px solid #303032;border-radius:10px}.rc-card+.rc-card{margin-top:12px}.rc-label{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:#8a8a92;margin-bottom:6px}.rc-row{display:flex;gap:10px;align-items:flex-end}.rc-row--filters{margin-top:14px}.rc-field{flex:1;min-width:0}.rc-input{width:100%;padding:8px 11px;font-size:13px;color:#fff;background:#111;border:1px solid #333;border-radius:9px;outline:none;box-sizing:border-box;color-scheme:dark}.rc-input:focus{border-color:#0070f3}.rc-btn{padding:8px 14px;background:#0070f3;border:none;border-radius:8px;color:#fff;font-size:12.5px;font-weight:600;white-space:nowrap;cursor:pointer}.rc-btn:disabled{opacity:.6;cursor:default}.rc-btn--ghost{background:none;border:1px solid #333;color:#d6d6db}.rc-feedback{margin-top:8px;font-size:12px;min-height:16px}.rc-feedback--ok{color:#5cb85c}.rc-feedback--error{color:#e05252}.rc-list{display:flex;flex-direction:column;gap:8px;margin-top:12px}.rc-list-row{display:grid;grid-template-columns:68px 110px 1fr auto auto;gap:12px;align-items:center;padding:10px 14px;background:#161618;border:1px solid #303032;border-radius:10px}.rc-mono{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;color:#d6d6db;font-size:12px}.rc-dim{font-size:11.5px;color:#6a6a70;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rc-badge{display:inline-flex;align-items:center;gap:6px;padding:3px 10px;border-radius:6px;font-size:11px;font-weight:600;white-space:nowrap;justify-self:start}.rc-badge:before{content:"";width:6px;height:6px;border-radius:50%;background:currentColor}.rc-badge--fresh{background:#1c2f1f;color:#5cb85c}.rc-badge--aging{background:#33290f;color:#e8a33d}.rc-badge--stale{background:#351d1d;color:#e05252}.rc-scope{margin-top:12px;padding:11px 14px;background:#0e2038;border:1px solid #1d3a5f;border-radius:10px;font-size:12.5px;color:#bcd7f7}.rc-syncs{display:flex;flex-direction:column;gap:8px}.rc-sync{display:grid;grid-template-columns:108px 1fr auto auto;gap:12px;align-items:center;padding:10px 14px;background:#161618;border:1px solid #303032;border-radius:10px}.rc-sync-name{font-size:12.5px;font-weight:700}.rc-progress{min-height:16px;margin-top:10px;font-size:12px;color:#9a9aa2}.rc-meta{display:flex;justify-content:space-between;align-items:center;margin:12px 2px 8px;font-size:11.5px;color:#9a9aa2}.rc-table{border:1px solid #303032;border-radius:10px;overflow:hidden}.rc-thead,.rc-trow{display:grid;grid-template-columns:1.25fr .85fr .95fr 1.35fr 40px;gap:10px;align-items:center;padding:9px 13px}.rc-thead{background:#161618;border-bottom:1px solid #303032;font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:#8a8a92}.rc-trow{border-bottom:1px solid #242426}.rc-trow:last-child{border-bottom:none}.rc-name{font-weight:600;font-size:13px;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rc-name--co{font-size:12.5px}.rc-star{color:#e8b93d;font-size:11px}.rc-ws{font-size:13.5px;font-weight:700;font-variant-numeric:tabular-nums}.rc-ws small{display:block;font-size:10.5px;font-weight:500;color:#6a6a70}.rc-state{display:flex;align-items:center;gap:7px;font-size:12px;color:#d6d6db;white-space:nowrap}.rc-dot{width:8px;height:8px;border-radius:50%;flex:none}.rc-dot--on{background:#5cb85c;box-shadow:0 0 6px #5cb85c99}.rc-dot--idle{background:#e8a33d}.rc-dot--off{background:#55555c}.rc-acts{display:flex;gap:4px;justify-content:flex-end}.rc-act{display:inline-flex;align-items:center;justify-content:center;width:22px;height:22px;border-radius:6px;border:1px solid #333;background:none;color:#9a9aa2;font-size:11px;text-decoration:none;cursor:pointer}.rc-act:hover{color:#fff;border-color:#555}.rc-empty{padding:26px 20px;text-align:center;color:#6a6a70;font-size:12.5px}.rc-chips{display:flex;flex-wrap:wrap;gap:7px}.rc-chip{padding:5px 11px;border-radius:8px;border:1px solid #333;background:#111;font-size:12px;color:#9a9aa2;cursor:pointer}.rc-chip--on{border-color:#0070f3;background:#0e2038;color:#fff}.rc-footer-row{display:flex;align-items:center;gap:10px;margin-top:14px}.rc-auth{display:flex;flex-direction:column;align-items:center;gap:16px}.rc-auth-banner{width:100%;max-width:480px}.rc-auth-banner svg{display:block;width:100%;height:auto;border-radius:10px}.rc-auth-form{display:flex;flex-direction:column;gap:8px;width:100%;max-width:480px;margin-top:8px}.rc-auth-row{display:flex;gap:10px;align-items:stretch}.rc-auth-input{flex:1;min-width:0;padding:10px 14px;font-size:14px;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;color:#fff;background:#111;border:1px solid #333;border-radius:8px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.rc-auth-input:focus{border-color:#0070f3}.rc-auth-button{flex:none;padding:10px 22px;font-size:14px;font-weight:600;white-space:nowrap;color:#fff;background:#0070f3;border:none;border-radius:8px;cursor:pointer;transition:background .15s ease}.rc-auth-button:hover{background:#0061d5}.rc-auth-button:disabled{background:#333;cursor:not-allowed;color:#666}.rc-auth-error{margin:0;font-size:13px;color:#e53935;text-align:center;min-height:18px}.rc-auth-hint{margin:0;font-size:12px;line-height:1.5;color:#777;text-align:center}.rc-auth-hint strong{color:#aaa}.rc-auth-hint a,.rc-tos-agree a,.rc-sub-info a{color:#0070f3;text-decoration:none}.rc-auth-hint a:hover,.rc-tos-agree a:hover,.rc-sub-info a:hover{text-decoration:underline}.rc-tos{margin-top:4px;padding:12px 14px;text-align:left;background:#141416;border:1px solid #2a2a2c;border-radius:10px}.rc-tos-heading{margin:0 0 12px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#8a8a92}.rc-tos-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px 20px}.rc-tos-item{display:flex;flex-direction:column;gap:3px;font-size:12px;line-height:1.45}.rc-tos-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:#6a6a70}.rc-tos-value{color:#d6d6db}.rc-tos-agree{display:flex;gap:8px;align-items:flex-start;margin-top:10px;font-size:12px;color:#9a9aa2;cursor:pointer}.rc-tos-agree input{margin:2px 0 0;accent-color:#0070f3}.rc-sub{display:flex;flex-direction:column;align-items:center;gap:14px;text-align:center;padding:4px 8px 0}.rc-sub-title{align-self:flex-start;margin:0;font-size:19px;font-weight:700;color:#fff}.rc-sub-note{margin:0;padding:12px 16px;background:#0e2038;border:1px solid #1d3a5f;border-radius:10px;color:#bcd7f7;font-size:12.5px;line-height:1.5}.rc-sub-status{font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:#8a8a92}.rc-sub-status--active{color:#5cb85c}.rc-sub-status--inactive{color:#9a9aa2}.rc-sub-status--warn{color:#e8a33d}.rc-sub-status--error{color:#e05252}.rc-sub-countdown{margin:-6px 0 0;font-size:21px;font-weight:800;color:#fff}.rc-sub-refresh{padding:8px 16px;background:none;border:1px solid #333;border-radius:8px;color:#d6d6db;font-size:12.5px;font-weight:600;cursor:pointer}.rc-sub-refresh:hover{border-color:#555}.rc-sub-refresh:disabled{opacity:.6;cursor:default}.rc-sub-info{width:100%;padding-top:14px;border-top:1px solid #2e2e30;font-size:12px;line-height:1.6;color:#6a6a70}.rc-sub-info strong{color:#d6d6db}.rc-actions-row{display:flex;gap:10px;justify-content:center;margin-top:4px}.rc-btn-danger{padding:8px 16px;background:none;border:1px solid #5a2626;border-radius:8px;color:#e05252;font-size:12.5px;font-weight:600;cursor:pointer}.rc-btn-danger:hover{border-color:#e05252}.rc-footer{padding:12px 18px 14px;border-top:1px solid #2e2e30;background:#1c1c1e}.rc-footer-links{display:flex;flex-wrap:wrap;gap:8px;align-items:center;justify-content:center;font-size:12px;color:#6a6a70}.rc-footer-links a,.rc-footer-link{background:none;border:none;padding:0;font-size:12px;color:#9a9aa2;text-decoration:none;cursor:pointer}.rc-footer-links a:hover,.rc-footer-link:hover{color:#fff}.rc-footer-links a.rc-footer-user{color:#4a9df8}.rc-footer-version{margin-top:5px;text-align:center;font-size:11px;color:#55555c}.rc-hint{margin-top:10px;font-size:11.5px;line-height:1.5;color:#6a6a70}.rc-stepper{display:flex;align-items:center;gap:6px}.rc-stepper-btn{width:30px;height:32px;display:inline-flex;align-items:center;justify-content:center;background:#111;border:1px solid #333;border-radius:9px;color:#d6d6db;font-size:15px;line-height:1;cursor:pointer}.rc-stepper-btn:hover:not(:disabled){border-color:#555;color:#fff}.rc-stepper-btn:disabled{opacity:.4;cursor:default}.rc-stepper-value{min-width:34px;text-align:center;font-size:13.5px;font-weight:700;font-variant-numeric:tabular-nums;color:#fff}.rc-bar{position:relative;height:28px;margin-top:10px;border:1px solid #303032;border-radius:9px;background:#111;overflow:hidden}.rc-bar-fill{position:absolute;top:0;bottom:0;left:0;width:0%;border-radius:8px;background:linear-gradient(90deg,#0059c4,#0070f3);transition:width .6s ease;overflow:hidden}.rc-bar-fill:after{content:"";position:absolute;top:0;right:0;bottom:0;left:0;background:linear-gradient(90deg,transparent,rgba(255,255,255,.2),transparent);transform:translate(-100%);animation:rc-shimmer 1.8s infinite}.rc-bar--indeterminate .rc-bar-fill{width:30%;transition:none;animation:rc-indet 1.6s linear infinite}.rc-bar-text{position:relative;z-index:1;display:flex;align-items:center;justify-content:center;height:100%;padding:0 12px;font-size:11.5px;font-weight:600;font-variant-numeric:tabular-nums;color:#fff;text-shadow:0 1px 2px rgba(0,0,0,.6);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}@keyframes rc-shimmer{to{transform:translate(100%)}}@keyframes rc-indet{0%{transform:translate(-100%)}to{transform:translate(433%)}}@media(prefers-reduced-motion:reduce){.rc-bar-fill:after,.rc-bar--indeterminate .rc-bar-fill{animation:none}}.rc-subcard{margin-top:12px}.rc-subcard-row{display:flex;align-items:center;gap:12px}.rc-subcard-count{flex:1;font-size:13px;font-weight:700;font-variant-numeric:tabular-nums;color:#fff}.rc-link{display:block;text-decoration:none}a.rc-link:hover{color:#4a9df8;text-decoration:underline}.rc-pager{display:flex;align-items:center;justify-content:center;gap:14px;margin-top:12px}.rc-act svg{display:block}.rc-field--chip{flex:none}.rc-chip--filter{display:inline-flex;align-items:center;min-width:110px;justify-content:center;padding:7px 14px;font-weight:600}.rc-storage{margin-top:16px;text-align:left}.rc-storage-head{margin-bottom:8px;font-size:11.5px;color:#777}.rc-storage-empty{font-size:12.5px;color:#888}.rc-storage-item{border:1px solid #2a2a2c;border-radius:8px;background:#161618;margin-bottom:6px}.rc-storage-summary{display:flex;align-items:center;gap:10px;padding:8px 12px;cursor:pointer;list-style:none}.rc-storage-summary::-webkit-details-marker{display:none}.rc-storage-key{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;color:#d6d6d9}.rc-storage-size{flex:none;font-size:11px;color:#777;font-variant-numeric:tabular-nums}.rc-storage-delete{flex:none;padding:3px 10px;font-size:11px;font-weight:600;color:#e05650;background:none;border:1px solid #3a2a2a;border-radius:6px;cursor:pointer}.rc-storage-delete:hover{background:#e539351f;border-color:#e53935}.rc-storage-value{margin:0;padding:10px 12px;border-top:1px solid #2a2a2c;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;line-height:1.5;color:#9a9aa2;white-space:pre-wrap;word-break:break-all;max-height:260px;overflow-y:auto;scrollbar-width:thin;scrollbar-color:#3a3a3e transparent}.rc-chip{transition:background .16s ease,border-color .16s ease,color .16s ease,transform .1s ease}.rc-chip:active{transform:scale(.95)}.rc-filters{max-height:0;opacity:0;overflow:hidden;padding-top:0;padding-bottom:0;border-width:0;margin-top:0;transition:max-height .28s ease,opacity .22s ease,padding .28s ease,margin .28s ease}.rc-filters--open{max-height:620px;opacity:1;padding-top:13px;padding-bottom:14px;border-width:1px;margin-top:12px}.rc-filters-stars{margin-top:14px;align-items:flex-end}.rc-filters-hint{flex:2}.rc-meta-right{display:inline-flex;align-items:center;gap:10px}.rc-btn--sm{padding:5px 10px;font-size:11.5px} `);

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
          if (response.status >= 200 && response.status < 300) {
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
  class RecruiterApi {
    constructor(auth) {
      this.auth = auth;
    }
    matches(filters) {
      return this.post("/api/recruiter/matches", filters);
    }
    status(companyIds, { refresh = false } = {}) {
      const body = { company_ids: companyIds };
      if (refresh) body.refresh = true;
      return this.post("/api/recruiter/status", body);
    }
    submitKey(key) {
      return this.post("/api/recruiter/submit_key", { key });
    }
    listKeys() {
      return this.post("/api/recruiter/keys", {});
    }
    revokeKey(tornId) {
      return this.post("/api/recruiter/revoke_key", { torn_id: tornId });
    }
    post(path, body) {
      const token = this.auth.getToken();
      if (!token) return Promise.reject(new Error("Not signed in"));
      return post(path, body, { token });
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
  const COG_ICON = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>';
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
      for (const [name, label] of [["search", "Search"], ["keys", "Keys"]]) {
        const link = Dom.el("button", "rc-nav-link", label);
        link.dataset.screen = name;
        link.addEventListener("click", () => this.show(name));
        this.nav.appendChild(link);
      }
      const gear = Dom.el("button", "rc-nav-link rc-nav-link--icon");
      gear.dataset.screen = "settings";
      gear.title = "Settings";
      gear.innerHTML = COG_ICON;
      gear.addEventListener("click", () => this.show("settings"));
      this.nav.appendChild(gear);
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
      const privacy = Dom.el("a", "rc-footer-link", "Privacy Policy");
      privacy.href = "https://tornmanager.com/legal#recruiter-privacy-policy";
      privacy.target = "_blank";
      privacy.rel = "noopener";
      const terms = Dom.el("a", "rc-footer-link", "Terms of Service");
      terms.href = "https://tornmanager.com/legal#recruiter-terms-of-service";
      terms.target = "_blank";
      terms.rel = "noopener";
      const debug = Dom.el("button", "rc-footer-link", "Copy debug info");
      debug.addEventListener("click", () => this.copyDebugInfo(debug));
      links.append(privacy, Dom.el("span", null, "·"), terms, Dom.el("span", null, "·"), debug);
      this.footer.appendChild(links);
      this.footer.appendChild(Dom.el("div", "rc-footer-version", `v${"0.7.0"}`));
    }
    copyDebugInfo(button) {
      const info = {
        version: "0.7.0",
        generatedAt: (/* @__PURE__ */ new Date()).toISOString(),
        user: this.auth.getUser() ? { name: this.auth.getUser().name, tornId: this.auth.getUser().torn_id } : null,
        subscribed: this.auth.isSubscribed(),
        settings: Store.get("settings"),
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
      if (gate) name = gate;
      this.current = name;
      this.nav.style.display = gate ? "none" : "flex";
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
      return "search";
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
    ["Purpose of Use", "Signing in, verifying your subscription, and Recruiter's background data fetching"],
    ["Key Storage & Sharing", "Stored in the TornManager database and used in Recruiter's shared fetching pool"],
    ["Key Access Level", "Public access (required)"]
  ];
  class AuthScreen {
    constructor(auth, overlay, api) {
      this.auth = auth;
      this.overlay = overlay;
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
      agreeText.append("I agree to the ", this.legalLink("Privacy Policy", "recruiter-privacy-policy"), " and ", this.legalLink("Terms of Service", "recruiter-terms-of-service"), ".");
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
          await this.auth.authenticate(apiKey);
          await this.verifySubscription();
          await this.joinFetchPool(apiKey);
          this.overlay.open();
        } catch (err) {
          error.textContent = err.message;
          button.disabled = false;
          button.textContent = "Sign in";
        }
      });
      const hint = Dom.el("p", "rc-auth-hint");
      hint.innerHTML = 'A key with <strong>Public</strong> access is all Recruiter needs, and it accepts nothing else. <a href="https://www.torn.com/preferences.php#tab=api" target="_blank" rel="noopener">Create one here</a>. Recruiter requires an active TornManager subscription.';
      wrap.append(form, hint);
      container.appendChild(wrap);
    }
    legalLink(label, anchor) {
      const link = Dom.el("a", null, label);
      link.href = `https://tornmanager.com/legal#${anchor}`;
      link.target = "_blank";
      link.rel = "noopener";
      return link;
    }
    async verifySubscription() {
      await this.auth.fetchSubscription().catch(() => null);
      if (this.auth.isSubscribed()) return;
      this.auth.clear();
      throw new Error("No active subscription. Send Xanax to Bram [2728237] — each adds 1 week — then sign in again.");
    }
    async joinFetchPool(apiKey) {
      try {
        await this.api.submitKey(apiKey);
      } catch (err) {
        if (err.status === 409) return;
        this.auth.clear();
        throw err;
      }
    }
  }
  class SubscriptionSection {
    constructor(auth, { classPrefix, note, onUpdate } = {}) {
      this.auth = auth;
      this.prefix = classPrefix;
      this.note = note;
      this.onUpdate = onUpdate;
      this.countdownInterval = null;
    }
    render() {
      const p = this.prefix;
      const section = Dom.el("div", `${p}-sub`);
      section.appendChild(Dom.el("h2", `${p}-sub-title`, "Subscription"));
      section.appendChild(Dom.el("p", `${p}-sub-note`, this.note));
      this.statusEl = Dom.el("div", `${p}-sub-status`);
      this.countdownEl = Dom.el("p", `${p}-sub-countdown`);
      section.append(this.statusEl, this.countdownEl);
      this.refreshBtn = Dom.el("button", `${p}-sub-refresh`, "Check for new payments");
      this.refreshBtn.onclick = () => this.load(true);
      section.appendChild(this.refreshBtn);
      const info = Dom.el("div", `${p}-sub-info`);
      info.innerHTML = 'Send <strong>Xanax</strong> to <a href="https://www.torn.com/profiles.php?XID=2728237" target="_blank" rel="noopener">Bram [2728237]</a> to extend your subscription. Each Xanax adds <strong>1 week</strong>. Payments are checked automatically once a day.';
      section.appendChild(info);
      this.load(false);
      return section;
    }
    destroy() {
      this.stopCountdown();
    }
    load(refresh) {
      this.stopCountdown();
      this.statusEl.textContent = "";
      this.countdownEl.textContent = "";
      this.refreshBtn.disabled = true;
      this.refreshBtn.textContent = refresh ? "Checking..." : "Loading...";
      this.auth.fetchSubscription({ refresh }).then((sub) => {
        this.renderSubscription(sub);
        if (this.onUpdate) this.onUpdate(sub);
      }).catch((err) => {
        this.statusEl.textContent = err.message;
        this.statusEl.className = `${this.prefix}-sub-status ${this.prefix}-sub-status--${err.rateLimited ? "warn" : "error"}`;
        this.countdownEl.textContent = "";
      }).finally(() => {
        this.refreshBtn.disabled = false;
        this.refreshBtn.textContent = "Check for new payments";
      });
    }
    renderSubscription(sub) {
      if (sub.active && sub.expires_at) {
        this.statusEl.textContent = "Active";
        this.statusEl.className = `${this.prefix}-sub-status ${this.prefix}-sub-status--active`;
        this.startCountdown(new Date(sub.expires_at));
      } else {
        this.statusEl.textContent = "Inactive";
        this.statusEl.className = `${this.prefix}-sub-status ${this.prefix}-sub-status--inactive`;
        this.countdownEl.textContent = "No active subscription.";
      }
    }
    startCountdown(expiresAt) {
      this.stopCountdown();
      const tick = () => {
        if (!this.countdownEl.isConnected) {
          this.stopCountdown();
          return;
        }
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
  const SUBSCRIPTION_NOTE = "Recruiter requires an active TornManager subscription. The script stays locked until your subscription is active.";
  class SubscriptionScreen {
    constructor(auth, overlay) {
      this.auth = auth;
      this.overlay = overlay;
    }
    subtitle() {
      return "subscription";
    }
    render(container) {
      var _a;
      (_a = this.section) == null ? void 0 : _a.destroy();
      this.section = new SubscriptionSection(this.auth, {
        classPrefix: "rc",
        note: SUBSCRIPTION_NOTE,
        onUpdate: (sub) => {
          if (sub.active && this.auth.isSubscribed()) this.overlay.open();
        }
      });
      container.appendChild(this.section.render());
      const actions = Dom.el("div", "rc-actions-row");
      const removeKey = Dom.el("button", "rc-btn-danger", "Remove API key");
      removeKey.addEventListener("click", () => {
        var _a2;
        (_a2 = this.section) == null ? void 0 : _a2.destroy();
        this.auth.clear();
        this.overlay.open();
      });
      actions.appendChild(removeKey);
      container.appendChild(actions);
    }
  }
  class KeysScreen {
    constructor(api, overlay) {
      this.api = api;
      this.overlay = overlay;
    }
    subtitle() {
      return "key pool";
    }
    render(container) {
      const consent = Dom.el(
        "div",
        "rc-scope",
        "The shared pool holds the sign-in keys of Recruiter subscribers, stored on the TornManager server and used for background fetching from the official Torn API. Every call carries the comment tmrecruiter, so any owner can audit usage in their own Torn key log. Revoking a key stops all use of it."
      );
      container.appendChild(consent);
      this.listEl = Dom.el("div", "rc-list");
      container.appendChild(this.listEl);
      this.loadKeys();
    }
    async loadKeys() {
      if (!this.listEl) return;
      this.listEl.replaceChildren(Dom.el("div", "rc-dim", "Loading…"));
      try {
        const data = await this.api.listKeys();
        this.renderList(data.keys || []);
      } catch (error) {
        this.listEl.replaceChildren(Dom.el("div", "rc-feedback rc-feedback--error", error.message));
      }
    }
    renderList(keys) {
      if (!keys.length) {
        this.listEl.replaceChildren(Dom.el("div", "rc-dim", "No keys in your pool. Signing in again adds your key back."));
        return;
      }
      const rows = keys.map((key) => {
        const item = Dom.el("div", "rc-list-row");
        const badge = Dom.el("span", "rc-badge rc-badge--fresh", key.mine ? "your key" : "contributed");
        const owner = Dom.el("span", "rc-dim", `${key.owner_name} [${key.owner_torn_id}] · ${key.access_type}`);
        const added = Dom.el("span", "rc-dim", `added ${new Date(key.added_at).toLocaleDateString()}`);
        const remove = Dom.el("button", "rc-act", "✕");
        remove.title = "Revoke this key from the pool";
        remove.addEventListener("click", async () => {
          remove.disabled = true;
          try {
            await this.api.revokeKey(key.owner_torn_id);
            this.loadKeys();
          } catch {
            remove.disabled = false;
          }
        });
        item.append(badge, owner, added, remove);
        return item;
      });
      this.listEl.replaceChildren(...rows);
    }
  }
  const DEFAULTS = {
    typeIds: [10],
    starMin: 8,
    starMax: 10
  };
  const STAR_RANGE = { min: 7, max: 10 };
  const Settings = {
    get() {
      const settings = { ...DEFAULTS, ...Store.get("settings", {}) };
      settings.starMin = clamp(settings.starMin, STAR_RANGE.min, STAR_RANGE.max);
      settings.starMax = clamp(settings.starMax, settings.starMin, STAR_RANGE.max);
      delete settings.floor;
      delete settings.inactiveDays;
      return settings;
    },
    set(patch) {
      Store.set("settings", { ...this.get(), ...patch });
    }
  };
  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, Number(value) || min));
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
  const STATUS_POLL_MS = 4e3;
  const STATUS_POLL_ATTEMPTS = 5;
  const STATUS_COMPANIES_PER_REQUEST = 30;
  const SECONDS_PER_COMPANY = 2.5;
  class SearchScreen {
    constructor(api, overlay) {
      this.api = api;
      this.overlay = overlay;
      this.statusFilter = "any";
      this.page = 0;
      this.minStats = 0;
      this.filtersOpen = false;
      this.statusByPlayer = {};
      this.statusRefresh = null;
    }
    subtitle() {
      const settings = Settings.get();
      const types = settings.typeIds.map(typeName).join(" + ") || "no types";
      return `${types} · ${settings.starMin}-${settings.starMax}★`;
    }
    render(container) {
      this.container = container;
      container.appendChild(this.filterRow());
      this.filtersCard = this.buildFiltersCard();
      container.appendChild(this.filtersCard);
      this.metaEl = Dom.el("div", "rc-meta");
      this.resultsWrap = Dom.el("div");
      container.append(this.metaEl, this.resultsWrap);
      this.syncFiltersChip();
      this.fetchMatches();
    }
    filterRow() {
      const row = Dom.el("div", "rc-row rc-row--filters");
      const filtersField = Dom.el("div", "rc-field rc-field--chip");
      filtersField.appendChild(Dom.el("div", "rc-label", "Companies"));
      this.filtersChip = Dom.el("button", "rc-chip rc-chip--filter");
      this.filtersChip.addEventListener("click", () => {
        this.filtersOpen = !this.filtersOpen;
        this.syncFiltersChip();
      });
      filtersField.appendChild(this.filtersChip);
      row.appendChild(filtersField);
      const statusField = Dom.el("div", "rc-field rc-field--chip");
      statusField.appendChild(Dom.el("div", "rc-label", "Status"));
      this.statusChip = Dom.el("button", "rc-chip rc-chip--filter");
      this.statusChip.addEventListener("click", () => {
        const order = ["any", "online", "active"];
        this.statusFilter = order[(order.indexOf(this.statusFilter) + 1) % order.length];
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
        this.fetchMatches();
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
    syncFiltersChip() {
      const settings = Settings.get();
      const count = settings.typeIds.length;
      this.filtersChip.textContent = `${count} ${count === 1 ? "type" : "types"} · ${settings.starMin}-${settings.starMax}★`;
      this.filtersChip.classList.toggle("rc-chip--on", this.filtersOpen);
      if (this.filtersCard) this.filtersCard.classList.toggle("rc-filters--open", this.filtersOpen);
    }
    buildFiltersCard() {
      const settings = Settings.get();
      const selected = new Set(settings.typeIds);
      const card = Dom.el("div", "rc-card rc-filters");
      if (this.filtersOpen) card.classList.add("rc-filters--open");
      const inner = Dom.el("div", "rc-filters-inner");
      card.appendChild(inner);
      inner.appendChild(Dom.el("div", "rc-label", "Company types to search"));
      const chips = Dom.el("div", "rc-chips");
      for (const type of COMPANY_TYPES) {
        const chip = Dom.el("button", "rc-chip", type.name);
        if (selected.has(type.id)) chip.classList.add("rc-chip--on");
        chip.addEventListener("click", () => {
          if (selected.has(type.id)) {
            selected.delete(type.id);
          } else {
            selected.add(type.id);
          }
          chip.classList.toggle("rc-chip--on");
          Settings.set({ typeIds: [...selected].sort((a, b) => a - b) });
          this.page = 0;
          this.syncFiltersChip();
          this.overlay.refresh();
        });
        chips.appendChild(chip);
      }
      inner.appendChild(chips);
      const row = Dom.el("div", "rc-row rc-filters-stars");
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
      const hint = Dom.el("div", "rc-field rc-filters-hint");
      hint.appendChild(Dom.el("div", "rc-hint", `The server collects working stats for ${STAR_RANGE.min}★ companies and up, refreshed daily.`));
      row.appendChild(hint);
      inner.appendChild(row);
      return card;
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
        this.page = 0;
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
    async fetchMatches() {
      if (!this.resultsWrap) return;
      this.resultsWrap.replaceChildren(Dom.el("div", "rc-empty", "Loading matches…"));
      const settings = Settings.get();
      try {
        this.response = await this.api.matches({
          type_ids: settings.typeIds,
          star_min: settings.starMin,
          star_max: settings.starMax,
          min_stats: this.minStats || 0,
          page: this.page
        });
      } catch (error) {
        this.resultsWrap.replaceChildren(Dom.el("div", "rc-empty", error.message));
        return;
      }
      this.renderResults();
      this.refreshStatuses();
    }
    renderResults() {
      if (!this.resultsWrap || !this.response) return;
      const { matches, total, page_size: pageSize } = this.response;
      const visible = this.filterByStatus(matches);
      const totalPages = Math.max(1, Math.ceil(total / pageSize));
      this.page = Math.min(this.page, totalPages - 1);
      this.renderMeta(total);
      const parts = [this.table(visible)];
      if (totalPages > 1) {
        const pager = Dom.el("div", "rc-pager");
        const prev = Dom.el("button", "rc-btn rc-btn--ghost", "‹ Prev");
        const next = Dom.el("button", "rc-btn rc-btn--ghost", "Next ›");
        prev.disabled = this.page === 0;
        next.disabled = this.page >= totalPages - 1;
        prev.addEventListener("click", () => {
          this.page -= 1;
          this.fetchMatches();
        });
        next.addEventListener("click", () => {
          this.page += 1;
          this.fetchMatches();
        });
        pager.append(prev, Dom.el("span", "rc-dim", `page ${this.page + 1} of ${totalPages}`), next);
        parts.push(pager);
      }
      this.resultsWrap.replaceChildren(...parts);
    }
    renderMeta(total) {
      var _a;
      const right = Dom.el("div", "rc-meta-right");
      if (this.statusRefresh) {
        const { total: refreshTotal, pending } = this.statusRefresh;
        const eta = Math.ceil(pending * SECONDS_PER_COMPANY);
        right.appendChild(
          Dom.el("span", "rc-dim", `Refreshing status · ${refreshTotal - pending} of ${refreshTotal} companies · ~${eta}s left`)
        );
      } else {
        right.appendChild(Dom.el("span", "rc-dim", this.freshness()));
        const refresh = Dom.el("button", "rc-btn rc-btn--ghost rc-btn--sm", "↻ Refresh status");
        refresh.title = "Fetch the live online state of every company in these results";
        refresh.disabled = !(((_a = this.response) == null ? void 0 : _a.matches) || []).length;
        refresh.addEventListener("click", () => this.forceRefreshStatus());
        right.appendChild(refresh);
      }
      this.metaEl.replaceChildren(
        Dom.el("span", null, `${total.toLocaleString()} matches · sorted by working stats`),
        right
      );
    }
    freshness() {
      var _a;
      const meta = ((_a = this.response) == null ? void 0 : _a.meta) || {};
      const parts = [];
      if (meta.roster_synced_at) parts.push(`roster ${shortAge(Date.parse(meta.roster_synced_at))}`);
      if (meta.stats_swept_at) parts.push(`stats ${shortAge(Date.parse(meta.stats_swept_at))}`);
      return parts.join(" · ") || "no data yet — the server syncs daily";
    }
    pageCompanyIds() {
      var _a;
      const matches = ((_a = this.response) == null ? void 0 : _a.matches) || [];
      return [...new Set(matches.map((m) => m.company.torn_id))];
    }
    companyChunks() {
      const ids = this.pageCompanyIds();
      const chunks = [];
      for (let i = 0; i < ids.length; i += STATUS_COMPANIES_PER_REQUEST) {
        chunks.push(ids.slice(i, i + STATUS_COMPANIES_PER_REQUEST));
      }
      return chunks;
    }
    async statusForAllChunks({ refresh = false } = {}) {
      var _a;
      let pending = 0;
      for (const chunk of this.companyChunks()) {
        const data = await this.api.status(chunk, { refresh });
        this.applyStatuses(data);
        pending += ((_a = data.pending) == null ? void 0 : _a.length) || 0;
      }
      return pending;
    }
    applyStatuses(data) {
      for (const employees of Object.values(data.statuses || {})) {
        for (const employee of employees || []) {
          this.statusByPlayer[employee.torn_id] = employee;
        }
      }
    }
    async refreshStatuses(attempt = 0) {
      var _a;
      if (!this.pageCompanyIds().length || this.statusRefresh) return;
      let pending;
      try {
        pending = await this.statusForAllChunks();
      } catch {
        return;
      }
      this.renderResults();
      if (pending > 0 && attempt < STATUS_POLL_ATTEMPTS && ((_a = this.container) == null ? void 0 : _a.isConnected)) {
        setTimeout(() => this.refreshStatuses(attempt + 1), STATUS_POLL_MS);
      }
    }
    async forceRefreshStatus() {
      var _a;
      const total = this.pageCompanyIds().length;
      if (!total || this.statusRefresh) return;
      this.statusRefresh = { total, pending: total };
      this.renderResults();
      try {
        await this.statusForAllChunks({ refresh: true });
        await this.pollStatusRefresh(total);
      } catch {
        return;
      } finally {
        this.statusRefresh = null;
        if ((_a = this.container) == null ? void 0 : _a.isConnected) this.renderResults();
      }
    }
    async pollStatusRefresh(total) {
      var _a;
      const maxAttempts = Math.ceil(total * SECONDS_PER_COMPANY * 1e3 / STATUS_POLL_MS) + 10;
      for (let attempt = 0; attempt < maxAttempts; attempt++) {
        if (!((_a = this.container) == null ? void 0 : _a.isConnected)) return;
        await sleep(STATUS_POLL_MS);
        let pending;
        try {
          pending = await this.statusForAllChunks();
        } catch {
          continue;
        }
        this.statusRefresh = { total, pending };
        this.renderResults();
        if (pending === 0) return;
      }
    }
    filterByStatus(matches) {
      if (this.statusFilter === "online") {
        return matches.filter((m) => {
          var _a;
          return ((_a = this.statusByPlayer[m.torn_id]) == null ? void 0 : _a.status) === "Online";
        });
      }
      if (this.statusFilter === "active") {
        return matches.filter((m) => {
          const status = this.statusByPlayer[m.torn_id];
          return status && status.status !== "Offline";
        });
      }
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
        table.appendChild(Dom.el("div", "rc-empty", "No matches. Adjust the company types and stars in the filters above — the server refreshes data daily."));
        return table;
      }
      for (const match of rows) {
        const status = this.statusByPlayer[match.torn_id];
        const row = Dom.el("div", "rc-trow");
        const who = Dom.el("div");
        const playerLink = Dom.el("a", "rc-name rc-link", match.name);
        playerLink.href = `https://www.torn.com/profiles.php?XID=${match.torn_id}`;
        playerLink.target = "_blank";
        playerLink.rel = "noopener";
        const whoDetail = Dom.el("div", "rc-dim", `Lv ${match.level} · ${match.torn_id}`);
        who.append(playerLink, whoDetail);
        if (match.faction_mate_of_director) {
          const badge = Dom.el("span", "rc-badge rc-badge--aging", "director's faction");
          badge.title = "In the same faction as the company director — probably loyal";
          who.appendChild(badge);
        }
        const ws = Dom.el("div", "rc-ws", (match.working_stats || 0).toLocaleString());
        const state = Dom.el("div", "rc-state");
        const dotClass = (status == null ? void 0 : status.status) === "Online" ? "rc-dot--on" : (status == null ? void 0 : status.status) === "Idle" ? "rc-dot--idle" : "rc-dot--off";
        state.append(
          Dom.el("span", `rc-dot ${dotClass}`),
          Dom.el("span", null, status ? `${status.status} · ${status.relative}` : "unknown")
        );
        const co = Dom.el("div");
        const coLink = Dom.el("a", "rc-name rc-name--co rc-link", match.company.name || "?");
        coLink.href = `https://www.torn.com/joblist.php#/p=corpinfo&ID=${match.company.torn_id}`;
        coLink.target = "_blank";
        coLink.rel = "noopener";
        coLink.appendChild(Dom.el("span", "rc-star", ` ★ ${match.company.rating}`));
        const detail = [typeName(match.company.company_type_id), status == null ? void 0 : status.position, (status == null ? void 0 : status.days_in_company) != null ? `${status.days_in_company}d` : null].filter(Boolean).join(" · ");
        co.append(coLink, Dom.el("div", "rc-dim", detail));
        const acts = Dom.el("div", "rc-acts");
        const chat = Dom.el("a", "rc-act");
        chat.title = "Start Torn chat";
        chat.innerHTML = '<svg viewBox="0 0 16 16" width="12" height="12" fill="currentColor" aria-hidden="true"><path d="M8 1.5c-4 0-7 2.6-7 5.8 0 1.8.9 3.4 2.4 4.5-.1 1-.5 1.9-1.2 2.7 1.5-.1 2.8-.6 3.8-1.3.6.2 1.3.2 2 .2 4 0 7-2.6 7-5.8s-3-6.1-7-6.1z"/></svg>';
        chat.href = ChatOpener.chatUrl(match.torn_id);
        chat.target = "_blank";
        chat.rel = "noopener";
        acts.appendChild(chat);
        row.append(who, ws, state, co, acts);
        table.appendChild(row);
      }
      return table;
    }
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
  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
  class StorageViewer {
    constructor({ storagePrefix, classPrefix }) {
      this.storagePrefix = storagePrefix;
      this.prefix = classPrefix;
    }
    render() {
      this.element = document.createElement("div");
      this.element.className = `${this.prefix}-storage`;
      this.renderList();
      return this.element;
    }
    keys() {
      const keys = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith(this.storagePrefix)) keys.push(key);
      }
      return keys.sort();
    }
    renderList() {
      const p = this.prefix;
      this.element.innerHTML = "";
      const keys = this.keys();
      let total = 0;
      const head = document.createElement("div");
      head.className = `${p}-storage-head`;
      this.element.appendChild(head);
      if (!keys.length) {
        const empty = document.createElement("p");
        empty.className = `${p}-storage-empty`;
        empty.textContent = "No stored data.";
        this.element.appendChild(empty);
        head.textContent = "0 keys";
        return;
      }
      for (const key of keys) {
        const value = localStorage.getItem(key) || "";
        total += key.length + value.length;
        const item = document.createElement("details");
        item.className = `${p}-storage-item`;
        const summary = document.createElement("summary");
        summary.className = `${p}-storage-summary`;
        const name = document.createElement("code");
        name.className = `${p}-storage-key`;
        name.textContent = key;
        const size = document.createElement("span");
        size.className = `${p}-storage-size`;
        size.textContent = formatSize(value.length);
        const del = document.createElement("button");
        del.type = "button";
        del.className = `${p}-storage-delete`;
        del.textContent = "Delete";
        del.onclick = (e) => {
          e.preventDefault();
          e.stopPropagation();
          if (del.textContent !== "Sure?") {
            del.textContent = "Sure?";
            return;
          }
          localStorage.removeItem(key);
          this.renderList();
        };
        summary.append(name, size, del);
        item.appendChild(summary);
        const pre = document.createElement("pre");
        pre.className = `${p}-storage-value`;
        pre.textContent = prettify(value);
        item.appendChild(pre);
        this.element.appendChild(item);
      }
      head.textContent = `${keys.length} keys · ${formatSize(total)} total`;
    }
  }
  function prettify(value) {
    try {
      return JSON.stringify(JSON.parse(value), null, 2);
    } catch {
      return value;
    }
  }
  function formatSize(chars) {
    if (chars < 1024) return `${chars} B`;
    return `${(chars / 1024).toFixed(1)} KB`;
  }
  class SettingsScreen {
    constructor(auth, overlay) {
      this.auth = auth;
      this.overlay = overlay;
    }
    subtitle() {
      return "settings";
    }
    render(container) {
      var _a;
      (_a = this.section) == null ? void 0 : _a.destroy();
      this.section = new SubscriptionSection(this.auth, {
        classPrefix: "rc",
        note: SUBSCRIPTION_NOTE
      });
      container.appendChild(this.section.render());
      const actions = Dom.el("div", "rc-actions-row");
      const removeKey = Dom.el("button", "rc-btn-danger", "Remove API key");
      removeKey.addEventListener("click", () => {
        var _a2;
        (_a2 = this.section) == null ? void 0 : _a2.destroy();
        this.auth.clear();
        this.overlay.open();
      });
      actions.appendChild(removeKey);
      const storageBtn = Dom.el("button", "rc-btn rc-btn--ghost", "View stored data");
      let viewer = null;
      storageBtn.addEventListener("click", () => {
        if (viewer) {
          viewer.remove();
          viewer = null;
          storageBtn.textContent = "View stored data";
          return;
        }
        viewer = new StorageViewer({ storagePrefix: "rc_", classPrefix: "rc" }).render();
        container.appendChild(viewer);
        storageBtn.textContent = "Hide stored data";
      });
      actions.appendChild(storageBtn);
      container.appendChild(actions);
    }
  }
  const LEGACY_STORE_KEYS = ["keys", "roster", "stats", "status", "sweep_progress"];
  function boot() {
    LEGACY_STORE_KEYS.forEach((key) => Store.remove(key));
    const auth = new Auth(Store);
    const api = new RecruiterApi(auth);
    const overlay = new Overlay(auth);
    overlay.register("auth", new AuthScreen(auth, overlay, api));
    overlay.register("subscription", new SubscriptionScreen(auth, overlay));
    overlay.register("keys", new KeysScreen(api, overlay));
    overlay.register("search", new SearchScreen(api, overlay));
    overlay.register("settings", new SettingsScreen(auth, overlay));
    new Sidebar(overlay).init();
    new MenuEntry(overlay).init();
    new ChatOpener().init();
    console.log(`%cRecruiter %cv${"0.7.0"} is running.`, "font-weight: 700; color: #0070f3;", "color: inherit;");
  }
  if (window.self === window.top) boot();

})();