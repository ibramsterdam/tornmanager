// ==UserScript==
// @name         Torn Manager
// @namespace    tornmanager
// @version      0.3.12
// @author       Bram [2728237]
// @description  Torn Manager userscript
// @license      All rights reserved
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%230070f3'/%3E%3Ctext x='32' y='43' text-anchor='middle' font-family='Arial,Helvetica,sans-serif' font-weight='900' font-size='30' fill='white'%3ETM%3C/text%3E%3C/svg%3E
// @downloadURL  https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tornmanager.user.js
// @updateURL    https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tornmanager.user.js
// @match        https://www.torn.com/*
// @connect      torn.com
// @connect      api.torn.com
// @connect      tornmanager.com
// @connect      raw.githubusercontent.com
// @grant        GM.notification
// @grant        GM.xmlHttpRequest
// @grant        GM_addStyle
// @run-at       document-start
// ==/UserScript==

(t=>{if(typeof GM_addStyle=="function"){GM_addStyle(t);return}const o=document.createElement("style");o.textContent=t,document.head.append(o)})(` .tornmanager-icon{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='17' fill='white'%3ETM%3C/text%3E%3C/svg%3E")!important;background-position:center!important;background-size:contain!important;background-repeat:no-repeat!important;cursor:pointer!important}.tornmanager-icon:before,.tornmanager-icon:after{content:none!important;display:none!important}.tornmanager-menu-item a{display:flex!important;align-items:center;gap:8px;background-image:none!important}.tornmanager-menu-icon{flex:none;width:16px;height:16px;border-radius:4px;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='15' fill='white'%3ETM%3C/text%3E%3C/svg%3E");background-size:contain;background-repeat:no-repeat;background-position:center}.tm-overlay-backdrop{position:fixed;top:0;right:0;bottom:0;left:0;z-index:999999;background:#0000;display:flex;align-items:center;justify-content:center;pointer-events:none;transition:background .3s ease}.tm-overlay-backdrop.tm-overlay--visible{background:#0009;pointer-events:auto}.tm-overlay-panel{position:relative;width:520px;max-width:90vw;max-height:80vh;overflow-y:auto;background:#1c1c1e;border:1px solid #333;border-radius:12px;padding:40px 32px;box-shadow:0 24px 64px #00000080;opacity:0;transform:translateY(24px) scale(.96);transition:opacity .3s ease,transform .3s ease,width .3s ease;box-sizing:border-box}.tm-overlay-panel--war{width:660px}.tm-overlay--visible .tm-overlay-panel{opacity:1;transform:translateY(0) scale(1)}.tm-overlay-close{position:absolute;top:12px;right:16px;background:none;border:none;color:#888;font-size:24px;cursor:pointer;line-height:1;padding:4px 8px;border-radius:4px;transition:color .15s ease,background .15s ease}.tm-overlay-close:hover{color:#fff;background:#ffffff1a}.tm-update-notice{display:flex;flex-wrap:wrap;align-items:center;justify-content:center;gap:8px;margin:-16px -12px 20px;padding:9px 14px;font-size:12.5px;color:#ffcc80;background:#fb8c001f;border:1px solid rgba(251,140,0,.35);border-radius:8px;text-align:center}.tm-update-link{font-weight:700;color:#fb8c00;text-decoration:none;white-space:nowrap}.tm-update-link:hover{text-decoration:underline}.tm-overlay-title{margin:0;font-size:24px;font-weight:700;color:#fff;text-align:center}.tm-overlay-title--left{font-size:21px;text-align:left;padding-right:36px}.tm-tabs{display:flex;gap:2px;margin-top:14px;border-bottom:1px solid #2e2e30}.tm-tab{display:inline-flex;align-items:center;gap:7px;margin-bottom:-1px;padding:9px 14px 10px;font-size:13.5px;font-weight:600;color:#9a9aa2;background:none;border:none;border-bottom:2px solid transparent;cursor:pointer;transition:color .15s ease}.tm-tab:hover{color:#d6d6db}.tm-tab--active{color:#fff;border-bottom-color:#0070f3}.tm-tab--locked{color:#6a6a70}.tm-tab--locked:hover{color:#9a9aa2}.tm-tab-lock{display:inline-flex;opacity:.85}.tm-tab--icon{margin-left:auto;padding:9px 10px 10px}.tm-tab--icon svg{display:block}.tm-tab-content .tm-sub,.tm-tab-content .tm-war{margin-top:16px}.tm-auth{display:flex;flex-direction:column;align-items:center;gap:16px}.tm-auth-subtitle{margin:0;font-size:14px;color:#888;text-align:center}.tm-auth-form{display:flex;flex-direction:column;gap:12px;width:100%;max-width:340px;margin-top:8px}.tm-auth-input{width:100%;padding:10px 14px;font-size:14px;font-family:monospace;color:#fff;background:#111;border:1px solid #333;border-radius:8px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.tm-auth-input:focus{border-color:#0070f3}.tm-auth-button{width:100%;padding:10px 0;font-size:14px;font-weight:600;color:#fff;background:#0070f3;border:none;border-radius:8px;cursor:pointer;transition:background .15s ease}.tm-auth-button:hover{background:#0061d5}.tm-auth-button:disabled{background:#333;cursor:not-allowed;color:#666}.tm-auth-error{margin:0;font-size:13px;color:#e53935;text-align:center;min-height:18px}.tm-auth-hint{margin:0;font-size:12px;line-height:1.5;color:#777;text-align:center}.tm-auth-hint strong{color:#aaa}.tm-auth-hint a{color:#0070f3;text-decoration:none}.tm-auth-hint a:hover{text-decoration:underline}.tm-sub{margin-top:24px;padding:20px;background:#161618;border:1px solid #333;border-radius:10px}.tm-sub-title{margin:0 0 12px;font-size:15px;font-weight:600;color:#fff;text-align:center}.tm-sub-note{margin:0 0 14px;padding:8px 12px;font-size:12px;line-height:1.5;color:#9ab8dd;text-align:center;background:#0070f314;border:1px solid rgba(0,112,243,.3);border-radius:7px}.tm-sub-status{font-size:14px;font-weight:600;text-align:center}.tm-sub-status--active{color:#4caf50}.tm-sub-status--inactive{color:#888}.tm-sub-status--warn{color:#fb8c00}.tm-sub-status--error{color:#e53935}.tm-sub-countdown{margin:4px 0 0;font-size:22px;font-weight:700;font-variant-numeric:tabular-nums;color:#fff;text-align:center;letter-spacing:.5px}.tm-sub-refresh{display:block;margin:16px auto 0;padding:7px 16px;font-size:12px;font-weight:500;color:#aaa;background:none;border:1px solid #333;border-radius:6px;cursor:pointer;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-sub-refresh:hover{color:#fff;border-color:#555;background:#ffffff0d}.tm-sub-refresh:disabled{color:#555;cursor:not-allowed;border-color:#2a2a2a}.tm-sub-info{margin-top:16px;padding-top:12px;border-top:1px solid #2a2a2a;font-size:12px;line-height:1.5;color:#777;text-align:center}.tm-sub-info a{color:#0070f3;text-decoration:none}.tm-sub-info a:hover{text-decoration:underline}.tm-war{margin-top:16px;padding:20px;background:#161618;border:1px solid #333;border-radius:10px}.tm-war-head{margin-bottom:14px}.tm-war-head-row{display:flex;align-items:baseline;justify-content:space-between;gap:12px;margin-bottom:8px}.tm-war-head-left{display:flex;align-items:baseline;gap:6px;min-width:0;font-size:13px;color:#888}.tm-war-head-left--muted{color:#666}.tm-war-head-left--error{color:#e53935}.tm-war-head-vs{font-size:11px;font-style:italic;color:#666}.tm-war-head-enemy{font-size:14px;font-weight:700;color:#e53935;text-decoration:none;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-war-head-enemy:hover{color:#ff6659;text-decoration:underline}.tm-war-head-score{flex:none;font-size:15px;font-weight:700;font-variant-numeric:tabular-nums}.tm-war-score--up{color:#4caf50}.tm-war-score--down{color:#e53935}.tm-war-head-sep{font-weight:400;color:#555}.tm-war-head-target{font-size:12px;font-weight:400;color:#555}.tm-war-bar{height:3px;border-radius:2px;background:#2a2a2c;overflow:hidden}.tm-war-bar-fill{height:100%;border-radius:2px;background:#4caf50;transition:width .5s ease}.tm-war-bar-fill--losing{background:#e53935}.tm-tt-add{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin-bottom:12px}.tm-tt-add-input{flex:1;min-width:160px;padding:7px 11px;font-size:12.5px;color:#fff;background:#111;border:1px solid #333;border-radius:7px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.tm-tt-add-input:focus{border-color:#0070f3}.tm-tt-add-button{padding:7px 16px;font-size:12.5px;font-weight:600;color:#fff;background:#0070f3;border:none;border-radius:7px;cursor:pointer;white-space:nowrap;transition:background .15s ease}.tm-tt-add-button:hover{background:#0061d5}.tm-tt-add-error{width:100%;font-size:12px;color:#e53935}.tm-tt-add-error:empty{display:none}.tm-tt-wrap{border:1px solid #2a2a2c;border-radius:8px;overflow:auto;max-height:50vh}.tm-tt{width:100%;border-collapse:collapse;font-size:12.5px;text-align:left}.tm-tt th{position:sticky;top:0;z-index:1;padding:10px 12px;background:#1a1a1c;border-bottom:1px solid #2a2a2c;font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.5px;color:#888;text-align:left;white-space:nowrap}.tm-tt-sortable{cursor:pointer;-webkit-user-select:none;user-select:none}.tm-tt-sortable:hover{color:#fff}.tm-tt-arrow{display:inline-block;opacity:0;transition:transform .15s ease}.tm-tt-sort-active .tm-tt-arrow{opacity:1}.tm-tt-sort-asc .tm-tt-arrow{transform:rotate(180deg)}.tm-tt td{padding:11px 12px;border-bottom:1px solid #222;color:#ccc;white-space:nowrap}.tm-tt th:first-child,.tm-tt td:first-child{width:100%;padding-left:14px}.tm-tt tbody tr:last-child td{border-bottom:none}.tm-tt tbody tr{cursor:pointer}.tm-tt tbody tr:hover{background:#ffffff0a}.tm-tt tbody tr:hover .tm-tt-name{color:#ff6659}.tm-tt-name{color:#fff;font-weight:600;text-decoration:none}.tm-tt-name:hover{color:#e53935;text-decoration:underline}.tm-tt-name--unknown{color:#666;font-weight:500}.tm-tt-nodata{color:#444}.tm-loc--torn{color:#666}.tm-loc--plane{color:#42a5f5;font-weight:500}.tm-tt-empty{margin:4px 0 0;font-size:13px;color:#666;text-align:center}.tm-tt-remove-cell{width:26px;text-align:right}.tm-tt-remove{padding:2px 6px;font-size:15px;line-height:1;color:#555;background:none;border:none;border-radius:4px;cursor:pointer;opacity:.25;transition:color .15s ease,background .15s ease,opacity .15s ease}.tm-tt tbody tr:hover .tm-tt-remove,.tm-tt-remove:focus-visible{opacity:1}.tm-tt-remove:hover{color:#e53935;background:#e539351a}.tm-status{display:inline-block;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:600}.tm-status--okay{color:#4caf50;background:#4caf501f}.tm-status--hospital{color:#e53935;background:#e539351f}.tm-status--jail{color:#fb8c00;background:#fb8c001f}.tm-status--traveling{color:#42a5f5;background:#42a5f51f}.tm-status--abroad{color:#ab47bc;background:#ab47bc1f}.tm-status--unknown{color:#888;background:#ffffff0f}.tm-action{display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:500}.tm-action:before{content:"";width:6px;height:6px;border-radius:50%;background:currentColor}.tm-action--online{color:#4caf50}.tm-action--idle{color:#fb8c00}.tm-action--offline{color:#666}.tm-timer{font-weight:600;font-variant-numeric:tabular-nums}.tm-timer--hospital{color:#e53935}.tm-timer--travel{color:#42a5f5}.tm-timer--landing{color:#fb8c00}.tm-timer--soon{animation:tm-pulse 1s infinite}.tm-timer-sep{font-weight:400;color:#555}.tm-tt [data-timer-until]:hover,.tm-tt [data-travel-eta]:hover,.tm-tt [data-travel-fast-eta]:hover{text-decoration:underline dotted;text-underline-offset:3px}.tm-toast{position:fixed;bottom:32px;left:50%;z-index:1000000;padding:8px 16px;font-size:12.5px;font-weight:600;color:#fff;background:#2a2a2c;border:1px solid #444;border-radius:8px;box-shadow:0 8px 24px #0006;opacity:0;transform:translate(-50%,8px);transition:opacity .2s ease,transform .2s ease;pointer-events:none}.tm-toast--visible{opacity:1;transform:translate(-50%)}@media(max-width:600px){.tm-overlay-panel{max-width:96vw;max-height:88vh;padding:26px 16px 18px}.tm-tab{padding:9px 10px 10px;font-size:13px}.tm-chats-room{flex-direction:column;align-items:stretch;gap:8px}.tm-chats-room-actions{justify-content:flex-end}}@keyframes tm-pulse{50%{opacity:.4}}.tm-tab-content .tm-chats{margin-top:16px}.tm-chats-form{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin-bottom:14px}.tm-chats-input{flex:1;min-width:180px;padding:8px 12px;font-size:13px;color:#fff;background:#111;border:1px solid #333;border-radius:7px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.tm-chats-input:focus{border-color:#0070f3}.tm-chats-create{padding:8px 16px;font-size:12.5px;font-weight:600;color:#fff;background:#0070f3;border:none;border-radius:7px;cursor:pointer;white-space:nowrap;transition:background .15s ease}.tm-chats-create:hover{background:#0061d5}.tm-chats-error{width:100%;font-size:12px;color:#e53935}.tm-chats-error:empty{display:none}.tm-chats-list{display:flex;flex-direction:column;gap:8px}.tm-chats-section-label{margin:10px 0 2px;font-size:10.5px;font-weight:600;text-transform:uppercase;letter-spacing:.06em;color:#6a6a70}.tm-chats-section-label:first-child{margin-top:0}.tm-chats-section-note{margin:0 0 6px;font-size:11px;line-height:1.4;color:#6a6a70}.tm-chats-empty{display:flex;flex-direction:column;align-items:center;gap:6px;margin:8px 0;padding:26px 20px;background:#161618;border:1px solid #303032;border-radius:10px;text-align:center;color:#4a9df8}.tm-chats-empty-title{margin:6px 0 0;font-size:14.5px;font-weight:700;color:#fff}.tm-chats-empty-text{margin:0;max-width:44ch;font-size:12.5px;line-height:1.55;color:#9a9aa2}.tm-chats-room{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:10px 14px;background:#161618;border:1px solid #303032;border-radius:8px}.tm-chats-room-info{display:flex;flex-direction:column;gap:1px;min-width:0}.tm-chats-room-name{font-size:13.5px;font-weight:600;color:#fff;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-chats-room-meta{font-size:11.5px;color:#777}.tm-chats-room-actions{display:flex;gap:6px;flex:none}.tm-chats-btn{padding:5px 12px;font-size:12px;font-weight:500;color:#aaa;background:none;border:1px solid #3a3a3d;border-radius:6px;cursor:pointer;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-chats-btn:hover{color:#fff;border-color:#555}.tm-chats-btn--primary{color:#fff;background:#0070f3;border-color:#0070f3}.tm-chats-btn--primary:hover{background:#0061d5;border-color:#0061d5}.tm-chats-btn--danger{color:#e05650}.tm-chats-btn--danger:hover{color:#ff6659;border-color:#e53935;background:#e539351a}.tm-chats-hint{margin:14px 0 0;font-size:12px;line-height:1.5;color:#666;text-align:center}.tm-chats-toggle{display:flex;align-items:center;justify-content:center;gap:7px;margin-top:10px;font-size:12px;color:#888;cursor:pointer;-webkit-user-select:none;user-select:none}.tm-chats-toggle input{accent-color:#0070f3;cursor:pointer}.tm-chat-fab{position:fixed;right:14px;bottom:110px;z-index:99990;display:flex;align-items:center;justify-content:center;width:34px;height:34px;padding:0;border:none;border-radius:8px;background:none;cursor:grab;touch-action:none;-webkit-user-select:none;user-select:none;opacity:.9;box-shadow:0 4px 14px #0006;transition:opacity .15s ease,transform .15s ease}.tm-chat-fab:hover{opacity:1;transform:scale(1.06)}.tm-chat-fab:active{cursor:grabbing}.tm-chat-fab svg{display:block;border-radius:8px;pointer-events:none}.tm-chat-fab-dot{display:none;position:absolute;top:-3px;right:-3px;width:10px;height:10px;border-radius:50%;background:#e53935;border:2px solid #1c1c1e}.tm-chat-fab--unread .tm-chat-fab-dot{display:block;animation:tm-pulse 1.5s infinite}.tm-chat-menu{position:fixed;right:16px;bottom:150px;z-index:99991;display:none;flex-direction:column;gap:2px;min-width:180px;max-width:240px;padding:6px;background:#1c1c1e;border:1px solid #333;border-radius:10px;box-shadow:0 12px 40px #00000080}.tm-chat-menu--open{display:flex}.tm-chat-menu-item{display:flex;align-items:center;gap:8px;padding:8px 10px;font-size:12.5px;font-weight:600;color:#bbb;text-align:left;background:none;border:none;border-radius:7px;cursor:pointer;transition:color .15s ease,background .15s ease}.tm-chat-menu-item:hover{color:#fff;background:#ffffff0f}.tm-chat-menu-item--open{color:#fff;background:#0070f326}.tm-chat-menu-item-label{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-chat-menu-item-dot{display:none;width:7px;height:7px;border-radius:50%;background:#e53935;flex:none}.tm-chat-menu-item--unread .tm-chat-menu-item-dot{display:block}.tm-cb{position:fixed;right:12px;bottom:100px;z-index:99990;display:flex;flex-direction:column;width:330px;max-width:calc(100vw - 24px);height:440px;max-height:calc(100vh - 120px);background:#1c1c1e;border:1px solid #333;border-radius:10px;box-shadow:0 12px 40px #00000080;overflow:hidden;font-size:12.5px;animation:tm-cb-in .15s ease}@keyframes tm-cb-in{0%{opacity:0;transform:translateY(10px)}}.tm-cb-skeleton{display:flex;flex-direction:column;gap:10px;padding-top:2px}.tm-cb-skeleton-row{display:flex;align-items:center;gap:6px}.tm-cb-skel{height:10px;border-radius:4px;background:#26262a;animation:tm-skel 1.2s ease-in-out infinite}@keyframes tm-skel{50%{opacity:.45}}.tm-cb-header{display:flex;align-items:center;justify-content:space-between;gap:8px;padding:8px 10px 8px 14px;background:#161618;border-bottom:1px solid #2a2a2c;flex:none;cursor:grab;touch-action:none;-webkit-user-select:none;user-select:none}.tm-cb-header:active{cursor:grabbing}.tm-cb-action{cursor:pointer;touch-action:auto}.tm-cb-title{display:flex;align-items:baseline;gap:6px;min-width:0}.tm-cb-name{font-size:13px;font-weight:700;color:#fff;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-cb-count{font-size:11px;color:#777;flex:none}.tm-cb-lock{display:inline-flex;color:#4caf50;flex:none}.tm-cb-body--locked{color:#6a6a70;font-style:italic}.tm-cb-actions{display:flex;gap:2px;flex:none}.tm-cb-action{display:inline-flex;align-items:center;justify-content:center;width:24px;height:24px;padding:0;font-size:13px;line-height:1;color:#888;background:none;border:none;border-radius:5px;cursor:pointer;transition:color .15s ease,background .15s ease}.tm-cb-action:hover{color:#fff;background:#ffffff14}.tm-cb-messages{flex:1;overflow-y:auto;padding:10px 12px;display:flex;flex-direction:column;gap:5px}.tm-cb-row{line-height:1.45;word-break:break-word}.tm-cb-row--own{padding:1px 6px;margin:0 -6px;border-radius:5px;background:#0070f317}.tm-cb-sender{margin-right:5px;font-weight:700;color:#42a5f5;text-decoration:none}a.tm-cb-sender:hover{text-decoration:underline}.tm-cb-body{color:#ddd}.tm-cb-divider{margin:6px 0 2px;font-size:10.5px;color:#555;text-align:center;font-variant-numeric:tabular-nums}.tm-cb-system{font-size:11.5px;color:#666;font-style:italic;text-align:center}.tm-cb-composer{display:flex;align-items:flex-end;gap:6px;padding:8px 10px;background:#161618;border-top:1px solid #2a2a2c;flex:none}.tm-cb-input{flex:1;height:34px;padding:8px 10px;font-size:12.5px;font-family:inherit;color:#fff;background:#111;border:1px solid #333;border-radius:7px;outline:none;resize:none;box-sizing:border-box;transition:border-color .15s ease}.tm-cb-input:focus{border-color:#0070f3}.tm-cb-counter{font-size:10.5px;color:#fb8c00;font-variant-numeric:tabular-nums;align-self:center}.tm-cb-counter:empty{display:none}.tm-cb-send{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;padding:0;color:#fff;background:#0070f3;border:none;border-radius:7px;cursor:pointer;flex:none;transition:background .15s ease}.tm-cb-send:hover{background:#0061d5}.tm-remove-key{display:block;margin:24px auto 0;padding:8px 20px;font-size:13px;font-weight:500;color:#e53935;background:none;border:1px solid #333;border-radius:8px;cursor:pointer;transition:background .15s ease,border-color .15s ease}.tm-remove-key:hover{background:#e539351a;border-color:#e53935}.tm-footer{display:flex;flex-direction:column;align-items:center;gap:8px;margin-top:32px;padding-top:16px;border-top:1px solid #333}.tm-footer-row{display:flex;align-items:center;justify-content:center;gap:8px}.tm-footer-link{font-size:12px;color:#888;text-decoration:none;transition:color .15s ease}.tm-footer-link:hover{color:#fff}.tm-footer-link--button{padding:0;background:none;border:none;cursor:pointer}.tm-footer-divider{font-size:12px;color:#555}.tm-footer-version{font-size:10.5px;color:#555;font-variant-numeric:tabular-nums}.tm-footer-copy-log,.tm-footer-clear-log{font-size:11px;padding:3px 10px;border-radius:4px;cursor:pointer;border:1px solid #333;background:none;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-footer-copy-log{color:#e53935}.tm-footer-copy-log:hover{color:#ff6659;border-color:#e53935;background:#e539351a}.tm-footer-clear-log{color:#666}.tm-footer-clear-log:hover{color:#aaa;border-color:#555;background:#ffffff0d} `);

(function () {
  'use strict';

  const STORAGE_KEY$2 = "tm_errors";
  const MAX_ENTRIES = 50;
  class Logger {
    log(error, context = "unknown") {
      const errors = this.getAll();
      const entry = {
        message: (error == null ? void 0 : error.message) || String(error),
        stack: (error == null ? void 0 : error.stack) || null,
        context,
        timestamp: (/* @__PURE__ */ new Date()).toISOString()
      };
      errors.push(entry);
      if (errors.length > MAX_ENTRIES) errors.splice(0, errors.length - MAX_ENTRIES);
      try {
        localStorage.setItem(STORAGE_KEY$2, JSON.stringify(errors));
      } catch {
      }
    }
    getAll() {
      try {
        const raw = localStorage.getItem(STORAGE_KEY$2);
        return raw ? JSON.parse(raw) : [];
      } catch {
        return [];
      }
    }
    clear() {
      localStorage.removeItem(STORAGE_KEY$2);
    }
    format() {
      const errors = this.getAll();
      if (!errors.length) return "No errors logged.";
      return errors.map(
        (e, i) => `[${i + 1}] ${e.timestamp}
Context: ${e.context}
Message: ${e.message}${e.stack ? `
Stack: ${e.stack}` : ""}`
      ).join("\n\n");
    }
  }
  const STORAGE_KEY$1 = "tm_user";
  const API_BASE$2 = "https://tornmanager.com";
  class Auth {
    getUser() {
      try {
        const raw = localStorage.getItem(STORAGE_KEY$1);
        return raw ? JSON.parse(raw) : null;
      } catch {
        return null;
      }
    }
    getApiKey() {
      var _a;
      return ((_a = this.getUser()) == null ? void 0 : _a.api_key) || null;
    }
    isAuthenticated() {
      const user = this.getUser();
      return user !== null && user.api_key != null;
    }
    clear() {
      localStorage.removeItem(STORAGE_KEY$1);
    }
    authenticate(apiKey) {
      return new Promise((resolve, reject) => {
        GM.xmlHttpRequest({
          method: "POST",
          url: `${API_BASE$2}/api/session`,
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json"
          },
          data: JSON.stringify({ api_key: apiKey }),
          onload(response) {
            if (response.status === 200) {
              try {
                const data = JSON.parse(response.responseText);
                localStorage.setItem(
                  STORAGE_KEY$1,
                  JSON.stringify({ ...data.user, api_key: apiKey })
                );
                resolve(data.user);
              } catch {
                reject(new Error("Invalid response from server"));
              }
            } else {
              try {
                const data = JSON.parse(response.responseText);
                reject(new Error(data.error || "Authentication failed"));
              } catch {
                reject(new Error("Authentication failed"));
              }
            }
          },
          onerror() {
            reject(new Error("Network error. Could not reach Tornmanager."));
          }
        });
      });
    }
    fetchSubscription({ refresh = false } = {}) {
      const apiKey = this.getApiKey();
      if (!apiKey) return Promise.reject(new Error("Not authenticated"));
      const body = { api_key: apiKey };
      if (refresh) body.refresh = true;
      return new Promise((resolve, reject) => {
        GM.xmlHttpRequest({
          method: "POST",
          url: `${API_BASE$2}/api/subscription`,
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json"
          },
          data: JSON.stringify(body),
          onload(response) {
            if (response.status === 200) {
              try {
                resolve(JSON.parse(response.responseText).subscription);
              } catch {
                reject(new Error("Invalid response from server"));
              }
            } else if (response.status === 429) {
              try {
                const data = JSON.parse(response.responseText);
                const err = new Error(data.error || "Too many requests");
                err.rateLimited = true;
                reject(err);
              } catch {
                const err = new Error("Too many requests. Try again later.");
                err.rateLimited = true;
                reject(err);
              }
            } else {
              try {
                const data = JSON.parse(response.responseText);
                reject(new Error(data.error || "Could not fetch subscription"));
              } catch {
                reject(new Error("Could not fetch subscription"));
              }
            }
          },
          onerror() {
            reject(new Error("Network error. Could not reach Tornmanager."));
          }
        });
      });
    }
  }
  const API_BASE$1 = "https://tornmanager.com";
  class ApiClient {
    constructor(auth2) {
      this.auth = auth2;
    }
    fetchCurrentWar() {
      const apiKey = this.auth.getApiKey();
      if (!apiKey) return Promise.reject(new Error("Not authenticated"));
      return new Promise((resolve, reject) => {
        GM.xmlHttpRequest({
          method: "POST",
          url: `${API_BASE$1}/api/current_war`,
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json"
          },
          data: JSON.stringify({ api_key: apiKey }),
          onload(response) {
            if (response.status === 200) {
              try {
                resolve(JSON.parse(response.responseText));
              } catch {
                reject(new Error("Invalid response from server"));
              }
            } else {
              try {
                const data = JSON.parse(response.responseText);
                reject(new Error(data.error || "Could not fetch war data"));
              } catch {
                reject(new Error("Could not fetch war data"));
              }
            }
          },
          onerror() {
            reject(new Error("Network error. Could not reach Tornmanager."));
          }
        });
      });
    }
  }
  const API_BASE = "https://tornmanager.com";
  class ChatClient {
    constructor(auth2) {
      this.auth = auth2;
    }
    me() {
      const user = this.auth.getUser();
      return { torn_id: (user == null ? void 0 : user.torn_id) || 0, name: (user == null ? void 0 : user.name) || "You" };
    }
    listRooms() {
      return this.post("/api/chat/rooms").then((data) => ({
        rooms: data.rooms || [],
        publicRooms: data.public_rooms || []
      }));
    }
    createRoom(name) {
      return this.post("/api/chat/create_room", { name, encrypted: true }).then((data) => data.room);
    }
    joinByToken(token) {
      return this.post("/api/chat/join", { token }).then((data) => data.room);
    }
    joinPublic(roomId) {
      return this.post("/api/chat/join_public", { room_id: roomId }).then((data) => data.room);
    }
    leaveRoom(roomId) {
      return this.post("/api/chat/leave", { room_id: roomId }).then(() => true);
    }
    fetchMessages(roomId, sinceId = 0) {
      return this.post("/api/chat/messages", { room_id: roomId, since_id: sinceId }).then((data) => data.messages);
    }
    sendMessage(roomId, body) {
      return this.post("/api/chat/send_message", { room_id: roomId, body }).then((data) => data.message);
    }
    post(path, params = {}) {
      const apiKey = this.auth.getApiKey();
      if (!apiKey) return Promise.reject(new Error("Not authenticated"));
      return new Promise((resolve, reject) => {
        GM.xmlHttpRequest({
          method: "POST",
          url: `${API_BASE}${path}`,
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json"
          },
          data: JSON.stringify({ api_key: apiKey, ...params }),
          onload(response) {
            let data = null;
            try {
              data = JSON.parse(response.responseText);
            } catch {
              reject(new Error("Invalid response from server"));
              return;
            }
            if (response.status >= 200 && response.status < 300) {
              resolve(data);
            } else {
              reject(new Error(data.error || "Chat request failed"));
            }
          },
          onerror() {
            reject(new Error("Network error. Could not reach Tornmanager."));
          }
        });
      });
    }
  }
  class AuthScreen {
    constructor(auth2) {
      this.auth = auth2;
    }
    render(onSuccess) {
      const container = document.createElement("div");
      container.className = "tm-auth";
      const title = document.createElement("h1");
      title.className = "tm-overlay-title";
      title.textContent = "Welcome to Tornmanager";
      const subtitle = document.createElement("p");
      subtitle.className = "tm-auth-subtitle";
      subtitle.textContent = "Sign in with your Torn API key to get started.";
      const form = document.createElement("form");
      form.className = "tm-auth-form";
      const input = document.createElement("input");
      input.type = "text";
      input.className = "tm-auth-input";
      input.placeholder = "Torn API key";
      input.autocomplete = "off";
      input.spellcheck = false;
      const button = document.createElement("button");
      button.type = "submit";
      button.className = "tm-auth-button";
      button.textContent = "Sign in";
      const error = document.createElement("p");
      error.className = "tm-auth-error";
      form.appendChild(input);
      form.appendChild(button);
      form.appendChild(error);
      form.addEventListener("submit", async (e) => {
        e.preventDefault();
        const apiKey = input.value.trim();
        if (!apiKey) {
          error.textContent = "Please enter an API key.";
          return;
        }
        button.disabled = true;
        button.textContent = "Signing in...";
        error.textContent = "";
        try {
          const user = await this.auth.authenticate(apiKey);
          onSuccess(user);
        } catch (err) {
          error.textContent = err.message;
          button.disabled = false;
          button.textContent = "Sign in";
        }
      });
      const hint = document.createElement("p");
      hint.className = "tm-auth-hint";
      hint.innerHTML = 'A key with <strong>Public</strong> access is all this extension needs — <a href="https://www.torn.com/preferences.php#tab=api" target="_blank" rel="noopener">create one here</a>.';
      container.appendChild(title);
      container.appendChild(subtitle);
      container.appendChild(form);
      container.appendChild(hint);
      return container;
    }
  }
  class SubscriptionSection {
    constructor(auth2, onUpdate) {
      this.auth = auth2;
      this.onUpdate = onUpdate;
      this.countdownInterval = null;
    }
    render() {
      const section = document.createElement("div");
      section.className = "tm-sub";
      const title = document.createElement("h2");
      title.className = "tm-sub-title";
      title.textContent = "Subscription";
      section.appendChild(title);
      const note = document.createElement("p");
      note.className = "tm-sub-note";
      note.textContent = "A subscription is an optional extra — it only unlocks additional features like the Ranked War tab. Chats and the rest of the extension are free for everyone.";
      section.appendChild(note);
      this.statusEl = document.createElement("div");
      this.statusEl.className = "tm-sub-status";
      section.appendChild(this.statusEl);
      this.countdownEl = document.createElement("p");
      this.countdownEl.className = "tm-sub-countdown";
      section.appendChild(this.countdownEl);
      this.refreshBtn = document.createElement("button");
      this.refreshBtn.className = "tm-sub-refresh";
      this.refreshBtn.textContent = "Check for new payments";
      this.refreshBtn.onclick = () => this.load(true);
      section.appendChild(this.refreshBtn);
      const info = document.createElement("div");
      info.className = "tm-sub-info";
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
        if (err.rateLimited) {
          this.statusEl.textContent = err.message;
          this.statusEl.className = "tm-sub-status tm-sub-status--warn";
        } else {
          this.statusEl.textContent = err.message;
          this.statusEl.className = "tm-sub-status tm-sub-status--error";
        }
        this.countdownEl.textContent = "";
      }).finally(() => {
        this.refreshBtn.disabled = false;
        this.refreshBtn.textContent = "Check for new payments";
      });
    }
    renderSubscription(sub) {
      if (sub.active && sub.expires_at) {
        this.statusEl.textContent = "Active";
        this.statusEl.className = "tm-sub-status tm-sub-status--active";
        this.startCountdown(new Date(sub.expires_at));
      } else {
        this.statusEl.textContent = "Inactive";
        this.statusEl.className = "tm-sub-status tm-sub-status--inactive";
        this.countdownEl.textContent = "No active subscription.";
      }
    }
    startCountdown(expiresAt) {
      this.stopCountdown();
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
        parts.push(`${hours}h`);
        parts.push(`${minutes}m`);
        parts.push(`${seconds}s`);
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
  const STORAGE_KEY = "tm_targets";
  class Targets {
    getAll() {
      try {
        const raw = localStorage.getItem(STORAGE_KEY);
        const list = raw ? JSON.parse(raw) : [];
        return Array.isArray(list) ? list : [];
      } catch {
        return [];
      }
    }
    add(id) {
      const list = this.getAll();
      if (list.includes(id)) return false;
      list.push(id);
      this.save(list);
      return true;
    }
    remove(id) {
      this.save(this.getAll().filter((entry) => entry !== id));
    }
    save(list) {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
      } catch {
      }
    }
    // Accepts a raw ID, a profile link (XID=...) or an attack link (user2ID=...).
    static parseId(value) {
      const text = String(value).trim();
      const match = text.match(/(?:XID=|user2ID=)(\d+)/i) || text.match(/^(\d+)$/);
      return match ? parseInt(match[1], 10) : null;
    }
  }
  function copyText(text, toastMessage = "Copied to clipboard") {
    var _a;
    const done = () => showToast(toastMessage);
    const fallback = () => {
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
      done();
    };
    if ((_a = navigator.clipboard) == null ? void 0 : _a.writeText) {
      navigator.clipboard.writeText(text).then(done).catch(fallback);
    } else {
      fallback();
    }
  }
  function showToast(text) {
    const toast = document.createElement("div");
    toast.className = "tm-toast";
    toast.textContent = text;
    document.body.appendChild(toast);
    requestAnimationFrame(() => toast.classList.add("tm-toast--visible"));
    setTimeout(() => {
      toast.classList.remove("tm-toast--visible");
      setTimeout(() => toast.remove(), 300);
    }, 1600);
  }
  const FLIGHT_TIMES = {
    "Mexico": { standard: 1560, airstrip: 1080, wlt: 780, bct: 480 },
    "Cayman Islands": { standard: 2100, airstrip: 1500, wlt: 1080, bct: 660 },
    "Canada": { standard: 2460, airstrip: 1740, wlt: 1200, bct: 720 },
    "Hawaii": { standard: 8040, airstrip: 5640, wlt: 4020, bct: 2400 },
    "United Kingdom": { standard: 9540, airstrip: 6660, wlt: 4800, bct: 2880 },
    "Argentina": { standard: 10020, airstrip: 7020, wlt: 4980, bct: 3e3 },
    "Switzerland": { standard: 10500, airstrip: 7380, wlt: 5280, bct: 3180 },
    "Japan": { standard: 13500, airstrip: 9480, wlt: 6780, bct: 4080 },
    "China": { standard: 14520, airstrip: 10140, wlt: 7260, bct: 4320 },
    "UAE": { standard: 16260, airstrip: 11400, wlt: 8100, bct: 4860 },
    "South Africa": { standard: 17820, airstrip: 12480, wlt: 8940, bct: 5340 }
  };
  const PLANE_TYPE_MAP = {
    private_jet: ["wlt"],
    light_aircraft: ["airstrip"],
    airliner: ["bct", "standard"]
  };
  const STATUS_ORDER = { Okay: 0, Traveling: 1, Jail: 2, Hospital: 3, Fallen: 4 };
  const ACTION_ORDER = { Online: 0, Idle: 1, Offline: 2 };
  const HOSPITAL_ADJECTIVES = {
    "Mexican": "Mexico",
    "Caymanian": "Cayman Islands",
    "Canadian": "Canada",
    "Hawaiian": "Hawaii",
    "British": "United Kingdom",
    "Argentinian": "Argentina",
    "Swiss": "Switzerland",
    "Japanese": "Japan",
    "Chinese": "China",
    "Emirati": "UAE",
    "South African": "South Africa"
  };
  const STATUS_CLASSES = {
    Okay: "tm-status--okay",
    Hospital: "tm-status--hospital",
    Jail: "tm-status--jail",
    Traveling: "tm-status--traveling",
    Abroad: "tm-status--abroad"
  };
  const ACTION_CLASSES = {
    Online: "tm-action--online",
    Idle: "tm-action--idle",
    Offline: "tm-action--offline"
  };
  const COLUMNS = [
    { key: "name", label: "Name" },
    { key: "status", label: "Status" },
    { key: "location", label: "Location" },
    { key: "activity", label: "Activity" },
    {
      key: "timer",
      label: "Timer",
      title: "Hospital/Jail: time until release. Travel: estimated arrival based on destination and plane type."
    },
    { key: null, label: "" }
  ];
  class TargetTable {
    constructor({ onRemove }) {
      this.onRemove = onRemove;
      this.rows = [];
      this.sortKey = "status";
      this.sortDirection = "asc";
      this.sortHeaders = {};
      this.tickInterval = null;
    }
    render() {
      const wrap = document.createElement("div");
      wrap.className = "tm-tt-wrap";
      const table = document.createElement("table");
      table.className = "tm-tt";
      const thead = document.createElement("thead");
      const headRow = document.createElement("tr");
      for (const column of COLUMNS) {
        const th = document.createElement("th");
        if (column.title) th.title = column.title;
        if (column.key) {
          th.className = "tm-tt-sortable";
          th.textContent = `${column.label} `;
          const arrow = document.createElement("span");
          arrow.className = "tm-tt-arrow";
          arrow.textContent = "▾";
          th.appendChild(arrow);
          th.onclick = () => this.sort(column.key);
          this.sortHeaders[column.key] = th;
        }
        headRow.appendChild(th);
      }
      thead.appendChild(headRow);
      table.appendChild(thead);
      this.tbody = document.createElement("tbody");
      this.tbody.addEventListener("click", (e) => {
        const button = e.target.closest(".tm-tt-remove");
        if (button) {
          this.onRemove(parseInt(button.dataset.id, 10));
          return;
        }
        const timer = e.target.closest("[data-timer-until], [data-travel-eta], [data-travel-fast-eta]");
        if (timer) {
          this.copyEta(timer);
          return;
        }
        if (e.target.closest("a")) return;
        const row = e.target.closest("tr[data-attack-url]");
        if (row) window.location.href = row.dataset.attackUrl;
      });
      table.appendChild(this.tbody);
      wrap.appendChild(table);
      this.updateSortIndicators();
      this.tickInterval = setInterval(() => this.tickTimers(), 1e3);
      return wrap;
    }
    destroy() {
      if (this.tickInterval) {
        clearInterval(this.tickInterval);
        this.tickInterval = null;
      }
    }
    update(rows) {
      this.rows = rows;
      this.rowsById = new Map(rows.map((row) => [String(row.id), row]));
      this.renderBody();
    }
    sort(key) {
      if (this.sortKey === key) {
        this.sortDirection = this.sortDirection === "asc" ? "desc" : "asc";
      } else {
        this.sortKey = key;
        this.sortDirection = "asc";
      }
      this.updateSortIndicators();
      this.renderBody();
    }
    updateSortIndicators() {
      for (const [key, th] of Object.entries(this.sortHeaders)) {
        th.classList.toggle("tm-tt-sort-active", key === this.sortKey);
        th.classList.toggle("tm-tt-sort-asc", key === this.sortKey && this.sortDirection === "asc");
      }
    }
    renderBody() {
      if (!this.tbody) return;
      const sorted = [...this.rows].sort((a, b) => this.compare(a, b));
      this.tbody.innerHTML = sorted.map((row) => this.renderRow(row)).join("");
    }
    compare(a, b) {
      var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j;
      const dir = this.sortDirection === "asc" ? 1 : -1;
      switch (this.sortKey) {
        case "name": {
          const aVal = (((_a = a.member) == null ? void 0 : _a.name) || `ID ${a.id}`).toLowerCase();
          const bVal = (((_b = b.member) == null ? void 0 : _b.name) || `ID ${b.id}`).toLowerCase();
          return aVal < bVal ? -1 * dir : aVal > bVal ? 1 * dir : 0;
        }
        case "status": {
          const aVal = a.member ? STATUS_ORDER[(_c = a.member.status) == null ? void 0 : _c.state] ?? 5 : 6;
          const bVal = b.member ? STATUS_ORDER[(_d = b.member.status) == null ? void 0 : _d.state] ?? 5 : 6;
          return (aVal - bVal) * dir;
        }
        case "location": {
          const aVal = a.member ? this.locationFor(a.member.status) : "~";
          const bVal = b.member ? this.locationFor(b.member.status) : "~";
          return aVal < bVal ? -1 * dir : aVal > bVal ? 1 * dir : 0;
        }
        case "activity": {
          const aVal = a.member ? ACTION_ORDER[(_e = a.member.last_action) == null ? void 0 : _e.status] ?? 3 : 4;
          const bVal = b.member ? ACTION_ORDER[(_f = b.member.last_action) == null ? void 0 : _f.status] ?? 3 : 4;
          if (aVal !== bVal) return (aVal - bVal) * dir;
          const aTime = ((_h = (_g = a.member) == null ? void 0 : _g.last_action) == null ? void 0 : _h.timestamp) || 0;
          const bTime = ((_j = (_i = b.member) == null ? void 0 : _i.last_action) == null ? void 0 : _j.timestamp) || 0;
          return (bTime - aTime) * dir;
        }
        case "timer": {
          const aVal = a.member ? this.getTimerSeconds(a.member) : -1;
          const bVal = b.member ? this.getTimerSeconds(b.member) : -1;
          return (aVal - bVal) * dir;
        }
        default:
          return 0;
      }
    }
    getTimerSeconds(member) {
      const status = member.status;
      if (!status) return -1;
      if (status.state === "Traveling") {
        if (!status.travel_started_at || !status.destination) return 999999;
        const flightData = FLIGHT_TIMES[status.destination];
        if (flightData) {
          const ticketTypes = PLANE_TYPE_MAP[status.plane_type] || ["standard"];
          const duration = flightData[ticketTypes[0]];
          const elapsed = Math.floor((Date.now() - new Date(status.travel_started_at)) / 1e3);
          const remaining2 = duration - elapsed;
          return remaining2 > 0 ? remaining2 : -1;
        }
      }
      if (!status.until) return -1;
      const remaining = Math.floor((new Date(status.until) - Date.now()) / 1e3);
      return remaining > 0 ? remaining : -1;
    }
    renderRow({ id, member }) {
      const attackUrl = `https://www.torn.com/page.php?sid=attack&user2ID=${id}`;
      const removeCell = `<td class="tm-tt-remove-cell"><button type="button" class="tm-tt-remove" data-id="${id}" title="Remove target">×</button></td>`;
      if (!member) {
        return `
        <tr data-id="${id}" data-attack-url="${attackUrl}">
          <td><a href="${attackUrl}" class="tm-tt-name tm-tt-name--unknown" title="Not in the current war data">ID ${id}</a></td>
          <td><span class="tm-tt-nodata">-</span></td>
          <td><span class="tm-tt-nodata">-</span></td>
          <td><span class="tm-tt-nodata">-</span></td>
          <td><span class="tm-tt-nodata">-</span></td>
          ${removeCell}
        </tr>`;
      }
      const status = member.status || { state: "Unknown" };
      const statusClass = STATUS_CLASSES[status.state] || "tm-status--unknown";
      const name = this.escapeHtml(member.name || `ID ${id}`);
      return `
      <tr data-id="${id}" data-attack-url="${attackUrl}">
        <td><a href="${attackUrl}" class="tm-tt-name" title="Attack ${name}">${name}</a></td>
        <td><span class="tm-status ${statusClass}">${this.escapeHtml(status.state || "Unknown")}</span></td>
        <td>${this.renderLocation(status)}</td>
        <td>${this.renderActivity(member)}</td>
        <td>${this.renderTimer(member)}</td>
        ${removeCell}
      </tr>`;
    }
    // "Plane" while flying, otherwise the country the player is actually in —
    // including foreign hospitals ("In a Japanese hospital ..." → Japan).
    locationFor(status) {
      if (!status) return "Torn";
      if (status.state === "Traveling") return "Plane";
      const description = status.description || "";
      if (status.state === "Abroad") return description.replace(/^In\s+/i, "") || "Abroad";
      const match = description.match(/^In an? ([A-Z][\w ]*?) hospital/i);
      if (match) return HOSPITAL_ADJECTIVES[match[1]] || match[1];
      return "Torn";
    }
    renderLocation(status) {
      const location = this.locationFor(status);
      const cls = location === "Torn" ? "tm-loc tm-loc--torn" : location === "Plane" ? "tm-loc tm-loc--plane" : "tm-loc";
      return `<span class="${cls}">${this.escapeHtml(location)}</span>`;
    }
    renderActivity(member) {
      const lastAction = member.last_action;
      if (!(lastAction == null ? void 0 : lastAction.status)) return '<span class="tm-tt-nodata">-</span>';
      const actionClass = ACTION_CLASSES[lastAction.status] || "tm-action--offline";
      return `<span class="tm-action ${actionClass}" title="${this.escapeHtml(lastAction.relative || "")}">${this.escapeHtml(lastAction.status)}</span>`;
    }
    renderTimer(member) {
      const status = member.status;
      if (!status) return '<span class="tm-tt-nodata">-</span>';
      if (status.state === "Traveling") return this.renderTravelTimer(status);
      if (!status.until) return '<span class="tm-tt-nodata">-</span>';
      const remaining = Math.floor((new Date(status.until) - Date.now()) / 1e3);
      if (remaining <= 0) return '<span class="tm-tt-nodata">-</span>';
      const soonClass = remaining < 60 ? " tm-timer--soon" : "";
      return `<span class="tm-timer tm-timer--hospital${soonClass}" data-timer-until="${status.until}" title="Click to copy release time">${this.formatCountdown(remaining)}</span>`;
    }
    renderTravelTimer(status) {
      const destination = status.destination;
      const description = status.description || "";
      const isReturning = status.returning === true || description.toLowerCase().includes("returning");
      const prefix = isReturning ? "← " : "";
      const suffix = isReturning ? "" : " →";
      const flightData = FLIGHT_TIMES[destination];
      if (!status.travel_started_at || !flightData) {
        const displayText = isReturning ? "← Torn" : `${destination || "Unknown"} →`;
        return `<span class="tm-timer tm-timer--travel" title="${this.escapeHtml(description)}">${this.escapeHtml(displayText)}</span>`;
      }
      const ticketTypes = PLANE_TYPE_MAP[status.plane_type] || ["standard"];
      const startedAt = new Date(status.travel_started_at).getTime();
      const now = Date.now();
      if (ticketTypes.length === 2) {
        const fastEtaMs = startedAt + flightData[ticketTypes[0]] * 1e3;
        const slowEtaMs = startedAt + flightData[ticketTypes[1]] * 1e3;
        const fastRemaining = Math.max(0, Math.floor((fastEtaMs - now) / 1e3));
        const slowRemaining = Math.max(0, Math.floor((slowEtaMs - now) / 1e3));
        if (slowRemaining <= 0) return '<span class="tm-timer tm-timer--landing">About to land</span>';
        const fastText = fastRemaining <= 0 ? "About to land" : this.formatCountdown(fastRemaining);
        const soonClass2 = fastRemaining > 0 && fastRemaining < 60 ? " tm-timer--soon" : "";
        return `<span class="tm-timer tm-timer--travel${soonClass2}" data-travel-fast-eta="${new Date(fastEtaMs).toISOString()}" data-travel-slow-eta="${new Date(slowEtaMs).toISOString()}" data-travel-returning="${isReturning}" title="${this.escapeHtml(description)} · Click to copy ETA"><span class="tm-tt-travel-fast">${prefix}${fastText}</span><span class="tm-timer-sep"> / </span><span class="tm-tt-travel-slow">${this.formatCountdown(slowRemaining)}${suffix}</span></span>`;
      }
      const etaMs = startedAt + flightData[ticketTypes[0]] * 1e3;
      const remaining = Math.max(0, Math.floor((etaMs - now) / 1e3));
      if (remaining <= 0) return '<span class="tm-timer tm-timer--landing">About to land</span>';
      const soonClass = remaining < 60 ? " tm-timer--soon" : "";
      return `<span class="tm-timer tm-timer--travel${soonClass}" data-travel-eta="${new Date(etaMs).toISOString()}" data-travel-returning="${isReturning}" title="${this.escapeHtml(description)} · Click to copy ETA">${prefix}${this.formatCountdown(remaining)}${suffix}</span>`;
    }
    tickTimers() {
      if (!this.tbody) return;
      this.tbody.querySelectorAll("[data-timer-until]").forEach((el) => {
        const remaining = Math.floor((new Date(el.dataset.timerUntil) - Date.now()) / 1e3);
        if (remaining <= 0) {
          el.textContent = "-";
          el.className = "tm-tt-nodata";
          el.removeAttribute("data-timer-until");
        } else {
          el.textContent = this.formatCountdown(remaining);
          el.className = remaining < 60 ? "tm-timer tm-timer--hospital tm-timer--soon" : "tm-timer tm-timer--hospital";
        }
      });
      this.tbody.querySelectorAll("[data-travel-eta]").forEach((el) => {
        const remaining = Math.max(0, Math.floor((new Date(el.dataset.travelEta) - Date.now()) / 1e3));
        const isReturning = el.dataset.travelReturning === "true";
        if (remaining <= 0) {
          el.textContent = "About to land";
          el.className = "tm-timer tm-timer--landing";
          el.removeAttribute("data-travel-eta");
        } else {
          el.textContent = `${isReturning ? "← " : ""}${this.formatCountdown(remaining)}${isReturning ? "" : " →"}`;
          el.className = remaining < 60 ? "tm-timer tm-timer--travel tm-timer--soon" : "tm-timer tm-timer--travel";
        }
      });
      this.tbody.querySelectorAll("[data-travel-fast-eta]").forEach((el) => {
        const now = Date.now();
        const fastRemaining = Math.max(0, Math.floor((new Date(el.dataset.travelFastEta) - now) / 1e3));
        const slowRemaining = Math.max(0, Math.floor((new Date(el.dataset.travelSlowEta) - now) / 1e3));
        const isReturning = el.dataset.travelReturning === "true";
        if (slowRemaining <= 0) {
          el.textContent = "About to land";
          el.className = "tm-timer tm-timer--landing";
          el.removeAttribute("data-travel-fast-eta");
          el.removeAttribute("data-travel-slow-eta");
        } else {
          const fastEl = el.querySelector(".tm-tt-travel-fast");
          const slowEl = el.querySelector(".tm-tt-travel-slow");
          const prefix = isReturning ? "← " : "";
          const suffix = isReturning ? "" : " →";
          if (fastEl) fastEl.textContent = fastRemaining <= 0 ? "About to land" : `${prefix}${this.formatCountdown(fastRemaining)}`;
          if (slowEl) slowEl.textContent = `${this.formatCountdown(slowRemaining)}${suffix}`;
          el.className = fastRemaining > 0 && fastRemaining < 60 ? "tm-timer tm-timer--travel tm-timer--soon" : "tm-timer tm-timer--travel";
        }
      });
    }
    copyEta(el) {
      var _a, _b, _c;
      const row = el.closest("tr");
      const id = row == null ? void 0 : row.dataset.id;
      if (!id) return;
      const member = (_b = (_a = this.rowsById) == null ? void 0 : _a.get(id)) == null ? void 0 : _b.member;
      const label = `${(member == null ? void 0 : member.name) || "User"} [${id}]`;
      let message = null;
      if (el.dataset.travelEta) {
        const eta = new Date(el.dataset.travelEta);
        const remaining = Math.floor((eta - Date.now()) / 1e3);
        if (remaining > 0) {
          message = `${label} will land in ${this.formatCountdown(remaining)} or at ${this.formatTct(eta)} TCT (estimate).`;
        }
      } else if (el.dataset.travelFastEta) {
        const fast = new Date(el.dataset.travelFastEta);
        const slow = new Date(el.dataset.travelSlowEta);
        const fastRemaining = Math.floor((fast - Date.now()) / 1e3);
        const slowRemaining = Math.floor((slow - Date.now()) / 1e3);
        if (slowRemaining > 0) {
          message = fastRemaining > 0 ? `${label} will land in ${this.formatCountdown(fastRemaining)} – ${this.formatCountdown(slowRemaining)}, between ${this.formatTct(fast)} and ${this.formatTct(slow)} TCT (estimate).` : `${label} will land within ${this.formatCountdown(slowRemaining)}, by ${this.formatTct(slow)} TCT (estimate).`;
        }
      } else if (el.dataset.timerUntil) {
        const until = new Date(el.dataset.timerUntil);
        const remaining = Math.floor((until - Date.now()) / 1e3);
        if (remaining > 0) {
          const place = ((_c = member == null ? void 0 : member.status) == null ? void 0 : _c.state) === "Jail" ? "jail" : "hospital";
          message = `${label} is out of ${place} in ${this.formatCountdown(remaining)}, at ${this.formatTct(until)} TCT.`;
        }
      }
      if (message) copyText(message);
    }
    // TCT is UTC.
    formatTct(date) {
      return date.toISOString().slice(11, 19);
    }
    formatCountdown(totalSeconds) {
      const hours = Math.floor(totalSeconds / 3600);
      const minutes = Math.floor(totalSeconds % 3600 / 60);
      const seconds = totalSeconds % 60;
      if (hours > 0) return `${hours}h ${minutes}m ${seconds}s`;
      return `${minutes}m ${seconds}s`;
    }
    escapeHtml(text) {
      const div = document.createElement("div");
      div.textContent = text;
      return div.innerHTML;
    }
  }
  const POLL_INTERVAL_MS$1 = 6e3;
  class WarSection {
    constructor(api2) {
      this.api = api2;
      this.targets = new Targets();
      this.members = {};
      this.war = null;
      this.pollInterval = null;
      this.table = null;
    }
    render() {
      this.section = document.createElement("div");
      this.section.className = "tm-war";
      this.section.appendChild(this.createHeader());
      this.section.appendChild(this.createAddForm());
      this.table = new TargetTable({ onRemove: (id) => this.removeTarget(id) });
      this.tableWrap = this.table.render();
      this.section.appendChild(this.tableWrap);
      this.emptyEl = document.createElement("p");
      this.emptyEl.className = "tm-tt-empty";
      this.emptyEl.textContent = "No targets yet. Add a player by their Torn ID.";
      this.section.appendChild(this.emptyEl);
      this.refreshTable();
      this.poll();
      this.pollInterval = setInterval(() => this.poll(), POLL_INTERVAL_MS$1);
      return this.section;
    }
    destroy() {
      if (this.pollInterval) {
        clearInterval(this.pollInterval);
        this.pollInterval = null;
      }
      if (this.table) {
        this.table.destroy();
        this.table = null;
      }
    }
    createHeader() {
      const header = document.createElement("div");
      header.className = "tm-war-head";
      const row = document.createElement("div");
      row.className = "tm-war-head-row";
      this.headLeft = document.createElement("div");
      this.headLeft.className = "tm-war-head-left";
      this.headLeft.textContent = "Loading war status...";
      this.headScore = document.createElement("div");
      this.headScore.className = "tm-war-head-score";
      row.appendChild(this.headLeft);
      row.appendChild(this.headScore);
      header.appendChild(row);
      this.bar = document.createElement("div");
      this.bar.className = "tm-war-bar";
      this.bar.style.display = "none";
      this.barFill = document.createElement("div");
      this.barFill.className = "tm-war-bar-fill";
      this.bar.appendChild(this.barFill);
      header.appendChild(this.bar);
      return header;
    }
    createAddForm() {
      const form = document.createElement("form");
      form.className = "tm-tt-add";
      this.input = document.createElement("input");
      this.input.type = "text";
      this.input.className = "tm-tt-add-input";
      this.input.placeholder = "Torn ID or profile link";
      this.input.autocomplete = "off";
      this.input.spellcheck = false;
      const button = document.createElement("button");
      button.type = "submit";
      button.className = "tm-tt-add-button";
      button.textContent = "Add";
      this.addError = document.createElement("span");
      this.addError.className = "tm-tt-add-error";
      form.appendChild(this.input);
      form.appendChild(button);
      form.appendChild(this.addError);
      form.addEventListener("submit", (e) => {
        e.preventDefault();
        this.addTarget(this.input.value);
      });
      return form;
    }
    addTarget(value) {
      this.addError.textContent = "";
      const id = Targets.parseId(value);
      if (!id) {
        this.addError.textContent = "Enter a Torn ID or profile link.";
        return;
      }
      if (!this.targets.add(id)) {
        this.addError.textContent = "Already in your list.";
        return;
      }
      this.input.value = "";
      this.refreshTable();
    }
    removeTarget(id) {
      this.targets.remove(id);
      this.refreshTable();
    }
    refreshTable() {
      const ids = this.targets.getAll();
      this.emptyEl.style.display = ids.length ? "none" : "";
      this.tableWrap.style.display = ids.length ? "" : "none";
      this.table.update(ids.map((id) => ({ id, member: this.members[id] || null })));
    }
    poll() {
      this.api.fetchCurrentWar().then((response) => {
        var _a;
        this.war = response.war || null;
        this.members = ((_a = this.war) == null ? void 0 : _a.members) || {};
        this.updateHeader();
        this.refreshTable();
      }).catch((err) => {
        this.headLeft.className = "tm-war-head-left tm-war-head-left--error";
        this.headLeft.textContent = err.message || "Could not load war data.";
      });
    }
    updateHeader() {
      this.headLeft.className = "tm-war-head-left";
      this.headLeft.innerHTML = "";
      this.headScore.innerHTML = "";
      if (!this.war) {
        this.headLeft.classList.add("tm-war-head-left--muted");
        this.headLeft.textContent = "No active war.";
        this.bar.style.display = "none";
        return;
      }
      const vs = document.createElement("span");
      vs.className = "tm-war-head-vs";
      vs.textContent = "vs";
      const enemy = document.createElement("a");
      enemy.className = "tm-war-head-enemy";
      enemy.href = `https://www.torn.com/factions.php?step=profile&ID=${this.war.enemy_faction_id}`;
      enemy.target = "_blank";
      enemy.rel = "noopener";
      enemy.textContent = this.war.enemy_faction_name || "Unknown faction";
      this.headLeft.appendChild(vs);
      this.headLeft.appendChild(enemy);
      const ours = this.war.our_score || 0;
      const theirs = this.war.their_score || 0;
      const target = this.war.target_score || 0;
      const lead = ours - theirs;
      const ourScore = document.createElement("span");
      ourScore.className = ours >= theirs ? "tm-war-score--up" : "tm-war-score--down";
      ourScore.textContent = ours.toLocaleString();
      const separator = document.createElement("span");
      separator.className = "tm-war-head-sep";
      separator.textContent = " – ";
      const theirScore = document.createElement("span");
      theirScore.className = theirs >= ours ? "tm-war-score--up" : "tm-war-score--down";
      theirScore.textContent = theirs.toLocaleString();
      this.headScore.appendChild(ourScore);
      this.headScore.appendChild(separator);
      this.headScore.appendChild(theirScore);
      if (target > 0) {
        const targetEl = document.createElement("span");
        targetEl.className = "tm-war-head-target";
        targetEl.textContent = ` / ${target.toLocaleString()}`;
        this.headScore.appendChild(targetEl);
        const percentage = Math.min(Math.max(lead / target * 100, 0), 100);
        this.bar.style.display = "";
        this.barFill.style.width = `${percentage}%`;
        this.barFill.classList.toggle("tm-war-bar-fill--losing", lead < 0);
      } else {
        this.bar.style.display = "none";
      }
    }
  }
  const KEYS_STORAGE = "tm_chat_keys";
  function toBase64Url(bytes) {
    let binary = "";
    for (const b of bytes) binary += String.fromCharCode(b);
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }
  function fromBase64Url(str) {
    const padded = str.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((str.length + 3) % 4);
    const binary = atob(padded);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    return bytes;
  }
  const ChatCrypto = {
    // A fresh 256-bit key as a URL-safe string for the invite link.
    generateKey() {
      const bytes = new Uint8Array(32);
      crypto.getRandomValues(bytes);
      return toBase64Url(bytes);
    },
    importKey(keyB64) {
      return crypto.subtle.importKey("raw", fromBase64Url(keyB64), "AES-GCM", false, ["encrypt", "decrypt"]);
    },
    async encrypt(keyB64, plaintext) {
      const key = await this.importKey(keyB64);
      const iv = new Uint8Array(12);
      crypto.getRandomValues(iv);
      const ciphertext = await crypto.subtle.encrypt(
        { name: "AES-GCM", iv },
        key,
        new TextEncoder().encode(plaintext)
      );
      const packed = new Uint8Array(iv.length + ciphertext.byteLength);
      packed.set(iv, 0);
      packed.set(new Uint8Array(ciphertext), iv.length);
      return toBase64Url(packed);
    },
    async decrypt(keyB64, payload) {
      const key = await this.importKey(keyB64);
      const packed = fromBase64Url(payload);
      const iv = packed.slice(0, 12);
      const ciphertext = packed.slice(12);
      const plaintext = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, ciphertext);
      return new TextDecoder().decode(plaintext);
    },
    // --- per-room key storage ---
    getKey(roomId) {
      return this.allKeys()[roomId] || null;
    },
    setKey(roomId, keyB64) {
      if (!keyB64) return;
      const keys = this.allKeys();
      keys[roomId] = keyB64;
      try {
        localStorage.setItem(KEYS_STORAGE, JSON.stringify(keys));
      } catch {
      }
    },
    allKeys() {
      try {
        const raw = localStorage.getItem(KEYS_STORAGE);
        const keys = raw ? JSON.parse(raw) : {};
        return typeof keys === "object" && keys !== null ? keys : {};
      } catch {
        return {};
      }
    }
  };
  class ChatsSection {
    constructor(chatDock2) {
      this.chatDock = chatDock2;
      this.client = chatDock2.client;
    }
    render() {
      this.section = document.createElement("div");
      this.section.className = "tm-chats";
      this.section.appendChild(this.createForm());
      this.listEl = document.createElement("div");
      this.listEl.className = "tm-chats-list";
      this.section.appendChild(this.listEl);
      const hint = document.createElement("p");
      hint.className = "tm-chats-hint";
      hint.textContent = "Share a room's invite link in any Torn chat — clicking it joins automatically.";
      this.section.appendChild(hint);
      const toggle = document.createElement("label");
      toggle.className = "tm-chats-toggle";
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.checked = !this.chatDock.isFabHidden();
      checkbox.onchange = () => this.chatDock.setFabVisible(checkbox.checked);
      const caption = document.createElement("span");
      caption.textContent = "Show floating chat button (drag it anywhere)";
      toggle.appendChild(checkbox);
      toggle.appendChild(caption);
      this.section.appendChild(toggle);
      this.refresh();
      return this.section;
    }
    destroy() {
    }
    createForm() {
      const form = document.createElement("form");
      form.className = "tm-chats-form";
      this.input = document.createElement("input");
      this.input.type = "text";
      this.input.className = "tm-chats-input";
      this.input.placeholder = "Room name (e.g. Hawaii squad)";
      this.input.maxLength = 40;
      this.input.autocomplete = "off";
      const button = document.createElement("button");
      button.type = "submit";
      button.className = "tm-chats-create";
      button.textContent = "Create room";
      this.error = document.createElement("span");
      this.error.className = "tm-chats-error";
      form.appendChild(this.input);
      form.appendChild(button);
      form.appendChild(this.error);
      form.addEventListener("submit", (e) => {
        e.preventDefault();
        this.createRoom(button);
      });
      return form;
    }
    createRoom(button) {
      this.error.textContent = "";
      const name = this.input.value.trim();
      if (!name) {
        this.error.textContent = "Give the room a name.";
        return;
      }
      button.disabled = true;
      button.textContent = "Creating...";
      this.client.createRoom(name).then((room) => {
        if (room.encrypted) ChatCrypto.setKey(room.id, ChatCrypto.generateKey());
        this.input.value = "";
        this.chatDock.openRoom(room);
        this.refresh();
      }).catch((err) => {
        this.error.textContent = err.message || "Could not create the room.";
      }).finally(() => {
        button.disabled = false;
        button.textContent = "Create room";
      });
    }
    refresh() {
      this.client.listRooms().then(({ rooms, publicRooms }) => this.renderList(rooms, publicRooms)).catch(() => {
        this.listEl.innerHTML = "";
        const error = document.createElement("p");
        error.className = "tm-chats-empty";
        error.textContent = "Could not load your rooms.";
        this.listEl.appendChild(error);
      });
    }
    renderList(rooms, publicRooms) {
      this.listEl.innerHTML = "";
      const joinedIds = new Set(rooms.map((room) => room.id));
      const privateRooms = rooms.filter((room) => room.kind !== "public");
      if (!privateRooms.length) {
        const empty = document.createElement("div");
        empty.className = "tm-chats-empty";
        empty.innerHTML = '<svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2z"/></svg><p class="tm-chats-empty-title">Chat rooms beyond faction chat</p><p class="tm-chats-empty-text">Create a room with anyone in Torn — war squads, trade partners, friends. Share its invite link in any chat and clicking it joins instantly. Free for everyone.</p>';
        this.listEl.appendChild(empty);
      } else {
        this.listEl.appendChild(this.sectionLabel("Your rooms"));
        this.listEl.appendChild(this.sectionNote("🔒 End-to-end encrypted — only people with the invite link can read them. Deleted 7 days after the last message."));
        for (const room of privateRooms) this.listEl.appendChild(this.renderRoom(room));
      }
      if (publicRooms.length) {
        this.listEl.appendChild(this.sectionLabel("Public rooms · anonymous"));
        this.listEl.appendChild(this.sectionNote("Messages are cleared every 48 hours."));
        for (const room of publicRooms) {
          this.listEl.appendChild(this.renderPublicRoom(room, joinedIds.has(room.id)));
        }
      }
    }
    sectionLabel(text) {
      const label = document.createElement("p");
      label.className = "tm-chats-section-label";
      label.textContent = text;
      return label;
    }
    sectionNote(text) {
      const note = document.createElement("p");
      note.className = "tm-chats-section-note";
      note.textContent = text;
      return note;
    }
    renderPublicRoom(room, joined) {
      const row = document.createElement("div");
      row.className = "tm-chats-room";
      const info = document.createElement("div");
      info.className = "tm-chats-room-info";
      const name = document.createElement("span");
      name.className = "tm-chats-room-name";
      name.textContent = room.name;
      const meta = document.createElement("span");
      meta.className = "tm-chats-room-meta";
      meta.textContent = `${room.member_count} member${room.member_count === 1 ? "" : "s"} · you appear anonymously`;
      info.appendChild(name);
      info.appendChild(meta);
      const actions = document.createElement("div");
      actions.className = "tm-chats-room-actions";
      const open = document.createElement("button");
      open.type = "button";
      open.className = "tm-chats-btn tm-chats-btn--primary";
      open.textContent = joined ? "Open" : "Join";
      open.onclick = () => this.openPublic(room, open);
      actions.appendChild(open);
      row.appendChild(info);
      row.appendChild(actions);
      return row;
    }
    // The shared key rides in the link but never leaves the browser otherwise.
    copyInvite(room) {
      if (!room.encrypted) {
        copyText(room.invite_url, "Invite link copied");
        return;
      }
      const key = ChatCrypto.getKey(room.id);
      if (!key) {
        showToast("Encryption key missing — rejoin via an invite link first");
        return;
      }
      copyText(`${room.invite_url}~${key}`, "Invite link copied");
    }
    openPublic(room, button) {
      button.disabled = true;
      this.client.joinPublic(room.id).then((joined) => {
        this.chatDock.openRoom(joined);
        this.refresh();
      }).catch((err) => {
        this.error.textContent = err.message || "Could not open the room.";
        button.disabled = false;
      });
    }
    renderRoom(room) {
      const row = document.createElement("div");
      row.className = "tm-chats-room";
      const info = document.createElement("div");
      info.className = "tm-chats-room-info";
      const name = document.createElement("span");
      name.className = "tm-chats-room-name";
      name.textContent = room.name;
      const meta = document.createElement("span");
      meta.className = "tm-chats-room-meta";
      meta.textContent = `${room.member_count} member${room.member_count === 1 ? "" : "s"}${room.host ? " · host" : ""}`;
      info.appendChild(name);
      info.appendChild(meta);
      const actions = document.createElement("div");
      actions.className = "tm-chats-room-actions";
      const open = document.createElement("button");
      open.type = "button";
      open.className = "tm-chats-btn tm-chats-btn--primary";
      open.textContent = "Open";
      open.onclick = () => this.chatDock.openRoomById(room.id);
      actions.appendChild(open);
      if (room.host && room.invite_url) {
        const invite = document.createElement("button");
        invite.type = "button";
        invite.className = "tm-chats-btn";
        invite.textContent = "Invite";
        invite.onclick = () => this.copyInvite(room);
        actions.appendChild(invite);
      }
      const leave = document.createElement("button");
      leave.type = "button";
      leave.className = "tm-chats-btn tm-chats-btn--danger";
      leave.textContent = "Leave";
      leave.onclick = () => {
        this.client.leaveRoom(room.id).then(() => {
          this.chatDock.refresh();
          this.refresh();
        });
      };
      actions.appendChild(leave);
      row.appendChild(info);
      row.appendChild(actions);
      return row;
    }
  }
  const CURRENT = "0.3.12";
  const MANIFEST_URL = "https://raw.githubusercontent.com/ibramsterdam/tornmanager/main/userscript/package.json";
  const DOWNLOAD_URL = "https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tornmanager.user.js";
  const CACHE_KEY = "tm_version_check";
  const CACHE_TTL_MS = 60 * 60 * 1e3;
  function isNewer(latest, current) {
    const a = latest.split(".").map(Number);
    const b = current.split(".").map(Number);
    for (let i = 0; i < Math.max(a.length, b.length); i++) {
      const diff = (a[i] || 0) - (b[i] || 0);
      if (diff !== 0) return diff > 0;
    }
    return false;
  }
  function cachedLatest() {
    try {
      const raw = localStorage.getItem(CACHE_KEY);
      if (!raw) return null;
      const { latest, at } = JSON.parse(raw);
      if (!latest || Date.now() - at > CACHE_TTL_MS) return null;
      return latest;
    } catch {
      return null;
    }
  }
  function fetchLatest() {
    return new Promise((resolve) => {
      GM.xmlHttpRequest({
        method: "GET",
        url: `${MANIFEST_URL}?t=${Math.floor(Date.now() / CACHE_TTL_MS)}`,
        headers: { Accept: "application/json" },
        onload(response) {
          try {
            const version = JSON.parse(response.responseText).version;
            if (version) {
              localStorage.setItem(CACHE_KEY, JSON.stringify({ latest: version, at: Date.now() }));
            }
            resolve(version || null);
          } catch {
            resolve(null);
          }
        },
        onerror() {
          resolve(null);
        }
      });
    });
  }
  const UpdateCheck = {
    current: CURRENT,
    // Resolves to the latest published version if this build is behind it,
    // otherwise null. Never rejects — a failed check simply shows no notice.
    async outdatedVersion() {
      const latest = cachedLatest() || await fetchLatest();
      return latest && isNewer(latest, CURRENT) ? latest : null;
    }
  };
  const LOCK_ICON = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';
  const COG_ICON = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>';
  class Overlay {
    constructor(auth2, api2, logger2, chatDock2) {
      this.auth = auth2;
      this.api = api2;
      this.logger = logger2;
      this.chatDock = chatDock2;
      this.overlay = null;
      this.panel = null;
      this.isOpen = false;
      this.subscriptionSection = null;
      this.warSection = null;
      this.chatsSection = null;
      this.subscription = null;
      this.activeTab = "chats";
      this.updateChecked = false;
      this.latestVersion = null;
    }
    open() {
      if (this.isOpen) return;
      if (!this.overlay) {
        this.overlay = this.createOverlay();
        document.body.appendChild(this.overlay);
      }
      this.renderPanel();
      this.renderUpdateNotice();
      this.overlay.offsetHeight;
      this.overlay.classList.add("tm-overlay--visible");
      this.isOpen = true;
      this.checkForUpdate();
    }
    checkForUpdate() {
      if (this.updateChecked) return;
      this.updateChecked = true;
      UpdateCheck.outdatedVersion().then((latest) => {
        if (!latest) return;
        this.latestVersion = latest;
        this.renderUpdateNotice();
      }).catch(() => {
      });
    }
    renderUpdateNotice() {
      if (!this.latestVersion || !this.panel) return;
      if (this.panel.querySelector(".tm-update-notice")) return;
      const notice = document.createElement("div");
      notice.className = "tm-update-notice";
      const text = document.createElement("span");
      text.textContent = `Update available — you're on v${UpdateCheck.current}, latest is v${this.latestVersion}.`;
      const link = document.createElement("a");
      link.href = DOWNLOAD_URL;
      link.target = "_blank";
      link.rel = "noopener";
      link.className = "tm-update-link";
      link.textContent = "Update now";
      notice.appendChild(text);
      notice.appendChild(link);
      this.panel.insertBefore(notice, this.panel.firstChild);
    }
    close() {
      if (!this.overlay || !this.isOpen) return;
      this.destroySections();
      this.overlay.classList.remove("tm-overlay--visible");
      this.isOpen = false;
    }
    destroySections() {
      if (this.subscriptionSection) {
        this.subscriptionSection.destroy();
        this.subscriptionSection = null;
      }
      if (this.warSection) {
        this.warSection.destroy();
        this.warSection = null;
      }
      if (this.chatsSection) {
        this.chatsSection.destroy();
        this.chatsSection = null;
      }
    }
    toggle() {
      if (this.isOpen) {
        this.close();
      } else {
        this.open();
      }
    }
    createOverlay() {
      const backdrop = document.createElement("div");
      backdrop.id = "tm-overlay-backdrop";
      backdrop.className = "tm-overlay-backdrop";
      this.panel = document.createElement("div");
      this.panel.className = "tm-overlay-panel";
      backdrop.appendChild(this.panel);
      backdrop.addEventListener("click", (e) => {
        if (e.target === backdrop) this.close();
      });
      document.addEventListener("keydown", (e) => {
        if (e.key === "Escape" && this.isOpen) this.close();
      });
      return backdrop;
    }
    renderPanel() {
      this.destroySections();
      this.panel.classList.remove("tm-overlay-panel--war");
      this.panel.innerHTML = "";
      const closeBtn = document.createElement("button");
      closeBtn.className = "tm-overlay-close";
      closeBtn.textContent = "×";
      closeBtn.onclick = () => this.close();
      this.panel.appendChild(closeBtn);
      if (this.auth.isAuthenticated()) {
        this.renderAuthenticatedPanel();
      } else {
        this.renderUnauthenticatedPanel();
      }
      this.panel.appendChild(this.createFooter());
    }
    renderAuthenticatedPanel() {
      const user = this.auth.getUser();
      const title = document.createElement("h1");
      title.className = "tm-overlay-title tm-overlay-title--left";
      title.textContent = `Welcome, ${user.name}`;
      this.panel.appendChild(title);
      this.panel.appendChild(this.createTabBar());
      this.tabContent = document.createElement("div");
      this.tabContent.className = "tm-tab-content";
      this.panel.appendChild(this.tabContent);
      if (this.subscription === null) {
        this.auth.fetchSubscription().then((sub) => this.setSubscription(sub)).catch(() => {
        });
      }
      this.renderActiveTab();
    }
    createTabBar() {
      const tabs = document.createElement("div");
      tabs.className = "tm-tabs";
      this.chatsTab = this.createTab("Chats", "chats");
      this.warTab = this.createTab("Ranked War", "war");
      this.warTabLock = document.createElement("span");
      this.warTabLock.className = "tm-tab-lock";
      this.warTabLock.innerHTML = LOCK_ICON;
      this.warTab.appendChild(this.warTabLock);
      this.settingsTab = this.createTab("", "settings");
      this.settingsTab.classList.add("tm-tab--icon");
      this.settingsTab.title = "Settings";
      this.settingsTab.innerHTML = COG_ICON;
      tabs.appendChild(this.chatsTab);
      tabs.appendChild(this.warTab);
      tabs.appendChild(this.settingsTab);
      return tabs;
    }
    createTab(label, name) {
      const tab = document.createElement("button");
      tab.className = "tm-tab";
      tab.textContent = label;
      tab.onclick = () => this.selectTab(name);
      return tab;
    }
    selectTab(name) {
      if (this.activeTab === name) return;
      this.activeTab = name;
      this.renderActiveTab();
    }
    renderActiveTab() {
      var _a;
      if (!this.tabContent) return;
      if (this.activeTab === "war" && !((_a = this.subscription) == null ? void 0 : _a.active)) {
        this.activeTab = "settings";
      }
      this.destroySections();
      this.updateTabState();
      this.panel.classList.toggle("tm-overlay-panel--war", this.activeTab === "war");
      this.tabContent.innerHTML = "";
      if (this.activeTab === "war") {
        this.renderWarTab();
      } else if (this.activeTab === "chats") {
        this.renderChatsTab();
      } else {
        this.renderSettingsTab();
      }
    }
    updateTabState() {
      var _a;
      const locked = !((_a = this.subscription) == null ? void 0 : _a.active);
      this.settingsTab.classList.toggle("tm-tab--active", this.activeTab === "settings");
      this.warTab.classList.toggle("tm-tab--active", this.activeTab === "war");
      this.chatsTab.classList.toggle("tm-tab--active", this.activeTab === "chats");
      this.warTab.classList.toggle("tm-tab--locked", locked);
      this.warTabLock.style.display = locked ? "" : "none";
      if (locked) {
        this.warTab.title = "Requires an active subscription";
      } else {
        this.warTab.removeAttribute("title");
      }
    }
    setSubscription(subscription) {
      this.subscription = subscription;
      if (this.warTab) this.updateTabState();
    }
    renderSettingsTab() {
      this.subscriptionSection = new SubscriptionSection(this.auth, (sub) => this.setSubscription(sub));
      this.tabContent.appendChild(this.subscriptionSection.render());
      const removeBtn = document.createElement("button");
      removeBtn.className = "tm-remove-key";
      removeBtn.textContent = "Remove API key";
      removeBtn.onclick = () => {
        this.auth.clear();
        this.subscription = null;
        this.activeTab = "chats";
        this.renderPanel();
      };
      this.tabContent.appendChild(removeBtn);
    }
    renderWarTab() {
      this.warSection = new WarSection(this.api);
      this.tabContent.appendChild(this.warSection.render());
    }
    renderChatsTab() {
      this.chatsSection = new ChatsSection(this.chatDock);
      this.tabContent.appendChild(this.chatsSection.render());
    }
    renderUnauthenticatedPanel() {
      const authScreen = new AuthScreen(this.auth);
      this.panel.appendChild(authScreen.render(() => this.renderPanel()));
    }
    createFooter() {
      const footer = document.createElement("footer");
      footer.className = "tm-footer";
      const links = document.createElement("div");
      links.className = "tm-footer-row";
      const profile = document.createElement("a");
      profile.href = "https://www.torn.com/profiles.php?XID=2728237";
      profile.target = "_blank";
      profile.rel = "noopener";
      profile.className = "tm-footer-link";
      profile.textContent = "Bram [2728237]";
      const privacy = document.createElement("a");
      privacy.href = "https://tornmanager.com/legal#privacy-policy";
      privacy.target = "_blank";
      privacy.rel = "noopener";
      privacy.className = "tm-footer-link";
      privacy.textContent = "Privacy Policy";
      const tos = document.createElement("a");
      tos.href = "https://tornmanager.com/legal#terms-of-service";
      tos.target = "_blank";
      tos.rel = "noopener";
      tos.className = "tm-footer-link";
      tos.textContent = "Terms of Service";
      const divider = document.createElement("span");
      divider.className = "tm-footer-divider";
      divider.textContent = "·";
      links.appendChild(profile);
      links.appendChild(divider.cloneNode(true));
      links.appendChild(privacy);
      links.appendChild(divider.cloneNode(true));
      links.appendChild(tos);
      links.appendChild(divider.cloneNode(true));
      const debug = document.createElement("button");
      debug.type = "button";
      debug.className = "tm-footer-link tm-footer-link--button";
      debug.textContent = "Copy debug info";
      debug.onclick = () => copyText(this.debugInfo(), "Debug info copied");
      links.appendChild(debug);
      footer.appendChild(links);
      const version = document.createElement("div");
      version.className = "tm-footer-version";
      version.textContent = `v${"0.3.12"}`;
      footer.appendChild(version);
      const errors = this.logger.getAll();
      if (errors.length > 0) {
        const errorRow = document.createElement("div");
        errorRow.className = "tm-footer-row";
        const copyBtn = document.createElement("button");
        copyBtn.className = "tm-footer-copy-log";
        copyBtn.textContent = `Copy error log (${errors.length})`;
        copyBtn.onclick = async () => {
          try {
            await navigator.clipboard.writeText(this.logger.format());
            copyBtn.textContent = "Copied!";
            setTimeout(() => {
              copyBtn.textContent = `Copy error log (${this.logger.getAll().length})`;
            }, 2e3);
          } catch {
            const ta = document.createElement("textarea");
            ta.value = this.logger.format();
            ta.style.position = "fixed";
            ta.style.opacity = "0";
            document.body.appendChild(ta);
            ta.select();
            document.execCommand("copy");
            document.body.removeChild(ta);
            copyBtn.textContent = "Copied!";
            setTimeout(() => {
              copyBtn.textContent = `Copy error log (${this.logger.getAll().length})`;
            }, 2e3);
          }
        };
        const clearBtn = document.createElement("button");
        clearBtn.className = "tm-footer-clear-log";
        clearBtn.textContent = "Clear";
        clearBtn.onclick = () => {
          this.logger.clear();
          errorRow.remove();
        };
        errorRow.appendChild(copyBtn);
        errorRow.appendChild(clearBtn);
        footer.appendChild(errorRow);
      }
      return footer;
    }
    // Environment snapshot for support reports — everything the icon/chat
    // mounting and API transport depend on, small enough to paste anywhere.
    debugInfo() {
      var _a;
      return [
        `TornManager v${"0.3.12"}`,
        `URL: ${window.location.href}`,
        `Viewport: ${window.innerWidth}x${window.innerHeight}`,
        `UA: ${navigator.userAgent}`,
        `Body classes: ${((_a = document.body) == null ? void 0 : _a.className) || "-"}`,
        `#sidebar present: ${!!document.getElementById("sidebar")}`,
        `Status-icons list present: ${!!document.querySelector("#sidebar ul[class^='status-icon']")}`,
        `TM sidebar icon mounted: ${!!document.getElementById("tornmanager-icon")}`,
        `Torn #chatRoot present: ${!!document.getElementById("chatRoot")}`,
        `GM.xmlHttpRequest available: ${typeof GM !== "undefined" && typeof GM.xmlHttpRequest === "function"}`,
        `PDA bridge available: ${typeof window.PDA_httpPost === "function"}`,
        `Signed in: ${this.auth.isAuthenticated()}`,
        `Errors logged: ${this.logger.getAll().length}`
      ].join("\n");
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
  }
  class Sidebar {
    constructor(overlay2) {
      this.overlay = overlay2;
    }
    init() {
      Dom.ready("#sidebar", (sidebar2) => this.onReady(sidebar2));
    }
    onReady(sidebar2) {
      const icons = sidebar2.querySelector("ul[class^='status-icon']");
      if (!icons || document.getElementById("tornmanager-icon")) return;
      const icon = document.createElement("li");
      icon.id = "tornmanager-icon";
      icon.className = "tornmanager-icon";
      icon.onclick = () => this.overlay.toggle();
      icons.appendChild(icon);
    }
  }
  class SettingsMenuEntry {
    constructor(overlay2) {
      this.overlay = overlay2;
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
      if (menu.querySelector(".tornmanager-menu-item")) return;
      const item = document.createElement("li");
      item.className = "link tornmanager-menu-item";
      const link = document.createElement("a");
      link.href = "#";
      link.innerHTML = '<span class="tornmanager-menu-icon"></span><span>TornManager</span>';
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
  const POLL_INTERVAL_MS = 3e3;
  const MAX_LENGTH = 300;
  const DIVIDER_GAP_MS = 15 * 60 * 1e3;
  const POS_KEY = "tm_chat_box_pos";
  const DRAG_THRESHOLD_PX$1 = 6;
  let zCounter = 99991;
  class ChatBox {
    constructor(room, client, { onMinimize }) {
      this.room = room;
      this.client = client;
      this.onMinimize = onMinimize;
      this.lastMessageId = 0;
      this.lastMessageAt = null;
      this.pollInterval = null;
      this.loaded = false;
      this.encKey = room.encrypted ? ChatCrypto.getKey(room.id) : null;
    }
    render() {
      this.element = document.createElement("div");
      this.element.className = "tm-cb";
      const header = this.createHeader();
      this.element.appendChild(header);
      this.list = document.createElement("div");
      this.list.className = "tm-cb-messages";
      this.skeleton = this.createSkeleton();
      this.list.appendChild(this.skeleton);
      this.element.appendChild(this.list);
      this.element.appendChild(this.createComposer());
      this.element.addEventListener("pointerdown", () => {
        this.element.style.zIndex = ++zCounter;
      });
      this.makeDraggable(header);
      this.applyPosition();
      this.poll();
      this.pollInterval = setInterval(() => this.poll(), POLL_INTERVAL_MS);
      return this.element;
    }
    applyPosition() {
      const saved = this.savedPositions()[this.room.id];
      if (saved && typeof saved.left === "number" && typeof saved.top === "number") {
        this.moveTo(saved.left, saved.top);
        return;
      }
      const stagger = document.querySelectorAll(".tm-cb").length;
      this.element.style.right = `${12 + stagger * 28}px`;
      this.element.style.bottom = `${100 + stagger * 24}px`;
    }
    // Drag by the header; taps on the header buttons pass through untouched.
    makeDraggable(header) {
      let start = null;
      let dragging = false;
      header.addEventListener("pointerdown", (e) => {
        if (e.target.closest(".tm-cb-action")) return;
        const rect = this.element.getBoundingClientRect();
        start = { x: e.clientX, y: e.clientY, left: rect.left, top: rect.top };
        dragging = false;
        header.setPointerCapture(e.pointerId);
      });
      header.addEventListener("pointermove", (e) => {
        if (!start) return;
        const dx = e.clientX - start.x;
        const dy = e.clientY - start.y;
        if (!dragging && Math.hypot(dx, dy) < DRAG_THRESHOLD_PX$1) return;
        dragging = true;
        this.moveTo(start.left + dx, start.top + dy);
      });
      const finish = () => {
        if (!start) return;
        if (dragging) this.savePosition();
        start = null;
      };
      header.addEventListener("pointerup", finish);
      header.addEventListener("pointercancel", () => {
        start = null;
      });
    }
    moveTo(left, top) {
      const rect = this.element.getBoundingClientRect();
      const width = rect.width || 330;
      const height = rect.height || 440;
      this.element.style.left = `${Math.min(Math.max(left, 4), window.innerWidth - width - 4)}px`;
      this.element.style.top = `${Math.min(Math.max(top, 4), window.innerHeight - height - 4)}px`;
      this.element.style.right = "auto";
      this.element.style.bottom = "auto";
    }
    clampPosition() {
      const rect = this.element.getBoundingClientRect();
      if (rect.left < 0 || rect.top < 0 || rect.right > window.innerWidth || rect.bottom > window.innerHeight) {
        this.moveTo(rect.left, rect.top);
      }
    }
    savePosition() {
      const positions = this.savedPositions();
      const rect = this.element.getBoundingClientRect();
      positions[this.room.id] = { left: Math.round(rect.left), top: Math.round(rect.top) };
      try {
        localStorage.setItem(POS_KEY, JSON.stringify(positions));
      } catch {
      }
    }
    savedPositions() {
      try {
        const raw = localStorage.getItem(POS_KEY);
        const positions = raw ? JSON.parse(raw) : {};
        return typeof positions === "object" && positions !== null ? positions : {};
      } catch {
        return {};
      }
    }
    destroy() {
      var _a;
      if (this.pollInterval) {
        clearInterval(this.pollInterval);
        this.pollInterval = null;
      }
      (_a = this.element) == null ? void 0 : _a.remove();
    }
    createHeader() {
      const header = document.createElement("div");
      header.className = "tm-cb-header";
      const title = document.createElement("div");
      title.className = "tm-cb-title";
      const name = document.createElement("span");
      name.className = "tm-cb-name";
      name.textContent = this.room.name;
      const count = document.createElement("span");
      count.className = "tm-cb-count";
      count.textContent = `· ${this.room.member_count}`;
      title.appendChild(name);
      title.appendChild(count);
      if (this.room.encrypted) {
        const lock = document.createElement("span");
        lock.className = "tm-cb-lock";
        lock.title = "End-to-end encrypted";
        lock.innerHTML = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';
        title.appendChild(lock);
      }
      header.appendChild(title);
      const actions = document.createElement("div");
      actions.className = "tm-cb-actions";
      if (this.room.host && this.room.invite_url) {
        const invite = document.createElement("button");
        invite.type = "button";
        invite.className = "tm-cb-action";
        invite.title = "Copy invite link";
        invite.innerHTML = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';
        invite.onclick = () => this.copyInvite();
        actions.appendChild(invite);
      }
      const minimize = document.createElement("button");
      minimize.type = "button";
      minimize.className = "tm-cb-action";
      minimize.title = "Minimize";
      minimize.textContent = "—";
      minimize.onclick = () => this.onMinimize(this.room.id);
      actions.appendChild(minimize);
      header.appendChild(actions);
      return header;
    }
    copyInvite() {
      if (this.room.encrypted) {
        if (!this.encKey) {
          this.appendSystem("Encryption key missing — rejoin via an invite link first.");
          return;
        }
        copyText(`${this.room.invite_url}~${this.encKey}`, "Invite link copied");
      } else {
        copyText(this.room.invite_url, "Invite link copied");
      }
    }
    createComposer() {
      const composer = document.createElement("div");
      composer.className = "tm-cb-composer";
      this.input = document.createElement("textarea");
      this.input.className = "tm-cb-input";
      this.input.placeholder = "Type your message...";
      this.input.rows = 1;
      this.input.maxLength = MAX_LENGTH;
      this.counter = document.createElement("span");
      this.counter.className = "tm-cb-counter";
      const send = document.createElement("button");
      send.type = "button";
      send.className = "tm-cb-send";
      send.title = "Send";
      send.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M2 21l21-9L2 3v7l15 2-15 2v7z"/></svg>';
      send.onclick = () => this.send();
      this.input.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault();
          this.send();
        }
      });
      this.input.addEventListener("input", () => {
        const remaining = MAX_LENGTH - this.input.value.length;
        this.counter.textContent = remaining <= 60 ? remaining : "";
      });
      composer.appendChild(this.input);
      composer.appendChild(this.counter);
      composer.appendChild(send);
      return composer;
    }
    async send() {
      const body = this.input.value.trim();
      if (!body) return;
      if (this.room.encrypted && !this.encKey) {
        this.appendSystem("Can't send — rejoin via the invite link to restore this room's key.");
        return;
      }
      this.input.value = "";
      this.counter.textContent = "";
      try {
        const payload = this.room.encrypted ? await ChatCrypto.encrypt(this.encKey, body) : body;
        await this.client.sendMessage(this.room.id, payload);
        this.poll();
      } catch (err) {
        this.appendSystem(err.message || "Could not send message.");
      }
    }
    createSkeleton() {
      const skeleton = document.createElement("div");
      skeleton.className = "tm-cb-skeleton";
      const widths = [[52, 150], [38, 210], [60, 96], [45, 180], [52, 128]];
      for (const [nameWidth, textWidth] of widths) {
        const row = document.createElement("div");
        row.className = "tm-cb-skeleton-row";
        row.innerHTML = `<span class="tm-cb-skel" style="width:${nameWidth}px"></span><span class="tm-cb-skel" style="width:${textWidth}px"></span>`;
        skeleton.appendChild(row);
      }
      return skeleton;
    }
    poll() {
      this.client.fetchMessages(this.room.id, this.lastMessageId).then((messages) => {
        var _a;
        if (!this.loaded) {
          this.loaded = true;
          (_a = this.skeleton) == null ? void 0 : _a.remove();
          this.skeleton = null;
        }
        this.appendMessages(messages);
      }).catch(() => {
      });
    }
    async appendMessages(messages) {
      if (!messages.length) return;
      for (const message of messages) {
        this.lastMessageId = Math.max(this.lastMessageId, message.id);
      }
      const prepared = [];
      for (const message of messages) {
        prepared.push({ message, ...await this.resolveBody(message) });
      }
      const nearBottom = this.list.scrollHeight - this.list.scrollTop - this.list.clientHeight < 60;
      for (const { message, body, locked } of prepared) {
        this.appendDividerIfNeeded(message.at);
        if (message.system) {
          this.appendSystem(message.body);
          continue;
        }
        const row = document.createElement("div");
        row.className = "tm-cb-row";
        const own = message.own ?? message.torn_id === this.client.me().torn_id;
        if (own) row.classList.add("tm-cb-row--own");
        let sender;
        if (message.torn_id) {
          sender = document.createElement("a");
          sender.href = `https://www.torn.com/profiles.php?XID=${message.torn_id}`;
          sender.target = "_blank";
          sender.rel = "noopener";
        } else {
          sender = document.createElement("span");
        }
        sender.className = "tm-cb-sender";
        sender.style.color = this.colorForName(message.name);
        sender.textContent = `${message.name}:`;
        const bodyEl = document.createElement("span");
        bodyEl.className = locked ? "tm-cb-body tm-cb-body--locked" : "tm-cb-body";
        bodyEl.textContent = body;
        row.appendChild(sender);
        row.appendChild(bodyEl);
        this.list.appendChild(row);
      }
      if (nearBottom) this.list.scrollTop = this.list.scrollHeight;
    }
    async resolveBody(message) {
      if (message.system || !this.room.encrypted) {
        return { body: message.body, locked: false };
      }
      if (!this.encKey) {
        return { body: "🔒 Encrypted — rejoin via the invite link to read.", locked: true };
      }
      try {
        return { body: await ChatCrypto.decrypt(this.encKey, message.body), locked: false };
      } catch {
        return { body: "🔒 Can't decrypt this message.", locked: true };
      }
    }
    appendDividerIfNeeded(at) {
      const timestamp = new Date(at).getTime();
      if (this.lastMessageAt && timestamp - this.lastMessageAt < DIVIDER_GAP_MS) {
        this.lastMessageAt = timestamp;
        return;
      }
      this.lastMessageAt = timestamp;
      const divider = document.createElement("div");
      divider.className = "tm-cb-divider";
      const date = new Date(at);
      const pad = (n) => String(n).padStart(2, "0");
      divider.textContent = `${pad(date.getHours())}:${pad(date.getMinutes())}`;
      this.list.appendChild(divider);
    }
    appendSystem(text) {
      const row = document.createElement("div");
      row.className = "tm-cb-system";
      row.textContent = text;
      this.list.appendChild(row);
      this.list.scrollTop = this.list.scrollHeight;
    }
    // Deterministic per-name color: hash the name to a hue, with fixed
    // saturation/lightness tuned to stay readable on the dark chat background.
    colorForName(name) {
      let hash = 0;
      for (let i = 0; i < name.length; i++) {
        hash = hash * 31 + name.charCodeAt(i) | 0;
      }
      const hue = Math.abs(hash) % 360;
      return `hsl(${hue}, 60%, 68%)`;
    }
  }
  const OPEN_KEY = "tm_chat_open";
  const SEEN_KEY = "tm_chat_seen";
  const FAB_POS_KEY = "tm_chat_fab_pos";
  const FAB_HIDDEN_KEY = "tm_chat_fab_hidden";
  const UNREAD_POLL_MS = 8e3;
  const DRAG_THRESHOLD_PX = 6;
  const TM_LOGO = '<svg width="34" height="34" viewBox="0 0 32 32"><rect width="32" height="32" rx="7" fill="#0070f3"/><text x="16" y="22" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="15" fill="#fff">TM</text></svg>';
  class ChatDock {
    constructor(auth2, client, logger2) {
      this.auth = auth2;
      this.client = client;
      this.logger = logger2;
      this.rooms = [];
      this.boxes = /* @__PURE__ */ new Map();
      this.menuItems = /* @__PURE__ */ new Map();
      this.unread = /* @__PURE__ */ new Set();
      this.menuOpen = false;
      this.unreadInterval = null;
    }
    init() {
      if (!this.auth.isAuthenticated()) return;
      Dom.ready("body", () => {
        this.fab = document.createElement("button");
        this.fab.type = "button";
        this.fab.className = "tm-chat-fab";
        this.fab.title = "TornManager chats — drag to move";
        this.fab.innerHTML = `${TM_LOGO}<span class="tm-chat-fab-dot"></span>`;
        this.fab.style.display = "none";
        this.menu = document.createElement("div");
        this.menu.className = "tm-chat-menu";
        this.boxesEl = document.createElement("div");
        this.boxesEl.className = "tm-chat-boxes";
        document.body.appendChild(this.fab);
        document.body.appendChild(this.menu);
        document.body.appendChild(this.boxesEl);
        this.makeFabDraggable();
        this.applyFabPos();
        window.addEventListener("resize", () => {
          this.applyFabPos();
          this.boxes.forEach((box) => box.clampPosition());
        });
        document.addEventListener("click", (e) => {
          if (this.menuOpen && !this.menu.contains(e.target) && !this.fab.contains(e.target)) {
            this.toggleMenu(false);
          }
        });
        this.handleInviteHash().then(() => this.refresh());
        this.unreadInterval = setInterval(() => this.pollUnread(), UNREAD_POLL_MS);
      });
    }
    toggleMenu(open) {
      this.menuOpen = open;
      this.menu.classList.toggle("tm-chat-menu--open", open);
      if (open) this.positionMenu();
    }
    // A tap toggles the menu; moving past the threshold drags the button instead.
    makeFabDraggable() {
      let start = null;
      let dragging = false;
      this.fab.addEventListener("pointerdown", (e) => {
        const rect = this.fab.getBoundingClientRect();
        start = { x: e.clientX, y: e.clientY, left: rect.left, top: rect.top };
        dragging = false;
        this.fab.setPointerCapture(e.pointerId);
      });
      this.fab.addEventListener("pointermove", (e) => {
        if (!start) return;
        const dx = e.clientX - start.x;
        const dy = e.clientY - start.y;
        if (!dragging && Math.hypot(dx, dy) < DRAG_THRESHOLD_PX) return;
        dragging = true;
        this.toggleMenu(false);
        this.moveFab(start.left + dx, start.top + dy);
      });
      const finish = () => {
        if (!start) return;
        if (dragging) {
          this.saveFabPos();
        } else {
          this.toggleMenu(!this.menuOpen);
        }
        start = null;
      };
      this.fab.addEventListener("pointerup", finish);
      this.fab.addEventListener("pointercancel", () => {
        start = null;
      });
    }
    moveFab(left, top) {
      const size = this.fab.offsetWidth || 34;
      const clampedLeft = Math.min(Math.max(left, 4), window.innerWidth - size - 4);
      const clampedTop = Math.min(Math.max(top, 4), window.innerHeight - size - 4);
      this.fab.style.left = `${clampedLeft}px`;
      this.fab.style.top = `${clampedTop}px`;
      this.fab.style.right = "auto";
      this.fab.style.bottom = "auto";
    }
    saveFabPos() {
      const rect = this.fab.getBoundingClientRect();
      try {
        localStorage.setItem(FAB_POS_KEY, JSON.stringify({ left: Math.round(rect.left), top: Math.round(rect.top) }));
      } catch {
      }
    }
    applyFabPos() {
      try {
        const raw = localStorage.getItem(FAB_POS_KEY);
        if (!raw) return;
        const pos = JSON.parse(raw);
        if (typeof (pos == null ? void 0 : pos.left) === "number" && typeof (pos == null ? void 0 : pos.top) === "number") {
          this.moveFab(pos.left, pos.top);
        }
      } catch {
      }
    }
    positionMenu() {
      const rect = this.fab.getBoundingClientRect();
      const right = Math.min(Math.max(window.innerWidth - rect.right, 8), window.innerWidth - 200);
      this.menu.style.right = `${right}px`;
      if (rect.top > 300) {
        this.menu.style.bottom = `${window.innerHeight - rect.top + 8}px`;
        this.menu.style.top = "auto";
      } else {
        this.menu.style.top = `${rect.bottom + 8}px`;
        this.menu.style.bottom = "auto";
      }
    }
    isFabHidden() {
      return localStorage.getItem(FAB_HIDDEN_KEY) === "1";
    }
    setFabVisible(visible) {
      try {
        localStorage.setItem(FAB_HIDDEN_KEY, visible ? "0" : "1");
      } catch {
      }
      if (!visible) this.toggleMenu(false);
      this.updateFabDisplay();
    }
    updateFabDisplay() {
      if (!this.fab) return;
      this.fab.style.display = this.rooms.length && !this.isFabHidden() ? "" : "none";
    }
    async handleInviteHash() {
      const match = window.location.hash.match(/tmchat=([A-Za-z0-9_-]+)(?:~([A-Za-z0-9_-]+))?/);
      if (!match) return;
      history.replaceState(null, "", window.location.pathname + window.location.search);
      const [, token, encKey] = match;
      try {
        const room = await this.client.joinByToken(token);
        if (encKey) ChatCrypto.setKey(room.id, encKey);
        showToast(`Joined "${room.name}"`);
        this.openRoom(room);
      } catch (err) {
        this.logger.log(err, "chat invite join");
        showToast(err.message || "Could not join the chat room");
      }
    }
    refresh() {
      return this.client.listRooms().then(({ rooms }) => {
        this.rooms = rooms;
        this.renderMenu();
        this.syncBoxes();
      }).catch((err) => this.logger.log(err, "chat rooms list"));
    }
    renderMenu() {
      if (!this.menu) return;
      this.menu.innerHTML = "";
      this.menuItems.clear();
      for (const room of this.rooms) {
        const item = document.createElement("button");
        item.type = "button";
        item.className = "tm-chat-menu-item";
        item.title = room.name;
        const label = document.createElement("span");
        label.className = "tm-chat-menu-item-label";
        label.textContent = room.name;
        const dot = document.createElement("span");
        dot.className = "tm-chat-menu-item-dot";
        item.appendChild(label);
        item.appendChild(dot);
        item.onclick = () => {
          this.toggleRoom(room.id);
          this.toggleMenu(false);
        };
        this.menuItems.set(room.id, item);
        this.menu.appendChild(item);
      }
      this.updateFabDisplay();
      this.updateUnreadUI();
    }
    syncBoxes() {
      const openIds = this.getOpenIds().filter((id) => this.rooms.some((room) => room.id === id));
      for (const [id, box] of this.boxes) {
        if (!openIds.includes(id)) {
          box.destroy();
          this.boxes.delete(id);
        }
      }
      for (const id of openIds) {
        if (!this.boxes.has(id)) this.mountBox(id);
      }
      this.updateUnreadUI();
    }
    mountBox(roomId) {
      const room = this.rooms.find((r) => r.id === roomId);
      if (!room) return;
      const box = new ChatBox(room, this.client, {
        onMinimize: (id) => this.markOpen(id, false)
      });
      this.boxes.set(roomId, box);
      this.boxesEl.appendChild(box.render());
      this.markSeen(roomId);
    }
    toggleRoom(roomId) {
      this.markOpen(roomId, !this.getOpenIds().includes(roomId));
    }
    // Instant open for a room object we already have (e.g. straight from create/join).
    openRoom(room) {
      const index = this.rooms.findIndex((r) => r.id === room.id);
      if (index === -1) this.rooms.push(room);
      else this.rooms[index] = room;
      this.renderMenu();
      this.markOpen(room.id, true);
    }
    openRoomById(roomId) {
      if (this.rooms.some((room) => room.id === roomId)) {
        this.markOpen(roomId, true);
      } else {
        this.refresh().then(() => this.markOpen(roomId, true));
      }
    }
    markOpen(roomId, open) {
      const ids = this.getOpenIds().filter((id) => id !== roomId);
      if (open) ids.push(roomId);
      this.saveOpenIds(ids);
      if (open) this.setUnread(roomId, false);
      this.syncBoxes();
    }
    pollUnread() {
      const openIds = this.getOpenIds();
      const seen = this.getSeen();
      for (const room of this.rooms) {
        if (openIds.includes(room.id)) {
          this.markSeen(room.id);
          continue;
        }
        this.client.fetchMessages(room.id, seen[room.id] || 0).then((messages) => {
          if (messages.length) this.setUnread(room.id, true);
        }).catch(() => {
        });
      }
    }
    setUnread(roomId, unread) {
      if (unread) {
        this.unread.add(roomId);
      } else {
        this.unread.delete(roomId);
        this.markSeen(roomId);
      }
      this.updateUnreadUI();
    }
    updateUnreadUI() {
      var _a;
      const openIds = this.getOpenIds();
      for (const [id, item] of this.menuItems) {
        item.classList.toggle("tm-chat-menu-item--unread", this.unread.has(id));
        item.classList.toggle("tm-chat-menu-item--open", openIds.includes(id));
      }
      (_a = this.fab) == null ? void 0 : _a.classList.toggle("tm-chat-fab--unread", this.unread.size > 0);
    }
    markSeen(roomId) {
      const box = this.boxes.get(roomId);
      const seen = this.getSeen();
      seen[roomId] = Math.max(seen[roomId] || 0, (box == null ? void 0 : box.lastMessageId) || 0);
      try {
        localStorage.setItem(SEEN_KEY, JSON.stringify(seen));
      } catch {
      }
    }
    getSeen() {
      try {
        const raw = localStorage.getItem(SEEN_KEY);
        const seen = raw ? JSON.parse(raw) : {};
        return typeof seen === "object" && seen !== null ? seen : {};
      } catch {
        return {};
      }
    }
    getOpenIds() {
      try {
        const raw = localStorage.getItem(OPEN_KEY);
        const ids = raw ? JSON.parse(raw) : [];
        return Array.isArray(ids) ? ids : [];
      } catch {
        return [];
      }
    }
    saveOpenIds(ids) {
      try {
        localStorage.setItem(OPEN_KEY, JSON.stringify(ids));
      } catch {
      }
    }
  }
  const logger = new Logger();
  const auth = new Auth();
  const api = new ApiClient(auth);
  const chatClient = new ChatClient(auth);
  const chatDock = new ChatDock(auth, chatClient, logger);
  chatDock.init();
  function fromAnotherUserscript(source) {
    if (!source) return false;
    const match = source.match(/userscript\.html\?name=([^&]+)/i);
    return !!match && !decodeURIComponent(match[1]).toLowerCase().includes("torn-manager");
  }
  window.addEventListener("error", (e) => {
    var _a, _b;
    const msg = ((_a = e.error) == null ? void 0 : _a.message) || e.message || "";
    if (msg.includes("ResizeObserver")) return;
    if (fromAnotherUserscript(e.filename) || fromAnotherUserscript((_b = e.error) == null ? void 0 : _b.stack)) return;
    const source = e.filename ? `${e.filename}:${e.lineno}` : "unknown source";
    logger.log(e.error || msg, `uncaught (${source})`);
  });
  window.addEventListener("unhandledrejection", (e) => {
    var _a;
    if (fromAnotherUserscript((_a = e.reason) == null ? void 0 : _a.stack)) return;
    logger.log(e.reason, "unhandled promise");
  });
  console.log(
    "%cTorn%cManager %cis running.",
    "font-size: 30px; font-weight: 600; color: #42a5f5;",
    "font-size: 30px; font-weight: 600; color: #fff;",
    "font-size: 30px;"
  );
  const overlay = new Overlay(auth, api, logger, chatDock);
  const sidebar = new Sidebar(overlay);
  sidebar.init();
  const settingsMenuEntry = new SettingsMenuEntry(overlay);
  settingsMenuEntry.init();

})();