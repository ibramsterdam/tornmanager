// ==UserScript==
// @name         Torn Manager Chats
// @namespace    tornmanager
// @version      0.4.2
// @author       Bram [2728237]
// @description  TornManager Chats userscript
// @license      All rights reserved
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%230070f3'/%3E%3Ctext x='32' y='43' text-anchor='middle' font-family='Arial,Helvetica,sans-serif' font-weight='900' font-size='30' fill='white'%3ETM%3C/text%3E%3C/svg%3E
// @downloadURL  https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-chats.user.js
// @updateURL    https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-chats.user.js
// @match        https://www.torn.com/*
// @connect      torn.com
// @connect      api.torn.com
// @connect      tornmanager.com
// @connect      raw.githubusercontent.com
// @connect      amazonaws.com
// @grant        GM.notification
// @grant        GM.xmlHttpRequest
// @grant        GM_addStyle
// @run-at       document-start
// @noframes
// ==/UserScript==

(t=>{if(typeof GM_addStyle=="function"){GM_addStyle(t);return}const e=document.createElement("style");e.textContent=t,document.head.append(e)})(` .tornmanager-icon{background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='17' fill='white'%3ETM%3C/text%3E%3C/svg%3E")!important;background-position:center!important;background-size:contain!important;background-repeat:no-repeat!important;cursor:pointer!important}.tornmanager-icon:before,.tornmanager-icon:after{content:none!important;display:none!important}.tornmanager-menu-item a{display:flex!important;align-items:center;gap:8px;background-image:none!important}.tornmanager-menu-icon{flex:none;width:16px;height:16px;border-radius:4px;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='15' fill='white'%3ETM%3C/text%3E%3C/svg%3E");background-size:contain;background-repeat:no-repeat;background-position:center}.tm-overlay-panel,.tm-mh-targets,.tm-tt-wrap,.tm-cb-messages,.tm-storage-value{scrollbar-width:thin;scrollbar-color:#3a3a3e transparent}.tm-overlay-panel::-webkit-scrollbar,.tm-mh-targets::-webkit-scrollbar,.tm-tt-wrap::-webkit-scrollbar,.tm-cb-messages::-webkit-scrollbar,.tm-storage-value::-webkit-scrollbar{width:8px;height:8px}.tm-overlay-panel::-webkit-scrollbar-thumb,.tm-mh-targets::-webkit-scrollbar-thumb,.tm-tt-wrap::-webkit-scrollbar-thumb,.tm-cb-messages::-webkit-scrollbar-thumb,.tm-storage-value::-webkit-scrollbar-thumb{background:#3a3a3e;border-radius:4px}.tm-overlay-panel::-webkit-scrollbar-track,.tm-mh-targets::-webkit-scrollbar-track,.tm-tt-wrap::-webkit-scrollbar-track,.tm-cb-messages::-webkit-scrollbar-track,.tm-storage-value::-webkit-scrollbar-track,.tm-overlay-panel::-webkit-scrollbar-corner,.tm-mh-targets::-webkit-scrollbar-corner,.tm-tt-wrap::-webkit-scrollbar-corner,.tm-cb-messages::-webkit-scrollbar-corner,.tm-storage-value::-webkit-scrollbar-corner{background:transparent}.tm-overlay-backdrop{position:fixed;top:0;right:0;bottom:0;left:0;z-index:999999;background:#0000;display:flex;align-items:center;justify-content:center;pointer-events:none;transition:background .3s ease}.tm-overlay-backdrop.tm-overlay--visible{background:#0009;pointer-events:auto}.tm-overlay-panel{position:relative;width:520px;max-width:90vw;max-height:80vh;-webkit-text-size-adjust:100%;text-size-adjust:100%;overflow-y:auto;background:#1c1c1e;border:1px solid #333;border-radius:12px;padding:40px 32px;box-shadow:0 24px 64px #00000080;opacity:0;transform:translateY(24px) scale(.96);transition:opacity .3s ease,transform .3s ease,width .3s ease;box-sizing:border-box}.tm-overlay-panel--war{width:660px}.tm-overlay-panel--chats{width:600px}.tm-overlay--visible .tm-overlay-panel{opacity:1;transform:translateY(0) scale(1)}.tm-overlay-close{position:absolute;top:12px;right:16px;background:none;border:none;color:#888;font-size:24px;cursor:pointer;line-height:1;padding:4px 8px;border-radius:4px;transition:color .15s ease,background .15s ease}.tm-overlay-close:hover{color:#fff;background:#ffffff1a}.tm-update-notice{display:flex;flex-wrap:wrap;align-items:center;justify-content:center;gap:8px;margin:-16px -12px 20px;padding:9px 14px;font-size:12.5px;color:#ffcc80;background:#fb8c001f;border:1px solid rgba(251,140,0,.35);border-radius:8px;text-align:center}.tm-update-link{font-weight:700;color:#fb8c00;text-decoration:none;white-space:nowrap}.tm-update-link:hover{text-decoration:underline}.tm-force-update .tm-cb,.tm-force-update .tm-chat-menu,.tm-force-update .tm-overlay-panel,.tm-force-update .tm-lightbox,.tm-force-update #tm_chat_launcher{filter:blur(6px) grayscale(.4)!important;pointer-events:none!important;-webkit-user-select:none!important;user-select:none!important}.tm-force-update-bar{position:fixed;top:14px;left:50%;transform:translate(-50%);z-index:2147483647;display:flex;align-items:center;gap:14px;max-width:min(92vw,580px);padding:12px 16px;color:#e8eaf0;background:#14161c;border:1px solid #0070f3;border-radius:10px;box-shadow:0 12px 40px #00000080;font:500 13px/1.45 system-ui,-apple-system,Segoe UI,sans-serif}.tm-force-update-bar span{flex:1}.tm-force-update-link{flex:none;padding:7px 14px;font-weight:700;white-space:nowrap;color:#fff;background:#0070f3;border-radius:7px;text-decoration:none}.tm-force-update-link:hover{background:#0061d5}.tm-overlay-title{margin:0;font-size:24px;font-weight:700;color:#fff;text-align:center}.tm-overlay-title--left{font-size:21px;text-align:left;padding-right:36px}.tm-tabs{display:flex;gap:2px;margin-top:14px;border-bottom:1px solid #2e2e30}.tm-tab{display:inline-flex;align-items:center;gap:7px;margin-bottom:-1px;padding:9px 14px 10px;font-size:13.5px;font-weight:600;color:#9a9aa2;background:none;border:none;border-bottom:2px solid transparent;cursor:pointer;transition:color .15s ease}.tm-tab:hover{color:#d6d6db}.tm-tab--active{color:#fff;border-bottom-color:#0070f3}.tm-tab--locked{color:#6a6a70}.tm-tab--locked:hover{color:#9a9aa2}.tm-tab-lock{display:inline-flex;opacity:.85}.tm-tab--icon{margin-left:auto;padding:9px 10px 10px}.tm-tab--icon svg{display:block}.tm-tab-content .tm-sub,.tm-tab-content .tm-war,.tm-tab-content .tm-mugging{margin-top:16px}.tm-mugging-title{margin:0 0 14px;font-size:18px;font-weight:700;color:#fff}.tm-mugging-connect{padding:22px;background:#161618;border:1px solid #2a2a2c;border-radius:12px;text-align:center}.tm-mugging-connect-sub{margin:0 auto 16px;max-width:46ch;font-size:12.5px;line-height:1.55;color:#9a9aa2}.tm-mugging-connect-sub strong{color:#c7c7cd}.tm-mugging-form{display:flex;flex-direction:column;gap:8px;margin-top:16px}.tm-mugging-input{width:100%;padding:11px 14px;font-size:13px;font-family:ui-monospace,Menlo,Consolas,monospace;text-align:center;color:#fff;background:#111;border:1px solid #333;border-radius:9px;outline:none;box-sizing:border-box;transition:border-color .15s ease}.tm-mugging-input:focus{border-color:#0070f3}.tm-mugging-save{width:100%;padding:11px;font-size:14px;font-weight:700;color:#fff;background:#0070f3;border:none;border-radius:9px;cursor:pointer;transition:background .15s ease}.tm-mugging-save:hover{background:#0061d5}.tm-mugging-save:disabled{background:#2a2a2c;color:#666;cursor:default}.tm-mugging-error{margin:0;min-height:15px;font-size:12.5px;color:#e53935}.tm-mug-controls{display:flex;align-items:flex-end;gap:10px;margin-bottom:14px}.tm-mug-field{display:flex;flex-direction:column;gap:5px;flex:1;min-width:0}.tm-mug-field-label{font-size:11.5px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:#8a8a92}.tm-mug-input{width:100%;padding:9px 11px;font-size:13px;color:#fff;background:#111;border:1px solid #333;border-radius:9px;outline:none;box-sizing:border-box;color-scheme:dark}.tm-mug-input:focus{border-color:#0070f3}.tm-mug-stepper{display:flex;align-items:center;gap:8px}.tm-mug-step{flex:none;display:inline-flex;align-items:center;justify-content:center;width:34px;height:36px;color:#fff;background:#1c1c1e;border:1px solid #333;border-radius:9px;cursor:pointer;transition:background .15s ease,border-color .15s ease}.tm-mug-step:hover:not(:disabled){background:#26262a;border-color:#3a3a3d}.tm-mug-step:disabled{opacity:.35;cursor:default}.tm-mug-step svg{width:16px;height:16px;stroke:currentColor;stroke-width:2.2;stroke-linecap:round}.tm-mug-step-value{flex:1;min-width:0;padding:8px 6px;text-align:center;font-size:14px;font-weight:700;color:#fff;font-variant-numeric:tabular-nums;background:#111;border:1px solid #2a2a2c;border-radius:9px}.tm-mug-fetch{flex:none;padding:10px 22px;font-size:14px;font-weight:700;color:#fff;background:#0070f3;border:none;border-radius:9px;cursor:pointer;transition:background .15s ease}.tm-mug-fetch:hover{background:#0061d5}.tm-mug-fetch:disabled{background:#2a2a2c;color:#666;cursor:default}.tm-mug-caption{margin:0 0 10px;font-size:12px;color:#8a8a92}.tm-mug-stats{display:grid;grid-template-columns:1fr 1fr;gap:10px}.tm-mug-stat{display:flex;flex-direction:column;gap:4px;padding:16px;background:#161618;border:1px solid #2a2a2c;border-radius:11px}.tm-mug-stat-value{font-size:22px;font-weight:700;color:#fff;font-variant-numeric:tabular-nums;letter-spacing:-.01em}.tm-mug-stat-label{font-size:11.5px;text-transform:uppercase;letter-spacing:.05em;color:#8a8a92}.tm-mug-viewlog{margin-top:6px;font-size:12px;font-weight:600;color:#4da3ff;text-decoration:none}.tm-mug-viewlog:hover{text-decoration:underline}.tm-mug-message{margin:0;padding:26px 16px;text-align:center;font-size:13px;color:#8a8a92;background:#161618;border:1px solid #2a2a2c;border-radius:11px}.tm-mug-usage{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-top:16px;padding-top:14px;border-top:1px solid #232325;font-size:12px;color:#8a8a92}.tm-mug-remove{flex:none;padding:6px 14px;font-size:12px;color:#e05650;background:none;border:1px solid #333;border-radius:8px;cursor:pointer;transition:background .15s ease,border-color .15s ease}.tm-mug-remove:hover{background:#e539351a;border-color:#e53935}.tm-mugcalc{margin-top:20px;padding-top:18px;border-top:1px solid #232325}.tm-mugcalc-heading{margin:0 0 4px;font-size:15px;font-weight:700;color:#fff}.tm-mugcalc-intro{margin:0 0 14px;font-size:12.5px;line-height:1.5;color:#8a8a92}.tm-mugcalc-inputs{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px}.tm-mugcalc-wide{grid-column:1 / -1}.tm-mugcalc-rate{margin:0 0 12px;font-size:13px;color:#c7c7cd}.tm-mugcalc-rate strong{color:#fff}.tm-mugcalc-hint{margin:0;font-size:12.5px;color:#8a8a92}.tm-mugcalc-table{width:100%;border-collapse:collapse;font-size:13px}.tm-mugcalc-table th{padding:8px 10px;text-align:right;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;color:#8a8a92;border-bottom:1px solid #2a2a2c}.tm-mugcalc-table th:first-child{text-align:left}.tm-mugcalc-table td{padding:10px;text-align:right;color:#fff;font-variant-numeric:tabular-nums;border-bottom:1px solid #202022}.tm-mugcalc-table td:first-child{text-align:left;color:#c7c7cd}.tm-mugcalc-table tbody tr:last-child td{border-bottom:none}.tm-mugcalc-note{margin:12px 0 0;font-size:11.5px;line-height:1.5;color:#7a7a80}.tm-mug-helper-toggle{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:11px;margin-bottom:16px;font-size:13px;font-weight:600;color:#c7c7cd;background:#161618;border:1px solid #2a2a2c;border-radius:10px;cursor:pointer;transition:background .15s ease,border-color .15s ease,color .15s ease}.tm-mug-helper-toggle svg{width:16px;height:16px}.tm-mug-helper-toggle:hover{background:#1c1c1e;border-color:#3a3a3d;color:#fff}.tm-mug-helper-toggle--on{color:#4da3ff;background:#0070f314;border-color:#0070f366}.tm-mh{position:fixed;z-index:99995;display:flex;flex-direction:column;width:300px;height:340px;background:#1c1c1e;border:1px solid #333;border-radius:12px;box-shadow:0 12px 40px #00000080;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif}.tm-mh-header{display:flex;align-items:center;justify-content:space-between;gap:8px;flex:none;padding:9px 8px 9px 14px;background:#161618;border-bottom:1px solid #2a2a2c;cursor:move;-webkit-user-select:none;user-select:none}.tm-mh-title{font-size:14px;font-weight:700;color:#fff}.tm-mh-action{display:inline-flex;align-items:center;justify-content:center;width:26px;height:26px;font-size:19px;line-height:1;color:#9a9aa2;background:none;border:none;border-radius:6px;cursor:pointer;transition:background .15s ease,color .15s ease}.tm-mh-action:hover{background:#26262a;color:#fff}.tm-mh-body{flex:1;display:flex;flex-direction:column;overflow:hidden}.tm-mh-nav{flex:none;display:flex;flex-wrap:wrap;gap:6px;padding:10px 12px;border-bottom:1px solid #232325}.tm-mh-nav-link{padding:5px 9px;font-size:11.5px;font-weight:600;color:#c7c7cd;background:#161618;border:1px solid #2a2a2c;border-radius:7px;text-decoration:none;white-space:nowrap;transition:background .15s ease,border-color .15s ease,color .15s ease}.tm-mh-nav-link:hover{background:#1f1f22;border-color:#3a3a3d;color:#fff}.tm-mh-nav-link--active{color:#4da3ff;background:#0070f31a;border-color:#0070f366}.tm-mh-content{flex:1;display:flex;flex-direction:column;overflow:hidden}.tm-mh-placeholder{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:16px;text-align:center;color:#8a8a92}.tm-mh-placeholder svg{width:30px;height:30px;color:#4a4a50;margin-bottom:10px}.tm-mh-placeholder-title{margin:0 0 4px;font-size:15px;font-weight:700;color:#c7c7cd}.tm-mh-placeholder-text{margin:0;max-width:32ch;font-size:12px;line-height:1.5}.tm-mh-bar{flex:none;padding:12px 12px 8px}.tm-mh-scan{width:100%;padding:9px;font-size:13px;font-weight:600;color:#fff;background:#0070f3;border:none;border-radius:9px;cursor:pointer;transition:background .15s ease}.tm-mh-scan:hover{background:#0061d5}.tm-mh-scan:disabled{background:#2a2a2c;color:#666;cursor:default}.tm-mh-buymug{flex:none;display:flex;flex-direction:column;gap:10px;padding:12px;border-bottom:1px solid #232325}.tm-mh-item{font-size:13px;font-weight:700;color:#fff}.tm-mh-field{display:flex;flex-direction:column;gap:5px}.tm-mh-field-label{font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;color:#8a8a92}.tm-mh-field-row{display:flex;gap:8px}.tm-mh-input{flex:1;min-width:0;padding:8px 10px;font-size:13px;color:#fff;background:#111;border:1px solid #333;border-radius:8px;outline:none;box-sizing:border-box}.tm-mh-input:focus{border-color:#0070f3}.tm-mh-fetch{flex:none;padding:8px 14px;font-size:12.5px;font-weight:600;color:#c7c7cd;background:#1c1c1e;border:1px solid #333;border-radius:8px;cursor:pointer;transition:background .15s ease,color .15s ease}.tm-mh-fetch:hover{background:#26262a;color:#fff}.tm-mh-fetch:disabled{opacity:.5;cursor:default}.tm-mh-targets{flex:1;overflow:auto;padding:0 12px 12px}.tm-mh-progress{height:4px;margin-bottom:8px;background:#2a2a2c;border-radius:3px;overflow:hidden}.tm-mh-progress-fill{width:0;height:100%;background:#0070f3;transition:width .25s ease}.tm-mh-progress-label,.tm-mh-summary{margin:0 0 8px;font-size:11.5px;color:#8a8a92}@keyframes tm-mh-pop{0%{opacity:0;transform:translateY(5px)}to{opacity:1;transform:none}}.tm-mh-note{margin:0 0 8px;font-size:11px;color:#7a7a80}.tm-mh-msg{margin:0;padding:14px 4px;text-align:center;font-size:12.5px;line-height:1.5;color:#8a8a92}.tm-mh-list{display:flex;flex-direction:column;gap:6px}.tm-mh-target{display:flex;align-items:center;justify-content:space-between;gap:8px;padding:8px 10px;background:#161618;border:1px solid #2a2a2c;border-radius:9px;animation:tm-mh-pop .2s ease}.tm-mh-target-info{display:flex;flex-direction:column;gap:2px;min-width:0}.tm-mh-target-remove{flex:none;display:inline-flex;align-items:center;justify-content:center;width:24px;height:24px;font-size:17px;line-height:1;color:#7a7a80;background:none;border:1px solid transparent;border-radius:6px;cursor:pointer;transition:background .15s ease,color .15s ease,border-color .15s ease}.tm-mh-target-remove:hover{color:#e05650;background:#e539351a;border-color:#e5393559}.tm-mh-target:hover{border-color:#3a3a3d}.tm-mh-seller-highlight{outline:2px solid #0070f3!important;outline-offset:-2px!important;background:#0070f326!important;border-radius:4px!important}@media(prefers-reduced-motion:reduce){.tm-mh-target{animation:none}.tm-mh-progress-fill{transition:none}}.tm-mh-target-name{font-size:13px;font-weight:600;color:#fff}.tm-mh-target-top{display:flex;align-items:baseline;justify-content:space-between;gap:8px}.tm-mh-target-profit{flex:none;font-size:13px;font-weight:700;color:#3fb950;font-variant-numeric:tabular-nums}.tm-mh-target-sub{font-size:11px;color:#8a8a92}.tm-mh-target-link{font-size:11.5px;color:#4da3ff;text-decoration:none}.tm-mh-target-link:hover{text-decoration:underline}.tm-mh-resize{position:absolute;right:0;bottom:0;width:16px;height:16px;cursor:nwse-resize}.tm-mh-resize:after{content:"";position:absolute;right:3px;bottom:3px;width:7px;height:7px;border-right:2px solid #555;border-bottom:2px solid #555}.tm-chats-settings{display:flex;flex-direction:column;gap:8px;margin-top:16px;padding-top:12px;border-top:1px solid #2a2a2c}.tm-chats-setting{display:flex;align-items:center;justify-content:space-between;gap:10px;font-size:12px;color:#888}.tm-prefs-fonts,.tm-chats-modes{display:flex;gap:4px}.tm-chats-mode{display:inline-flex;align-items:center;gap:4px;padding:6px 11px;font-size:12px;font-weight:600;color:#aaa;background:none;border:1px solid #3a3a3d;border-radius:6px;cursor:pointer;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-chats-mode:hover{color:#fff;border-color:#555}.tm-chats-mode--active{color:#fff;background:#0070f3;border-color:#0070f3}.tm-chats-beta{font-size:8.5px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:#ffcc80;background:#fb8c002e;border-radius:3px;padding:1px 4px}.tm-chats-mode--active .tm-chats-beta{color:#fff;background:#ffffff40}.tm-prefs-font{min-width:34px;padding:6px 10px;font-weight:600;color:#aaa;background:none;border:1px solid #3a3a3d;border-radius:6px;cursor:pointer;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-prefs-font:nth-child(1){font-size:11px}.tm-prefs-font:nth-child(2){font-size:13px}.tm-prefs-font:nth-child(3){font-size:15px}.tm-prefs-font:hover{color:#fff;border-color:#555}.tm-prefs-font--active{color:#fff;background:#0070f3;border-color:#0070f3}.tm-auth{display:flex;flex-direction:column;align-items:center;gap:16px}.tm-auth-banner{display:block;width:100%;max-width:480px;height:auto;border-radius:10px}.tm-auth-form{display:flex;flex-direction:column;gap:8px;width:100%;max-width:480px;margin-top:8px}.tm-auth-row{display:flex;gap:10px;align-items:stretch}.tm-auth-input{flex:1;min-width:0;padding:10px 14px;font-size:14px;font-family:monospace;color:#fff;background:#111;border:1px solid #333;border-radius:8px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.tm-auth-input:focus{border-color:#0070f3}.tm-auth-button{flex:none;padding:10px 22px;font-size:14px;font-weight:600;white-space:nowrap;color:#fff;background:#0070f3;border:none;border-radius:8px;cursor:pointer;transition:background .15s ease}.tm-auth-button:hover{background:#0061d5}.tm-auth-button:disabled{background:#333;cursor:not-allowed;color:#666}.tm-auth-error{margin:0;font-size:13px;color:#e53935;text-align:center;min-height:18px}.tm-auth-hint{margin:0;font-size:12px;line-height:1.5;color:#777;text-align:center}.tm-auth-hint strong{color:#aaa}.tm-auth-hint a{color:#0070f3;text-decoration:none}.tm-auth-hint a:hover{text-decoration:underline}.tm-tos{margin-top:4px;padding:12px 14px;text-align:left;background:#141416;border:1px solid #2a2a2c;border-radius:10px}.tm-tos-heading{margin:0 0 8px;font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:#8a8a90}.tm-tos-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:9px 14px}.tm-tos-item{display:flex;flex-direction:column;gap:2px;min-width:0}.tm-tos-label{font-size:9.5px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;color:#6a6a70}.tm-tos-value{font-size:12px;line-height:1.4;color:#c7c7cd}.tm-tos-agree{display:flex;align-items:flex-start;gap:9px;margin-top:12px;padding-top:11px;border-top:1px solid #2a2a2c;font-size:12px;line-height:1.45;color:#9a9aa2;cursor:pointer}.tm-tos-checkbox{flex:none;margin:1px 0 0;width:15px;height:15px;accent-color:#0070f3;cursor:pointer}.tm-tos-agree a{color:#4da3ff;text-decoration:none}.tm-tos-agree a:hover{text-decoration:underline}.tm-sub{margin-top:24px;padding:20px;background:#161618;border:1px solid #333;border-radius:10px}.tm-sub-title{margin:0 0 12px;font-size:15px;font-weight:600;color:#fff;text-align:center}.tm-sub-note{margin:0 0 14px;padding:8px 12px;font-size:12px;line-height:1.5;color:#9ab8dd;text-align:center;background:#0070f314;border:1px solid rgba(0,112,243,.3);border-radius:7px}.tm-sub-status{font-size:14px;font-weight:600;text-align:center}.tm-sub-status--active{color:#4caf50}.tm-sub-status--inactive{color:#888}.tm-sub-status--warn{color:#fb8c00}.tm-sub-status--error{color:#e53935}.tm-sub-countdown{margin:4px 0 0;font-size:22px;font-weight:700;font-variant-numeric:tabular-nums;color:#fff;text-align:center;letter-spacing:.5px}.tm-sub-refresh{display:block;margin:16px auto 0;padding:7px 16px;font-size:12px;font-weight:500;color:#aaa;background:none;border:1px solid #333;border-radius:6px;cursor:pointer;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-sub-refresh:hover{color:#fff;border-color:#555;background:#ffffff0d}.tm-sub-refresh:disabled{color:#555;cursor:not-allowed;border-color:#2a2a2a}.tm-sub-info{margin-top:16px;padding-top:12px;border-top:1px solid #2a2a2a;font-size:12px;line-height:1.5;color:#777;text-align:center}.tm-sub-info a{color:#0070f3;text-decoration:none}.tm-sub-info a:hover{text-decoration:underline}.tm-war{margin-top:16px;padding:20px;background:#161618;border:1px solid #333;border-radius:10px}.tm-war-head{margin-bottom:14px}.tm-war-head-row{display:flex;align-items:baseline;justify-content:space-between;gap:12px;margin-bottom:8px}.tm-war-head-left{display:flex;align-items:baseline;gap:6px;min-width:0;font-size:13px;color:#888}.tm-war-head-left--muted{color:#666}.tm-war-head-left--error{color:#e53935}.tm-war-head-vs{font-size:11px;font-style:italic;color:#666}.tm-war-head-enemy{font-size:14px;font-weight:700;color:#e53935;text-decoration:none;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-war-head-enemy:hover{color:#ff6659;text-decoration:underline}.tm-war-head-score{flex:none;font-size:15px;font-weight:700;font-variant-numeric:tabular-nums}.tm-war-score--up{color:#4caf50}.tm-war-score--down{color:#e53935}.tm-war-head-sep{font-weight:400;color:#555}.tm-war-head-target{font-size:12px;font-weight:400;color:#555}.tm-war-bar{height:3px;border-radius:2px;background:#2a2a2c;overflow:hidden}.tm-war-bar-fill{height:100%;border-radius:2px;background:#4caf50;transition:width .5s ease}.tm-war-bar-fill--losing{background:#e53935}.tm-tt-add{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin-bottom:12px}.tm-tt-add-input{flex:1;min-width:160px;padding:7px 11px;font-size:12.5px;color:#fff;background:#111;border:1px solid #333;border-radius:7px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.tm-tt-add-input:focus{border-color:#0070f3}.tm-tt-add-button{padding:7px 16px;font-size:12.5px;font-weight:600;color:#fff;background:#0070f3;border:none;border-radius:7px;cursor:pointer;white-space:nowrap;transition:background .15s ease}.tm-tt-add-button:hover{background:#0061d5}.tm-tt-add-error{width:100%;font-size:12px;color:#e53935}.tm-tt-add-error:empty{display:none}.tm-tt-wrap{border:1px solid #2a2a2c;border-radius:8px;overflow:auto;max-height:50vh}.tm-tt{width:100%;border-collapse:collapse;font-size:12.5px;text-align:left}.tm-tt th{position:sticky;top:0;z-index:1;padding:10px 12px;background:#1a1a1c;border-bottom:1px solid #2a2a2c;font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.5px;color:#888;text-align:left;white-space:nowrap}.tm-tt-sortable{cursor:pointer;-webkit-user-select:none;user-select:none}.tm-tt-sortable:hover{color:#fff}.tm-tt-arrow{display:inline-block;opacity:0;transition:transform .15s ease}.tm-tt-sort-active .tm-tt-arrow{opacity:1}.tm-tt-sort-asc .tm-tt-arrow{transform:rotate(180deg)}.tm-tt td{padding:11px 12px;border-bottom:1px solid #222;color:#ccc;white-space:nowrap}.tm-tt th:first-child,.tm-tt td:first-child{width:100%;padding-left:14px}.tm-tt tbody tr:last-child td{border-bottom:none}.tm-tt tbody tr{cursor:pointer}.tm-tt tbody tr:hover{background:#ffffff0a}.tm-tt tbody tr:hover .tm-tt-name{color:#ff6659}.tm-tt-name{color:#fff;font-weight:600;text-decoration:none}.tm-tt-name:hover{color:#e53935;text-decoration:underline}.tm-tt-name--unknown{color:#666;font-weight:500}.tm-tt-nodata{color:#444}.tm-loc--torn{color:#666}.tm-loc--plane{color:#42a5f5;font-weight:500}.tm-tt-empty{margin:4px 0 0;font-size:13px;color:#666;text-align:center}.tm-tt-remove-cell{width:26px;text-align:right}.tm-tt-remove{padding:2px 6px;font-size:15px;line-height:1;color:#555;background:none;border:none;border-radius:4px;cursor:pointer;opacity:.25;transition:color .15s ease,background .15s ease,opacity .15s ease}.tm-tt tbody tr:hover .tm-tt-remove,.tm-tt-remove:focus-visible{opacity:1}.tm-tt-remove:hover{color:#e53935;background:#e539351a}.tm-status{display:inline-block;padding:2px 8px;border-radius:10px;font-size:11px;font-weight:600}.tm-status--okay{color:#4caf50;background:#4caf501f}.tm-status--hospital{color:#e53935;background:#e539351f}.tm-status--jail{color:#fb8c00;background:#fb8c001f}.tm-status--traveling{color:#42a5f5;background:#42a5f51f}.tm-status--abroad{color:#ab47bc;background:#ab47bc1f}.tm-status--unknown{color:#888;background:#ffffff0f}.tm-action{display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:500}.tm-action:before{content:"";width:6px;height:6px;border-radius:50%;background:currentColor}.tm-action--online{color:#4caf50}.tm-action--idle{color:#fb8c00}.tm-action--offline{color:#666}.tm-timer{font-weight:600;font-variant-numeric:tabular-nums}.tm-timer--hospital{color:#e53935}.tm-timer--travel{color:#42a5f5}.tm-timer--landing{color:#fb8c00}.tm-timer--soon{animation:tm-pulse 1s infinite}.tm-timer-sep{font-weight:400;color:#555}.tm-tt [data-timer-until]:hover,.tm-tt [data-travel-eta]:hover,.tm-tt [data-travel-fast-eta]:hover{text-decoration:underline dotted;text-underline-offset:3px}.tm-toast{position:fixed;bottom:32px;left:50%;z-index:1000000;padding:8px 16px;font-size:12.5px;font-weight:600;color:#fff;background:#2a2a2c;border:1px solid #444;border-radius:8px;box-shadow:0 8px 24px #0006;opacity:0;transform:translate(-50%,8px);transition:opacity .2s ease,transform .2s ease;pointer-events:none}.tm-toast--visible{opacity:1;transform:translate(-50%)}@media(max-width:600px){.tm-overlay-panel{max-width:96vw;max-height:88vh;padding:26px 16px 18px}.tm-tab{padding:9px 10px 10px;font-size:13px}.tm-chats-grid{grid-template-columns:1fr}}@keyframes tm-pulse{50%{opacity:.4}}.tm-tab-content .tm-chats{margin-top:16px}.tm-chats-form{display:flex;flex-wrap:wrap;align-items:center;gap:8px;margin-bottom:10px}.tm-chats-input{flex:1;min-width:180px;padding:8px 12px;font-size:13px;color:#fff;background:#111;border:1px solid #333;border-radius:7px;outline:none;transition:border-color .15s ease;box-sizing:border-box}.tm-chats-input:focus{border-color:#0070f3}.tm-chats-create{padding:8px 16px;font-size:12.5px;font-weight:600;color:#fff;background:#0070f3;border:none;border-radius:7px;cursor:pointer;white-space:nowrap;transition:background .15s ease}.tm-chats-create:hover{background:#0061d5}.tm-chats-error{width:100%;font-size:12px;color:#e53935}.tm-chats-error:empty{display:none}.tm-chats-list{display:flex;flex-direction:column;gap:8px}.tm-chats-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.tm-chats-section-head{display:flex;align-items:baseline;justify-content:space-between;flex-wrap:wrap;gap:3px 12px;margin:18px 0 8px;padding-bottom:5px;border-bottom:1px solid #2a2a2c}.tm-chats-section-head:first-child{margin-top:0}.tm-chats-section-label{font-size:12.5px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;color:#e6e6ea}.tm-chats-section-desc{display:inline-flex;align-items:center;gap:5px;font-size:11px;color:#6a6a70}.tm-chats-section-desc svg{flex:none;color:#5cb85c}.tm-chats-empty{display:flex;flex-direction:column;align-items:center;gap:6px;margin:8px 0;padding:26px 20px;background:#161618;border:1px solid #303032;border-radius:10px;text-align:center;color:#4a9df8}.tm-chats-empty-title{margin:6px 0 0;font-size:14.5px;font-weight:700;color:#fff}.tm-chats-empty-text{margin:0;max-width:44ch;font-size:12.5px;line-height:1.55;color:#9a9aa2}.tm-chats-room{display:grid;grid-template-columns:minmax(0,1fr) auto;grid-template-areas:"name name" "meta actions";align-items:end;column-gap:10px;row-gap:4px;padding:8px 12px;background:#161618;border:1px solid #2a2a2c;border-radius:8px;cursor:pointer;transition:background .15s ease,border-color .15s ease}.tm-chats-room:hover{background:#1c1c1f;border-color:#3a3a3d}.tm-chats-room:focus-visible{outline:2px solid #0070f3;outline-offset:-1px}.tm-chats-room-nameline{grid-area:name;display:flex;align-items:center;flex-wrap:wrap;gap:6px;min-width:0}.tm-chats-room-name{font-size:13px;font-weight:600;color:#fff;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-chats-room-chip{flex:none;padding:1px 7px;font-size:10px;font-weight:700;letter-spacing:.02em;text-transform:uppercase;border-radius:4px}.tm-chats-room-chip--anon{color:#d6b8ff;background:#a76cf729;border:1px solid rgba(167,108,247,.45)}.tm-chats-room-chip--locked{color:#f0a83c;background:#f0a83c26;border:1px solid rgba(240,168,60,.45)}.tm-chats-room-chip--host{color:#7fb3ff;background:#0070f329;border:1px solid rgba(0,112,243,.45)}.tm-chats-room-meta{grid-area:meta;font-size:11px;color:#777;white-space:nowrap}.tm-chats-room-actions{grid-area:actions;display:flex;align-items:center;justify-content:flex-end;gap:2px}.tm-chats-room-tag{font-size:11px;font-weight:600;color:#fff;background:#0070f3;border-radius:5px;padding:4px 10px}.tm-chats-icon-btn{display:inline-flex;align-items:center;justify-content:center;width:28px;height:28px;padding:0;color:#888;background:none;border:none;border-radius:6px;cursor:pointer;transition:color .15s ease,background .15s ease}.tm-chats-icon-btn:hover{color:#fff;background:#ffffff14}.tm-chats-icon-btn--danger:hover{color:#ff6659;background:#e539351f}.tm-chats-icon-btn--members{width:auto;gap:4px;padding:0 8px 0 7px;font-size:12px;font-weight:600}.tm-chats-icon-btn--muted{color:#4a4a4e;cursor:not-allowed}.tm-chats-icon-btn--muted:hover{color:#4a4a4e;background:none}.tm-chats-btn{padding:5px 12px;font-size:12px;font-weight:600;color:#aaa;background:none;border:1px solid #3a3a3d;border-radius:6px;cursor:pointer;white-space:nowrap;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-chats-btn:hover{color:#fff;border-color:#555}.tm-chats-btn:disabled{opacity:.5;cursor:default}.tm-chats-btn--danger{color:#e05650;border-color:#4a2b2b}.tm-chats-btn--danger:hover{color:#ff6659;border-color:#e53935;background:#e539351a}.tm-members-head{display:flex;align-items:center;gap:10px;margin-bottom:10px}.tm-members-back{display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;color:#9a9aa2;background:#161618;border:1px solid #2a2a2c;border-radius:7px;cursor:pointer;flex:none}.tm-members-back:hover{color:#fff;border-color:#3a3a3e}.tm-members-title{display:flex;flex-direction:column;min-width:0}.tm-members-title-name{font-size:14px;font-weight:700;color:#fff;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-members-title-sub{font-size:11px;color:#777}.tm-members-list{display:flex;flex-direction:column;gap:6px;font-size:13px;color:#888}.tm-members-empty{margin:0;padding:18px;text-align:center;font-size:12.5px;color:#888;background:#161618;border:1px solid #2a2a2c;border-radius:9px}.tm-members-row{display:flex;align-items:center;gap:10px;padding:8px 12px;background:#161618;border:1px solid #2a2a2c;border-radius:9px}.tm-members-row .tm-chats-btn{flex:none}.tm-members-avatar{flex:none;display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;font-size:13px;font-weight:700;color:#fff;border-radius:50%}.tm-members-info{display:flex;flex-direction:column;gap:1px;min-width:0;flex:1}.tm-members-nameline{display:flex;align-items:center;gap:6px;min-width:0}.tm-members-name{font-size:13px;font-weight:600;color:#fff;text-decoration:none;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}a.tm-members-name:hover{text-decoration:underline}.tm-members-id{font-size:11px;color:#666;font-variant-numeric:tabular-nums;white-space:nowrap}.tm-members-tag{flex:none;font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.04em;border-radius:4px;padding:2px 6px}.tm-members-tag--host{color:#7fb3ff;background:#0070f324}.tm-members-tag--suspended{color:#e05650;background:#e539351f}.tm-cb-suspended{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;height:100%;padding:24px;text-align:center;color:#e05650}.tm-cb-suspended p{margin:0;font-size:13px;color:#9a9aa2}.tm-cb-rules{display:flex;flex-direction:column;gap:9px;padding:12px 14px;margin:6px;background:#161618;border:1px solid #2a2a2c;border-radius:9px;font-size:11.5px}.tm-cb-rules-title{margin:0;font-size:12.5px;font-weight:700;color:#fff}.tm-cb-rules-list{margin:0;padding-left:16px;display:flex;flex-direction:column;gap:5px;list-style:disc;font-size:11.5px;line-height:1.45;color:#b9b9c0}.tm-cb-rules-accept{align-self:flex-start;padding:6px 16px;font-size:12px;font-weight:600;color:#fff;background:#0070f3;border:none;border-radius:6px;cursor:pointer;transition:background .15s ease}.tm-cb-rules-accept:hover{background:#0061d5}.tm-cb-rules-hint{margin:0;font-size:10.5px;line-height:1.5;color:#777}.tm-cb-rules-hint a{color:#7fb3ff;text-decoration:none}.tm-cb-rules-hint a:hover{text-decoration:underline}.tm-cb-locked{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:8px;height:100%;padding:24px;text-align:center;color:#f0a83c}.tm-cb-locked-title{margin:0;font-size:14px;font-weight:700;color:#f0a83c}.tm-cb-locked-text{margin:0;font-size:12.5px;line-height:1.5;color:#9a9aa2}.tm-chats-hint{margin:2px 0 0;font-size:11px;line-height:1.4;color:#666;text-align:center}.tm-launcher-logo{width:22px;height:22px;border-radius:5px;display:block}.tm-chat-fab{position:fixed;right:14px;bottom:110px;z-index:99990;display:flex;align-items:center;justify-content:center;width:34px;height:34px;padding:0;border:none;border-radius:8px;background:none;cursor:grab;touch-action:none;-webkit-user-select:none;user-select:none;opacity:.9;box-shadow:0 4px 14px #0006;transition:opacity .15s ease,transform .15s ease}.tm-chat-fab:hover{opacity:1;transform:scale(1.06)}.tm-chat-fab:active{cursor:grabbing}.tm-chat-fab svg{display:block;border-radius:8px;pointer-events:none}.tm-chat-fab-dot{display:none;position:absolute;top:-3px;right:-3px;width:10px;height:10px;border-radius:50%;background:#e53935;border:2px solid #1c1c1e}.tm-chat-fab--unread .tm-chat-fab-dot{display:block;animation:tm-pulse 1.5s infinite}.tm-chat-menu{position:fixed;right:16px;bottom:150px;z-index:2147483647;display:none;flex-direction:column;gap:2px;min-width:180px;max-width:240px;padding:6px;background:#1c1c1e;border:1px solid #333;border-radius:10px;box-shadow:0 12px 40px #00000080}.tm-chat-menu--open{display:flex}.tm-chat-menu-item{display:flex;align-items:center;gap:8px;padding:8px 10px;font-size:12.5px;font-weight:600;color:#bbb;text-align:left;background:none;border:none;border-radius:7px;cursor:pointer;transition:color .15s ease,background .15s ease}.tm-chat-menu-item:hover{color:#fff;background:#ffffff0f}.tm-chat-menu-item--open{color:#fff;background:#0070f326}.tm-chat-menu-item-label{flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-chat-menu-item-dot{display:none;width:7px;height:7px;border-radius:50%;background:#e53935;flex:none}.tm-chat-menu-item--unread .tm-chat-menu-item-dot{display:block}.tm-cb{position:fixed;right:12px;bottom:100px;z-index:99990;display:flex;flex-direction:column;width:330px;max-width:calc(100vw - 24px);height:440px;max-height:calc(100vh - 120px);background:#1c1c1e;border:1px solid #333;border-radius:10px;box-shadow:0 12px 40px #00000080;overflow:hidden;font-size:var(--tm-chat-font, 12.5px);animation:tm-cb-in .15s ease}@keyframes tm-cb-in{0%{opacity:0;transform:translateY(10px)}}.tm-cb-skeleton{display:flex;flex-direction:column;gap:10px;padding-top:2px}.tm-cb-skeleton-row{display:flex;align-items:center;gap:6px}.tm-cb-skel{height:10px;border-radius:4px;background:#26262a;animation:tm-skel 1.2s ease-in-out infinite}@keyframes tm-skel{50%{opacity:.45}}.tm-cb-header{display:flex;align-items:center;justify-content:space-between;gap:8px;padding:8px 10px 8px 14px;background:#161618;border-bottom:1px solid #2a2a2c;flex:none;cursor:grab;touch-action:none;-webkit-user-select:none;user-select:none}.tm-cb-header:active{cursor:grabbing}.tm-cb-action{cursor:pointer;touch-action:auto}.tm-cb-title{display:flex;align-items:baseline;gap:6px;min-width:0}.tm-cb-name{font-size:1.04em;font-weight:700;color:#fff;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.tm-cb-members{display:inline-flex;align-items:center;gap:4px;flex:none;padding:2px 8px;font-size:.8em;font-variant-numeric:tabular-nums;line-height:1;color:#8a8f9a;background:#ffffff0d;border:1px solid rgba(255,255,255,.08);border-radius:999px}.tm-cb-members--link{cursor:pointer;touch-action:auto;transition:color .12s ease,border-color .12s ease,background .12s ease}.tm-cb-members--link:hover{color:#4da3ff;background:#0070f31f;border-color:#0070f366}.tm-cb-lock{display:inline-flex;color:#4caf50;flex:none}.tm-cb-body--locked{color:#6a6a70;font-style:italic}.tm-cb-actions{display:flex;gap:2px;flex:none}.tm-cb-action{display:inline-flex;align-items:center;justify-content:center;width:24px;height:24px;padding:0;font-size:13px;line-height:1;color:#888;background:none;border:none;border-radius:5px;cursor:pointer;transition:color .15s ease,background .15s ease}.tm-cb-action:hover{color:#fff;background:#ffffff14}.tm-cb-retention{padding-bottom:6px;font-size:.8em;line-height:1.35;text-align:center;color:#6a6a70;border-bottom:1px solid #26262a}.tm-cb-messages{flex:1;overflow-y:auto;padding:10px 12px;display:flex;flex-direction:column;gap:5px}.tm-cb-row{line-height:1.45;word-break:break-word}.tm-cb-row--own{padding:1px 6px;margin:0 -6px;border-radius:5px;background:#0070f317}.tm-cb-sender{margin-right:5px;font-weight:700;color:#42a5f5;text-decoration:none}.tm-cb-sender--admin{color:#ff5449}a.tm-cb-sender:hover{text-decoration:underline}.tm-cb-body{color:#ddd}.tm-cb-divider{margin:6px 0 2px;font-size:.84em;color:#555;text-align:center;font-variant-numeric:tabular-nums}.tm-cb-system{font-size:.92em;color:#666;font-style:italic;text-align:center}.tm-cb-composer{display:flex;flex-direction:column;align-items:stretch;gap:8px;padding:8px 10px;background:#161618;border-top:1px solid #2a2a2c;flex:none}.tm-cb-composer-row{display:flex;align-items:flex-end;gap:6px}.tm-cb-pending{display:flex;align-items:center;gap:9px;padding:6px;background:#101216;border:1px solid #2b3040;border-radius:8px}.tm-cb-pending[hidden]{display:none}.tm-cb-pending-thumb{flex:none;width:40px;height:40px;object-fit:cover;border-radius:5px}.tm-cb-pending-label{flex:1;font-size:12px;color:#9fd0ff}.tm-cb-pending-remove{flex:none;width:24px;height:24px;padding:0;font-size:17px;line-height:1;color:#aaa;background:transparent;border:none;border-radius:5px;cursor:pointer}.tm-cb-pending-remove:hover{color:#fff;background:#ffffff14}.tm-cb-notice{margin:4px 6px;padding:6px 10px;font-size:.92em;text-align:center;color:#ffcc80;background:#fb8c001f;border:1px solid rgba(251,140,0,.3);border-radius:7px}.tm-cb-input{flex:1;height:34px;padding:8px 10px;font-size:1em;font-family:inherit;color:#fff;background:#111;border:1px solid #333;border-radius:7px;outline:none;resize:none;box-sizing:border-box;transition:border-color .15s ease}.tm-cb-input:focus{border-color:#0070f3}.tm-cb-counter{font-size:10.5px;color:#fb8c00;font-variant-numeric:tabular-nums;align-self:center}.tm-cb-counter:empty{display:none}.tm-cb-send{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;padding:0;color:#fff;background:#0070f3;border:none;border-radius:7px;cursor:pointer;flex:none;transition:background .15s ease}.tm-cb-send:hover{background:#0061d5}.tm-cb-attach{display:inline-flex;align-items:center;justify-content:center;width:34px;height:34px;padding:0;color:#bbb;background:#1d1d20;border:1px solid #333;border-radius:7px;cursor:pointer;flex:none;transition:color .15s ease,border-color .15s ease}.tm-cb-attach:hover{color:#fff;border-color:#0070f3}.tm-cb-attach:disabled{cursor:default;opacity:.6}.tm-cb-attach--busy{animation:tm-cb-pulse 1s ease-in-out infinite}@keyframes tm-cb-pulse{0%,to{opacity:.4}50%{opacity:.8}}.tm-cb-image-chip{display:inline-flex;align-items:center;gap:5px;margin-right:5px;padding:2px 8px;font:inherit;color:#9fd0ff;background:#0070f324;border:1px solid rgba(0,112,243,.4);border-radius:6px;cursor:pointer;vertical-align:baseline;transition:background .15s ease}.tm-cb-image-chip:hover{background:#0070f347}.tm-cb-caption{margin-left:4px}.tm-lightbox{position:fixed;top:0;right:0;bottom:0;left:0;display:flex;align-items:center;justify-content:center;padding:4vh 4vw;background:#0000;cursor:zoom-out;opacity:0;transition:opacity .2s ease,background .2s ease}.tm-lightbox--open{opacity:1;background:#000000d1}.tm-lightbox-img{max-width:100%;max-height:100%;border-radius:8px;box-shadow:0 20px 60px #0009;cursor:default;animation:tm-lightbox-pop .2s ease}@keyframes tm-lightbox-pop{0%{transform:scale(.85);opacity:0}to{transform:scale(1);opacity:1}}.tm-lightbox-spinner{width:34px;height:34px;border:3px solid rgba(255,255,255,.25);border-top-color:#fff;border-radius:50%;animation:tm-lightbox-spin .8s linear infinite}@keyframes tm-lightbox-spin{to{transform:rotate(360deg)}}.tm-lightbox-error{padding:14px 18px;color:#eee;background:#1d1d20;border:1px solid #333;border-radius:8px;font-size:13px}@media(prefers-reduced-motion:reduce){.tm-cb-attach--busy,.tm-lightbox,.tm-lightbox-img,.tm-lightbox-spinner{animation:none;transition:none}}.tm-cb-resize{position:absolute;right:0;bottom:0;width:18px;height:18px;z-index:2;cursor:nwse-resize;touch-action:none;background:linear-gradient(135deg,transparent 0 50%,#555 50% 60%,transparent 60% 72%,#555 72% 82%,transparent 82%);border-bottom-right-radius:10px}.tm-cb-resize:hover{background:linear-gradient(135deg,transparent 0 50%,#888 50% 60%,transparent 60% 72%,#888 72% 82%,transparent 82%)}.tm-settings-actions{display:flex;justify-content:center;gap:10px;margin-top:24px}.tm-settings-actions .tm-remove-key{margin:0}.tm-storage-toggle{color:#aaa}.tm-storage-toggle:hover{color:#fff;background:#ffffff0f;border-color:#555}.tm-storage{margin-top:16px;text-align:left}.tm-storage-head{margin-bottom:8px;font-size:11.5px;color:#777}.tm-storage-empty{font-size:12.5px;color:#888}.tm-storage-item{border:1px solid #2a2a2c;border-radius:8px;background:#161618;margin-bottom:6px}.tm-storage-summary{display:flex;align-items:center;gap:10px;padding:8px 12px;cursor:pointer;list-style:none}.tm-storage-summary::-webkit-details-marker{display:none}.tm-storage-key{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;color:#d6d6d9}.tm-storage-size{flex:none;font-size:11px;color:#777;font-variant-numeric:tabular-nums}.tm-storage-delete{flex:none;padding:3px 10px;font-size:11px;font-weight:600;color:#e05650;background:none;border:1px solid #3a2a2a;border-radius:6px;cursor:pointer;transition:background .15s ease,border-color .15s ease}.tm-storage-delete:hover{background:#e539351f;border-color:#e53935}.tm-storage-value{margin:0;padding:10px 12px;border-top:1px solid #2a2a2c;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;line-height:1.5;color:#9a9aa2;white-space:pre-wrap;word-break:break-all;max-height:260px;overflow-y:auto}.tm-suspended{display:flex;flex-direction:column;align-items:center;gap:10px;padding:48px 24px;text-align:center;color:#e05650}.tm-suspended-title{margin:0;font-size:17px;font-weight:700;color:#fff}.tm-suspended-text{margin:0;font-size:13px;line-height:1.6;color:#b9b9c0;max-width:380px}.tm-remove-key{display:block;margin:24px auto 0;padding:8px 20px;font-size:13px;font-weight:500;color:#e53935;background:none;border:1px solid #333;border-radius:8px;cursor:pointer;transition:background .15s ease,border-color .15s ease}.tm-remove-key:hover{background:#e539351a;border-color:#e53935}.tm-footer{display:flex;flex-direction:column;align-items:center;gap:8px;margin-top:32px;padding-top:16px;border-top:1px solid #333}.tm-footer-row{display:flex;align-items:center;justify-content:center;gap:8px}.tm-footer-link{font-size:12px;color:#888;text-decoration:none;transition:color .15s ease}.tm-footer-link:hover{color:#fff}.tm-footer-link--button{padding:0;background:none;border:none;cursor:pointer}.tm-footer-divider{font-size:12px;color:#555}.tm-footer-version{font-size:10.5px;color:#555;font-variant-numeric:tabular-nums}.tm-footer-copy-log,.tm-footer-clear-log{font-size:11px;padding:3px 10px;border-radius:4px;cursor:pointer;border:1px solid #333;background:none;transition:color .15s ease,border-color .15s ease,background .15s ease}.tm-footer-copy-log{color:#e53935}.tm-footer-copy-log:hover{color:#ff6659;border-color:#e53935;background:#e539351a}.tm-footer-clear-log{color:#666}.tm-footer-clear-log:hover{color:#aaa;border-color:#555;background:#ffffff0d} `);

(function () {
  'use strict';

  const STORAGE_KEY$3 = "tm_errors";
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
        localStorage.setItem(STORAGE_KEY$3, JSON.stringify(errors));
      } catch {
      }
    }
    getAll() {
      try {
        const raw = localStorage.getItem(STORAGE_KEY$3);
        return raw ? JSON.parse(raw) : [];
      } catch {
        return [];
      }
    }
    clear() {
      localStorage.removeItem(STORAGE_KEY$3);
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
  const Store = createStore("tm_");
  class ApiClient {
    constructor(auth) {
      this.auth = auth;
    }
    fetchCurrentWar() {
      const token = this.auth.getToken();
      if (!token) return Promise.reject(new Error("Not authenticated"));
      return post("/api/current_war", {}, { token });
    }
  }
  class ChatClient {
    constructor(auth) {
      this.auth = auth;
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
    roomMembers(roomId) {
      return this.post("/api/chat/room_members", { room_id: roomId }).then((data) => data.members);
    }
    suspend(roomId, tornId) {
      return this.post("/api/chat/suspend", { room_id: roomId, torn_id: tornId }).then(() => true);
    }
    unsuspend(roomId, tornId) {
      return this.post("/api/chat/unsuspend", { room_id: roomId, torn_id: tornId }).then(() => true);
    }
    fetchMessages(roomId, sinceId = 0) {
      return this.post("/api/chat/messages", { room_id: roomId, since_id: sinceId }).then((data) => data.messages);
    }
    sendMessage(roomId, body) {
      return this.post("/api/chat/send_message", { room_id: roomId, body }).then((data) => data.message);
    }
    sendImage(roomId, imageBase64, { body = "" } = {}) {
      return this.post("/api/chat/send_image", { room_id: roomId, body, image_base64: imageBase64 }).then(
        (data) => data.message
      );
    }
    fetchImage(roomId, messageId) {
      return this.post("/api/chat/image", { room_id: roomId, message_id: messageId }).then((data) => data.data);
    }
    post(path, params = {}) {
      const token = this.auth.getToken();
      if (!token) return Promise.reject(new Error("Not authenticated"));
      return post(path, params, { token });
    }
  }
  const chatBannerSvg = `<svg width="1000" height="400" viewBox="0 0 1000 400" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-labelledby="t d">
  <title id="t">TornManager Chat</title>
  <desc id="d">End-to-end encrypted chat rooms inside Torn City, now with image sharing.</desc>

  <defs>
    <linearGradient id="bgg" x1="0" y1="0" x2="1000" y2="400" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#0e1116"/>
      <stop offset="1" stop-color="#161c29"/>
    </linearGradient>
    <linearGradient id="accent" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="#0070f3"/>
      <stop offset="1" stop-color="#4da3ff"/>
    </linearGradient>
    <radialGradient id="lockGlow" cx="0.5" cy="0.5" r="0.5">
      <stop offset="0" stop-color="#0070f3" stop-opacity="0.9"/>
      <stop offset="1" stop-color="#0070f3" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="photo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2b4a7a"/>
      <stop offset="0.55" stop-color="#3d6fb0"/>
      <stop offset="1" stop-color="#7fb3e0"/>
    </linearGradient>
    <clipPath id="thumbclip"><rect x="0" y="0" width="130" height="94" rx="9"/></clipPath>
  </defs>

  <rect x="0.5" y="0.5" width="999" height="399" rx="20" fill="url(#bgg)" stroke="#232838"/>

  <!-- wordmark -->
  <text x="500" y="68" text-anchor="middle" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-weight="800" font-size="40" fill="url(#accent)">TornManager Chat</text>
  <text x="500" y="95" text-anchor="middle" font-family="ui-monospace, Menlo, Consolas, monospace" font-size="13.5" fill="#5b6580">end-to-end encrypted chat rooms, right inside Torn City</text>

  <!-- zone A: you, typing -->
  <circle cx="112" cy="170" r="16" fill="#4b5470"/>
  <path d="M 88 232 C 88 200 96 186 112 184 C 128 186 136 200 136 232 Z" fill="#4b5470"/>

  <rect x="60" y="250" width="214" height="44" rx="12" fill="#101216" stroke="#2b3040" stroke-width="1.5"/>
  <text x="78" y="277" font-family="ui-monospace, Menlo, Consolas, monospace" font-size="13" fill="#8a93b2">gg on that chain</text>
  <rect x="193" y="264" width="2.5" height="17" fill="#4da3ff">
    <animate attributeName="opacity" values="1;0;1" dur="1.2s" repeatCount="indefinite"/>
  </rect>
  <rect x="216" y="264" width="16" height="14" rx="2.5" fill="none" stroke="#8a93b2" stroke-width="1.5"/>
  <circle cx="220.5" cy="268.5" r="1.5" fill="#8a93b2"/>
  <path d="M 217 277 L 222 272 L 225 275 L 229 270 L 232 273" fill="none" stroke="#8a93b2" stroke-width="1.5" stroke-linejoin="round"/>
  <circle cx="256" cy="272" r="13" fill="url(#accent)"/>
  <path d="M 250 267 L 263 272 L 250 277 L 253.5 272 Z" fill="#ffffff" opacity="0.95"/>

  <!-- zone B: encrypted flow -->
  <path id="flowPath" d="M 276 268 C 330 252 356 232 392 214 C 440 190 496 204 540 210" fill="none" stroke="#2c3f5f" stroke-width="2" stroke-linecap="round" stroke-dasharray="1 9"/>
  <path d="M 276 268 C 330 252 356 232 392 214 C 440 190 496 204 540 210" fill="none" stroke="url(#accent)" stroke-width="2.5" stroke-linecap="round" stroke-dasharray="1 10">
    <animate attributeName="stroke-dashoffset" values="0;-22" dur="0.9s" repeatCount="indefinite"/>
  </path>

  <circle cx="392" cy="206" r="24" fill="url(#lockGlow)">
    <animate attributeName="opacity" values="0.55;0.15;0.55" dur="3.6s" repeatCount="indefinite"/>
  </circle>
  <path d="M 385 204 v-6 a7 7 0 0 1 14 0 v6" fill="none" stroke="#4da3ff" stroke-width="2.5"/>
  <rect x="379" y="204" width="26" height="20" rx="5" fill="#12233f" stroke="#4da3ff" stroke-width="2"/>
  <circle cx="392" cy="211" r="2" fill="#4da3ff"/>
  <rect x="391" y="212" width="2" height="5" fill="#4da3ff"/>
  <text x="392" y="242" text-anchor="middle" font-family="ui-monospace, Menlo, Consolas, monospace" font-size="10.5" fill="#565f89">AES-256-GCM</text>

  <!-- encrypted packets travelling into the room -->
  <g>
    <rect x="-8" y="-8" width="16" height="16" rx="4" fill="#152744" stroke="#4da3ff" stroke-width="1.3"/>
    <rect x="-4.5" y="-1.5" width="9" height="6" rx="1.5" fill="none" stroke="#7dbaff" stroke-width="1.1"/>
    <path d="M -2.5 -1.5 v-2 a2.5 2.5 0 0 1 5 0 v2" fill="none" stroke="#7dbaff" stroke-width="1.1"/>
    <animateMotion dur="3.6s" repeatCount="indefinite"><mpath href="#flowPath"/></animateMotion>
    <animate attributeName="opacity" values="0;1;1;1;0" keyTimes="0;0.12;0.5;0.88;1" dur="3.6s" repeatCount="indefinite"/>
  </g>
  <g>
    <rect x="-6" y="-6" width="12" height="12" rx="3" fill="#152744" stroke="#4da3ff" stroke-width="1.2" opacity="0.85"/>
    <animateMotion dur="3.6s" begin="1.8s" repeatCount="indefinite"><mpath href="#flowPath"/></animateMotion>
    <animate attributeName="opacity" values="0;0.85;0.85;0.85;0" keyTimes="0;0.12;0.5;0.88;1" dur="3.6s" begin="1.8s" repeatCount="indefinite"/>
  </g>

  <!-- zone C: the room -->
  <rect x="548" y="124" width="396" height="214" rx="14" fill="#17181c" stroke="#2b2f3a" stroke-width="1.5"/>

  <text x="570" y="154" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="15" font-weight="700" fill="#e8eaf0">Hawaii squad</text>
  <path d="M 678 148 v-2.5 a3.5 3.5 0 0 1 7 0 v2.5" fill="none" stroke="#7aa2f7" stroke-width="1.5"/>
  <rect x="676" y="148" width="11" height="8" rx="2" fill="none" stroke="#7aa2f7" stroke-width="1.5"/>
  <text x="696" y="154" font-family="ui-monospace, Menlo, Consolas, monospace" font-size="12" fill="#6b7280">&#183; 6</text>
  <circle cx="924" cy="149" r="4" fill="#34d399">
    <animate attributeName="opacity" values="1;0.35;1" dur="1.8s" repeatCount="indefinite"/>
  </circle>
  <line x1="560" y1="166" x2="932" y2="166" stroke="#24262e" stroke-width="1"/>

  <text x="570" y="188" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" font-weight="700" fill="#4da3ff">Bram:</text>
  <text x="612" y="188" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" fill="#ccd1dd">Landing in 2 minutes</text>

  <text x="570" y="212" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" font-weight="700" fill="#7ee787">Sato:</text>
  <text x="606" y="212" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" fill="#ccd1dd">Landing in 1 min, I'll</text>
  <text x="606" y="228" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" fill="#ccd1dd">hit Rook, grab Cade &amp; Nyx?</text>

  <text x="570" y="252" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" font-weight="700" fill="#c792ea">Ren:</text>
  <text x="600" y="252" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" fill="#ccd1dd">Sure! also landing in 1 min</text>

  <text x="570" y="278" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" font-weight="700" fill="#4da3ff">Bram:</text>
  <text x="612" y="278" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="13" fill="#ccd1dd">Let's do this!</text>
  <g>
    <rect x="702" y="266" width="92" height="22" rx="6" fill="#0070f3" fill-opacity="0.16" stroke="#0070f3" stroke-opacity="0.5"/>
    <rect x="710" y="272" width="13" height="11" rx="2" fill="none" stroke="#9fd0ff" stroke-width="1.3"/>
    <circle cx="713.5" cy="275.5" r="1.2" fill="#9fd0ff"/>
    <path d="M 711 283 L 715 279 L 718 281.5 L 723 277" fill="none" stroke="#9fd0ff" stroke-width="1.3" stroke-linejoin="round"/>
    <text x="730" y="281" font-family="system-ui, -apple-system, 'Segoe UI', sans-serif" font-size="12" fill="#9fd0ff">image</text>
    <animate attributeName="opacity" values="0.7;1;0.7" dur="1.8s" repeatCount="indefinite"/>
  </g>

  <rect x="562" y="306" width="372" height="26" rx="8" fill="#101216" stroke="#262b36"/>
  <text x="574" y="323" font-family="ui-monospace, Menlo, Consolas, monospace" font-size="11.5" fill="#565f89">Type a message&#8230;</text>
  <rect x="898" y="313" width="13" height="11" rx="2" fill="none" stroke="#6b7280" stroke-width="1.3"/>
  <path d="M 899 324 L 903 320 L 906 322.5 L 911 318" fill="none" stroke="#6b7280" stroke-width="1.3" stroke-linejoin="round"/>
  <circle cx="924" cy="319" r="9" fill="url(#accent)"/>
  <path d="M 920 315.5 L 929 319 L 920 322.5 L 922.5 319 Z" fill="#ffffff" opacity="0.95"/>

  <!-- the image, opened -->
  <path d="M 748 265 C 765 258 782 251 798 245" fill="none" stroke="#4da3ff" stroke-width="1.5" stroke-dasharray="1 6" opacity="0.7">
    <animate attributeName="stroke-dashoffset" values="0;-14" dur="0.9s" repeatCount="indefinite"/>
  </path>
  <g transform="translate(788,152)">
    <g>
      <animateTransform attributeName="transform" type="scale" values="1;1.03;1" dur="3.6s" repeatCount="indefinite"/>
      <rect x="4" y="6" width="130" height="94" rx="9" fill="#000000" opacity="0.35"/>
      <rect x="0" y="0" width="130" height="94" rx="9" fill="#f6f5f1" stroke="#3b4a66" stroke-width="1.5"/>
      <g clip-path="url(#thumbclip)">
        <!-- shiba, swinging -->
        <path d="M 12 41 L 19 21 L 30 42 Z" fill="#c48f50"/>
        <path d="M 33 42 L 45 23 L 51 42 Z" fill="#c48f50"/>
        <ellipse cx="31" cy="54" rx="21" ry="19" fill="#d29c5d"/>
        <ellipse cx="31" cy="61" rx="15" ry="12" fill="#eccb99"/>
        <ellipse cx="24" cy="51" rx="2.1" ry="2.7" fill="#3a2a1a"/>
        <ellipse cx="38" cy="51" rx="2.1" ry="2.7" fill="#3a2a1a"/>
        <ellipse cx="31" cy="59" rx="2.7" ry="2" fill="#2a1e12"/>
        <ellipse cx="46" cy="78" rx="6" ry="5" fill="#eccb99"/>
        <!-- bat -->
        <line x1="47" y1="78" x2="88" y2="46" stroke="#9a6a34" stroke-width="7" stroke-linecap="round"/>
        <line x1="47" y1="78" x2="86" y2="48" stroke="#bd8f57" stroke-width="2.4" stroke-linecap="round"/>
        <circle cx="88" cy="46" r="4.6" fill="#9a6a34"/>
        <!-- cheems, bonked -->
        <g transform="rotate(9 106 60)">
          <path d="M 90 51 L 95 38 L 101 52 Z" fill="#d3b44a"/>
          <path d="M 112 52 L 118 40 L 122 53 Z" fill="#d3b44a"/>
          <ellipse cx="106" cy="60" rx="19" ry="17" fill="#e7ca5f"/>
          <ellipse cx="102" cy="67" rx="13" ry="10" fill="#f3e7ae"/>
          <ellipse cx="100" cy="56" rx="1.9" ry="2.3" fill="#2a230f"/>
          <ellipse cx="112" cy="56" rx="1.9" ry="2.3" fill="#2a230f"/>
          <ellipse cx="100" cy="65" rx="3" ry="2.3" fill="#2a230f"/>
        </g>
        <!-- BONK -->
        <g fill="#3a3a3a" font-family="'Comic Sans MS', 'Chalkboard SE', system-ui, sans-serif" font-weight="800" font-size="14">
          <text x="55" y="64" transform="rotate(-30 55 64)">B</text>
          <text x="67" y="56" transform="rotate(-30 67 56)">O</text>
          <text x="79" y="48" transform="rotate(-30 79 48)">N</text>
          <text x="91" y="40" transform="rotate(-30 91 40)">K</text>
        </g>
      </g>
    </g>
  </g>

  <!-- sparkles on the new feature -->
  <path d="M 776 143 L 778 149 L 784 151 L 778 153 L 776 159 L 774 153 L 768 151 L 774 149 Z" fill="#4da3ff">
    <animate attributeName="opacity" values="0.2;1;0.2" dur="1.8s" repeatCount="indefinite"/>
  </path>
  <path d="M 912 146 L 913.4 150 L 917.4 151.4 L 913.4 152.8 L 912 156.8 L 910.6 152.8 L 906.6 151.4 L 910.6 150 Z" fill="#c792ea">
    <animate attributeName="opacity" values="1;0.2;1" dur="1.2s" repeatCount="indefinite"/>
  </path>
  <path d="M 902 240 L 903.4 244 L 907.4 245.4 L 903.4 246.8 L 902 250.8 L 900.6 246.8 L 896.6 245.4 L 900.6 244 Z" fill="#e0af68">
    <animate attributeName="opacity" values="0.3;1;0.3" dur="1.8s" begin="0.6s" repeatCount="indefinite"/>
  </path>

  <!-- caption -->
  <text x="500" y="384" text-anchor="middle" font-family="ui-monospace, Menlo, Consolas, monospace" font-size="12" fill="#565f89" opacity="0.85">create a room &#183; share the invite link &#183; chat &amp; send images &#183; all end-to-end encrypted</text>
</svg>
`;
  const PRIVACY_URL = "https://tornmanager.com/legal#userscript-privacy-policy";
  const TOS_URL = "https://tornmanager.com/legal#userscript-terms-of-service";
  const LINKS = `<a href="${PRIVACY_URL}" target="_blank" rel="noopener">Privacy Policy</a> and <a href="${TOS_URL}" target="_blank" rel="noopener">Terms of Service</a>`;
  const MAIN_KEY_DISCLOSURE = {
    storage: "Persistent until you remove your key",
    sharing: "Nobody (your data is private)",
    purpose: "Signing in and running chat, faction and war features",
    keyStorage: "Stored in the TornManager database, used only for automation",
    access: "Public access (minimum)",
    agreeHtml: `I agree to the ${LINKS}, including use of essential cookies and anonymous analytics.`
  };
  const MUG_KEY_DISCLOSURE = {
    storage: "Read live from Torn, nothing is stored on a server",
    sharing: "Nobody. The key never leaves your device",
    purpose: "Reading your attack mug logs, and checking the public status of sellers on Bazaar and Item Market pages to find mug targets (competitive advantage)",
    keyStorage: "Stored only in this browser; never sent to TornManager",
    access: "Full Access (required)",
    agreeHtml: `I agree to the ${LINKS}.`
  };
  const ITEMS = [
    ["Data Storage", "storage"],
    ["Data Sharing", "sharing"],
    ["Purpose of Use", "purpose"],
    ["Key Storage & Sharing", "keyStorage"],
    ["Key Access Level", "access"]
  ];
  class ApiDisclosure {
    constructor(info, onAgreeChange) {
      this.info = info;
      this.onAgreeChange = onAgreeChange;
    }
    render() {
      const wrap = document.createElement("div");
      wrap.className = "tm-tos";
      const heading = document.createElement("p");
      heading.className = "tm-tos-heading";
      heading.textContent = "How your key and data are handled";
      wrap.appendChild(heading);
      const grid = document.createElement("div");
      grid.className = "tm-tos-grid";
      for (const [label, field] of ITEMS) {
        const item = document.createElement("div");
        item.className = "tm-tos-item";
        const labelEl = document.createElement("span");
        labelEl.className = "tm-tos-label";
        labelEl.textContent = label;
        const valueEl = document.createElement("span");
        valueEl.className = "tm-tos-value";
        valueEl.textContent = this.info[field];
        item.appendChild(labelEl);
        item.appendChild(valueEl);
        grid.appendChild(item);
      }
      wrap.appendChild(grid);
      const agree = document.createElement("label");
      agree.className = "tm-tos-agree";
      this.checkbox = document.createElement("input");
      this.checkbox.type = "checkbox";
      this.checkbox.className = "tm-tos-checkbox";
      this.checkbox.addEventListener("change", () => {
        var _a;
        return (_a = this.onAgreeChange) == null ? void 0 : _a.call(this, this.checkbox.checked);
      });
      const text = document.createElement("span");
      text.innerHTML = this.info.agreeHtml;
      agree.appendChild(this.checkbox);
      agree.appendChild(text);
      wrap.appendChild(agree);
      return wrap;
    }
    isAgreed() {
      var _a;
      return !!((_a = this.checkbox) == null ? void 0 : _a.checked);
    }
  }
  const BANNER_URI = `data:image/svg+xml;utf8,${encodeURIComponent(chatBannerSvg)}`;
  class AuthScreen {
    constructor(auth) {
      this.auth = auth;
    }
    render(onSuccess) {
      const container = document.createElement("div");
      container.className = "tm-auth";
      const banner = document.createElement("img");
      banner.className = "tm-auth-banner";
      banner.src = BANNER_URI;
      banner.alt = "";
      const form = document.createElement("form");
      form.className = "tm-auth-form";
      const input = document.createElement("input");
      input.type = "text";
      input.className = "tm-auth-input";
      input.placeholder = "Add Public Torn API key";
      input.autocomplete = "off";
      input.spellcheck = false;
      const button = document.createElement("button");
      button.type = "submit";
      button.className = "tm-auth-button";
      button.textContent = "Sign in";
      button.disabled = true;
      const error = document.createElement("p");
      error.className = "tm-auth-error";
      const row = document.createElement("div");
      row.className = "tm-auth-row";
      row.appendChild(input);
      row.appendChild(button);
      form.appendChild(row);
      form.appendChild(error);
      const disclosure = new ApiDisclosure(MAIN_KEY_DISCLOSURE, (agreed) => {
        button.disabled = !agreed;
      });
      form.appendChild(disclosure.render());
      form.addEventListener("submit", async (e) => {
        e.preventDefault();
        if (!disclosure.isAgreed()) return;
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
      hint.innerHTML = 'A key with <strong>Public</strong> access is all this extension needs. <a href="https://www.torn.com/preferences.php#tab=api" target="_blank" rel="noopener">Create one here</a>.';
      container.appendChild(banner);
      container.appendChild(form);
      container.appendChild(hint);
      return container;
    }
  }
  class SubscriptionSection {
    constructor(auth, onUpdate) {
      this.auth = auth;
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
      note.textContent = "A subscription is an optional extra. It only unlocks additional features like the Ranked War tab. Chats and the rest of the extension are free for everyone.";
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
  const STORAGE_KEY$2 = "tm_targets";
  class Targets {
    getAll() {
      try {
        const raw = localStorage.getItem(STORAGE_KEY$2);
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
        localStorage.setItem(STORAGE_KEY$2, JSON.stringify(list));
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
      const location2 = this.locationFor(status);
      const cls = location2 === "Torn" ? "tm-loc tm-loc--torn" : location2 === "Plane" ? "tm-loc tm-loc--plane" : "tm-loc";
      return `<span class="${cls}">${this.escapeHtml(location2)}</span>`;
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
      let message2 = null;
      if (el.dataset.travelEta) {
        const eta = new Date(el.dataset.travelEta);
        const remaining = Math.floor((eta - Date.now()) / 1e3);
        if (remaining > 0) {
          message2 = `${label} will land in ${this.formatCountdown(remaining)} or at ${this.formatTct(eta)} TCT (estimate).`;
        }
      } else if (el.dataset.travelFastEta) {
        const fast = new Date(el.dataset.travelFastEta);
        const slow = new Date(el.dataset.travelSlowEta);
        const fastRemaining = Math.floor((fast - Date.now()) / 1e3);
        const slowRemaining = Math.floor((slow - Date.now()) / 1e3);
        if (slowRemaining > 0) {
          message2 = fastRemaining > 0 ? `${label} will land in ${this.formatCountdown(fastRemaining)} – ${this.formatCountdown(slowRemaining)}, between ${this.formatTct(fast)} and ${this.formatTct(slow)} TCT (estimate).` : `${label} will land within ${this.formatCountdown(slowRemaining)}, by ${this.formatTct(slow)} TCT (estimate).`;
        }
      } else if (el.dataset.timerUntil) {
        const until = new Date(el.dataset.timerUntil);
        const remaining = Math.floor((until - Date.now()) / 1e3);
        if (remaining > 0) {
          const place = ((_c = member == null ? void 0 : member.status) == null ? void 0 : _c.state) === "Jail" ? "jail" : "hospital";
          message2 = `${label} is out of ${place} in ${this.formatCountdown(remaining)}, at ${this.formatTct(until)} TCT.`;
        }
      }
      if (message2) copyText(message2);
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
    constructor(api) {
      this.api = api;
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
    async encryptBytes(keyB64, bytes) {
      const key = await this.importKey(keyB64);
      const iv = new Uint8Array(12);
      crypto.getRandomValues(iv);
      const ciphertext = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, bytes);
      const packed = new Uint8Array(iv.length + ciphertext.byteLength);
      packed.set(iv, 0);
      packed.set(new Uint8Array(ciphertext), iv.length);
      return packed;
    },
    async decryptBytes(keyB64, packed) {
      const key = await this.importKey(keyB64);
      const iv = packed.slice(0, 12);
      const ciphertext = packed.slice(12);
      const plaintext = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, ciphertext);
      return new Uint8Array(plaintext);
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
  const FONT_KEY = "tm_chat_font_px";
  const DEFAULT_FONT = 11;
  const FONT_SIZES = [
    { label: "S", px: 9.5 },
    { label: "M", px: 11 },
    { label: "L", px: 14.5 }
  ];
  const Preferences = {
    chatFontSize() {
      const value = parseFloat(localStorage.getItem(FONT_KEY));
      return value > 0 ? value : DEFAULT_FONT;
    },
    setChatFontSize(px) {
      try {
        localStorage.setItem(FONT_KEY, String(px));
      } catch {
      }
      this.applyChatFontSize();
    },
    // Exposed as a CSS variable the chat box reads, so a change reflows every
    // open box (and future ones) instantly.
    applyChatFontSize() {
      document.documentElement.style.setProperty("--tm-chat-font", `${this.chatFontSize()}px`);
    }
  };
  const INVITE_ICON = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';
  const LEAVE_ICON = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>';
  const MEMBERS_ICON = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>';
  const LOCK_ICON$1 = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';
  class ChatsSection {
    constructor(chatDock) {
      this.chatDock = chatDock;
      this.client = chatDock.client;
    }
    render() {
      this.section = document.createElement("div");
      this.section.className = "tm-chats";
      this.listEl = document.createElement("div");
      this.listEl.className = "tm-chats-list";
      this.section.appendChild(this.listEl);
      this.settingsEl = this.createSettings();
      this.section.appendChild(this.settingsEl);
      this.browseChrome = [this.settingsEl];
      this.refresh();
      return this.section;
    }
    createSettings() {
      const wrap = document.createElement("div");
      wrap.className = "tm-chats-settings";
      wrap.appendChild(this.createButtonControl());
      wrap.appendChild(this.createFontControl());
      const hint = document.createElement("p");
      hint.className = "tm-chats-hint";
      hint.textContent = "Share a room's invite link in any Torn chat. Clicking it joins automatically.";
      wrap.appendChild(hint);
      return wrap;
    }
    setBrowseChrome(visible) {
      for (const el of this.browseChrome || []) el.hidden = !visible;
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
      this.setBrowseChrome(true);
      this.client.listRooms().then(({ rooms, publicRooms }) => this.renderList(rooms, publicRooms)).catch((err) => {
        var _a;
        if (err.suspended) {
          (_a = this.chatDock.overlay) == null ? void 0 : _a.markSuspended(err.message);
          return;
        }
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
      if (publicRooms.length) {
        this.listEl.appendChild(this.sectionHead("Public rooms", "Anyone can join · messages deleted after 24h"));
        const grid = this.roomGrid();
        for (const room of publicRooms) {
          grid.appendChild(this.renderPublicRoom(room, joinedIds.has(room.id)));
        }
        this.listEl.appendChild(grid);
      }
      this.listEl.appendChild(
        this.sectionHead("Your rooms", `${LOCK_ICON$1}<span>End-to-end encrypted</span>`)
      );
      this.listEl.appendChild(this.createForm());
      if (!privateRooms.length) {
        const empty = document.createElement("div");
        empty.className = "tm-chats-empty";
        empty.innerHTML = '<svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2z"/></svg><p class="tm-chats-empty-title">Chat rooms beyond faction chat</p><p class="tm-chats-empty-text">Create a room with anyone in Torn: war squads, trade partners, friends. Share its invite link in any chat and clicking it joins instantly. Free for everyone.</p>';
        this.listEl.appendChild(empty);
      } else {
        const grid = this.roomGrid();
        for (const room of privateRooms) grid.appendChild(this.renderRoom(room));
        this.listEl.appendChild(grid);
      }
    }
    roomGrid() {
      const grid = document.createElement("div");
      grid.className = "tm-chats-grid";
      return grid;
    }
    sectionHead(label, descHtml) {
      const head = document.createElement("div");
      head.className = "tm-chats-section-head";
      const lbl = document.createElement("span");
      lbl.className = "tm-chats-section-label";
      lbl.textContent = label;
      head.appendChild(lbl);
      if (descHtml) {
        const desc = document.createElement("span");
        desc.className = "tm-chats-section-desc";
        desc.innerHTML = descHtml;
        head.appendChild(desc);
      }
      return head;
    }
    createButtonControl() {
      const row = document.createElement("div");
      row.className = "tm-chats-setting";
      const label = document.createElement("span");
      label.textContent = "Chat button";
      const options = document.createElement("div");
      options.className = "tm-chats-modes";
      const modes = [
        { value: "none", label: "None" },
        { value: "floating", label: "Floating" },
        { value: "integrated", label: "Integrated", beta: true }
      ];
      const current = this.chatDock.buttonMode();
      for (const mode of modes) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "tm-chats-mode";
        button.classList.toggle("tm-chats-mode--active", mode.value === current);
        button.innerHTML = mode.beta ? `${mode.label}<span class="tm-chats-beta">beta</span>` : mode.label;
        button.onclick = () => {
          this.chatDock.setButtonMode(mode.value);
          options.querySelectorAll(".tm-chats-mode").forEach((b) => b.classList.remove("tm-chats-mode--active"));
          button.classList.add("tm-chats-mode--active");
        };
        options.appendChild(button);
      }
      row.appendChild(label);
      row.appendChild(options);
      return row;
    }
    createFontControl() {
      const row = document.createElement("div");
      row.className = "tm-chats-setting";
      const label = document.createElement("span");
      label.textContent = "Chat text size";
      const options = document.createElement("div");
      options.className = "tm-prefs-fonts";
      const current = Preferences.chatFontSize();
      for (const size of FONT_SIZES) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "tm-prefs-font";
        button.textContent = size.label;
        button.classList.toggle("tm-prefs-font--active", size.px === current);
        button.onclick = () => {
          Preferences.setChatFontSize(size.px);
          options.querySelectorAll(".tm-prefs-font").forEach((b) => b.classList.remove("tm-prefs-font--active"));
          button.classList.add("tm-prefs-font--active");
        };
        options.appendChild(button);
      }
      row.appendChild(label);
      row.appendChild(options);
      return row;
    }
    renderPublicRoom(room, joined) {
      const members = `${room.member_count} member${room.member_count === 1 ? "" : "s"}`;
      const chip = room.anonymous ? { chip: "anonymous", chipClass: "tm-chats-room-chip--anon" } : {};
      const row = this.roomRow(room.name, members, chip);
      row.onclick = () => this.openPublic(room);
      if (!joined) {
        const tag = document.createElement("span");
        tag.className = "tm-chats-room-tag";
        tag.textContent = "Join";
        row.querySelector(".tm-chats-room-actions").appendChild(tag);
      }
      return row;
    }
    // The room's roster, shown over the list with a back button. Any member can
    // view it; only the host sees suspend/unsuspend controls.
    openMembers(room) {
      this.setBrowseChrome(false);
      this.listEl.innerHTML = "";
      const header = document.createElement("div");
      header.className = "tm-members-head";
      const back = document.createElement("button");
      back.type = "button";
      back.className = "tm-members-back";
      back.innerHTML = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>';
      back.setAttribute("aria-label", "Back");
      back.onclick = () => this.refresh();
      const title = document.createElement("div");
      title.className = "tm-members-title";
      const name = document.createElement("span");
      name.className = "tm-members-title-name";
      name.textContent = room.name;
      const sub = document.createElement("span");
      sub.className = "tm-members-title-sub";
      sub.textContent = "Members";
      title.appendChild(name);
      title.appendChild(sub);
      header.appendChild(back);
      header.appendChild(title);
      this.listEl.appendChild(header);
      const list = document.createElement("div");
      list.className = "tm-members-list";
      list.appendChild(this.membersMessage("Loading members…"));
      this.listEl.appendChild(list);
      this.client.roomMembers(room.id).then((members) => this.renderMembers(room, list, members)).catch((err) => {
        list.replaceChildren(this.membersMessage(err.message || "Could not load members."));
      });
    }
    membersMessage(text) {
      const el = document.createElement("p");
      el.className = "tm-members-empty";
      el.textContent = text;
      return el;
    }
    renderMembers(room, list, members) {
      list.innerHTML = "";
      if (!members.length) {
        list.appendChild(this.membersMessage("No members."));
        return;
      }
      const sorted = [...members].sort(
        (a, b) => a.name.localeCompare(b.name, void 0, { sensitivity: "base" })
      );
      for (const member of sorted) {
        const row = document.createElement("div");
        row.className = "tm-members-row";
        const avatar = document.createElement("span");
        avatar.className = "tm-members-avatar";
        avatar.style.background = this.colorForName(member.name);
        avatar.textContent = member.name.charAt(0).toUpperCase();
        row.appendChild(avatar);
        const info = document.createElement("div");
        info.className = "tm-members-info";
        const nameLine = document.createElement("div");
        nameLine.className = "tm-members-nameline";
        let nameEl;
        if (member.torn_id) {
          nameEl = document.createElement("a");
          nameEl.href = `https://www.torn.com/profiles.php?XID=${member.torn_id}`;
          nameEl.target = "_blank";
          nameEl.rel = "noopener";
        } else {
          nameEl = document.createElement("span");
        }
        nameEl.className = "tm-members-name";
        nameEl.textContent = member.name;
        nameLine.appendChild(nameEl);
        if (member.host) nameLine.appendChild(this.memberTag("host", "tm-members-tag--host"));
        if (member.suspended) nameLine.appendChild(this.memberTag("suspended", "tm-members-tag--suspended"));
        info.appendChild(nameLine);
        if (member.torn_id) {
          const idEl = document.createElement("span");
          idEl.className = "tm-members-id";
          idEl.textContent = `ID ${member.torn_id}`;
          info.appendChild(idEl);
        }
        row.appendChild(info);
        if (room.host && !member.host) {
          const action = document.createElement("button");
          action.type = "button";
          action.className = member.suspended ? "tm-chats-btn" : "tm-chats-btn tm-chats-btn--danger";
          action.textContent = member.suspended ? "Unsuspend" : "Suspend";
          action.onclick = () => {
            action.disabled = true;
            const call = member.suspended ? this.client.unsuspend(room.id, member.torn_id) : this.client.suspend(room.id, member.torn_id);
            call.then(() => this.openMembers(room)).catch((err) => {
              action.disabled = false;
              showToast(err.message || "Action failed");
            });
          };
          row.appendChild(action);
        }
        list.appendChild(row);
      }
    }
    memberTag(text, cls) {
      const tag = document.createElement("span");
      tag.className = `tm-members-tag ${cls}`;
      tag.textContent = text;
      return tag;
    }
    colorForName(name) {
      let hash = 0;
      for (let i = 0; i < name.length; i++) {
        hash = hash * 31 + name.charCodeAt(i) | 0;
      }
      return `hsl(${Math.abs(hash) % 360}, 55%, 45%)`;
    }
    // The shared key rides in the link but never leaves the browser otherwise.
    copyInvite(room) {
      if (!room.encrypted) {
        copyText(room.invite_url, "Invite link copied");
        return;
      }
      const key = ChatCrypto.getKey(room.id);
      if (!key) {
        showToast("Encryption key missing. Rejoin via an invite link first");
        return;
      }
      copyText(`${room.invite_url}~${key}`, "Invite link copied");
    }
    openPublic(room) {
      this.client.joinPublic(room.id).then((joined) => {
        this.chatDock.openRoom(joined);
        this.refresh();
      }).catch((err) => {
        this.error.textContent = err.message || "Could not open the room.";
      });
    }
    renderRoom(room) {
      const locked = room.encrypted && !ChatCrypto.getKey(room.id);
      const members = `${room.member_count} member${room.member_count === 1 ? "" : "s"}`;
      const row = room.host ? this.roomRow(room.name, "", { chip: "Host", chipClass: "tm-chats-room-chip--host" }) : this.roomRow(room.name, "");
      row.onclick = () => this.chatDock.openRoomById(room.id);
      if (locked) {
        const chip = document.createElement("span");
        chip.className = "tm-chats-room-chip tm-chats-room-chip--locked";
        chip.textContent = "Locked";
        chip.title = "This device doesn't have this room's key. Open its invite link here to unlock.";
        row.querySelector(".tm-chats-room-nameline").appendChild(chip);
      }
      const actions = row.querySelector(".tm-chats-room-actions");
      const membersBtn = this.iconButton(MEMBERS_ICON, members, () => this.openMembers(room), "tm-chats-icon-btn--members");
      const countEl = document.createElement("span");
      countEl.textContent = room.member_count;
      membersBtn.appendChild(countEl);
      actions.appendChild(membersBtn);
      if (room.host && room.invite_url && !locked) {
        actions.appendChild(
          this.iconButton(INVITE_ICON, "Copy invite link", () => this.copyInvite(room))
        );
      } else if (locked) {
        actions.appendChild(
          this.iconButton(
            INVITE_ICON,
            "Unlock this room on this device to copy its invite link",
            () => showToast("Open this room's invite link on this device to unlock it"),
            "tm-chats-icon-btn--muted"
          )
        );
      } else {
        actions.appendChild(
          this.iconButton(
            INVITE_ICON,
            "Ask the host for the invite link",
            () => showToast("Ask the host for the invite link"),
            "tm-chats-icon-btn--muted"
          )
        );
      }
      actions.appendChild(
        this.iconButton(LEAVE_ICON, "Leave room", () => {
          this.client.leaveRoom(room.id).then(() => {
            this.chatDock.refresh();
            this.refresh();
          });
        }, "tm-chats-icon-btn--danger")
      );
      return row;
    }
    // Click anywhere to open; small icon buttons handle secondary actions without
    // stealing the row's click. The name gets its own full-width row with meta +
    // icons below — viewport breakpoints are unreliable in Torn PDA's WebView.
    roomRow(name, meta, { chip, chipClass = "" } = {}) {
      const row = document.createElement("div");
      row.className = "tm-chats-room";
      row.setAttribute("role", "button");
      row.tabIndex = 0;
      const nameLine = document.createElement("div");
      nameLine.className = "tm-chats-room-nameline";
      const nameEl = document.createElement("span");
      nameEl.className = "tm-chats-room-name";
      nameEl.textContent = name;
      nameLine.appendChild(nameEl);
      if (chip) {
        const chipEl = document.createElement("span");
        chipEl.className = `tm-chats-room-chip ${chipClass}`.trim();
        chipEl.textContent = chip;
        nameLine.appendChild(chipEl);
      }
      const actions = document.createElement("div");
      actions.className = "tm-chats-room-actions";
      row.appendChild(nameLine);
      if (meta) {
        const metaEl = document.createElement("span");
        metaEl.className = "tm-chats-room-meta";
        metaEl.textContent = meta;
        row.appendChild(metaEl);
      }
      row.appendChild(actions);
      row.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          row.click();
        }
      });
      return row;
    }
    iconButton(icon, title, onClick, extraClass = "") {
      const button = document.createElement("button");
      button.type = "button";
      button.className = `tm-chats-icon-btn ${extraClass}`.trim();
      button.title = title;
      button.setAttribute("aria-label", title);
      button.innerHTML = icon;
      button.onclick = (e) => {
        e.stopPropagation();
        onClick();
      };
      return button;
    }
  }
  const STORAGE_KEY$1 = "tm_mug_key";
  const INCORRECT_KEY = 2;
  const OWNER_IN_FEDERAL_JAIL = 10;
  const DISABLED_BY_INACTIVITY = 13;
  const PAUSED_BY_OWNER = 18;
  const DEAD_KEY_CODES = /* @__PURE__ */ new Set([INCORRECT_KEY, OWNER_IN_FEDERAL_JAIL, DISABLED_BY_INACTIVITY, PAUSED_BY_OWNER]);
  const MugKey = {
    get() {
      try {
        return localStorage.getItem(STORAGE_KEY$1) || null;
      } catch {
        return null;
      }
    },
    set(key) {
      try {
        localStorage.setItem(STORAGE_KEY$1, key);
      } catch {
        return;
      }
    },
    clear() {
      try {
        localStorage.removeItem(STORAGE_KEY$1);
      } catch {
        return;
      }
    },
    invalidKeyError(err) {
      if (!DEAD_KEY_CODES.has(err == null ? void 0 : err.code)) return null;
      this.clear();
      return new Error(`Torn rejected the saved key (${err.message}). It was removed. Connect a new key on the Mugging tab.`);
    }
  };
  const BASE_V2 = "https://api.torn.com/v2";
  const BASE_V1 = "https://api.torn.com";
  const TornDirect = {
    keyInfo(key) {
      return this.get("/key/info", key);
    },
    get(path, key) {
      return this.request(`${BASE_V2}${path}`, key);
    },
    getV1(path, key) {
      return this.request(`${BASE_V1}${path}`, key);
    },
    request(url, key) {
      const separator = url.includes("?") ? "&" : "?";
      const fullUrl = `${url}${separator}key=${encodeURIComponent(key)}&comment=tmchats`;
      return new Promise((resolve, reject) => {
        GM.xmlHttpRequest({
          method: "GET",
          url: fullUrl,
          headers: { Accept: "application/json" },
          onload(response) {
            let data = null;
            try {
              data = JSON.parse(response.responseText);
            } catch {
              reject(new Error("Invalid response from Torn."));
              return;
            }
            if (data && data.error) {
              const err = new Error(data.error.error || "Torn API error.");
              err.code = data.error.code;
              reject(err);
              return;
            }
            resolve(data);
          },
          onerror() {
            reject(new Error("Network error contacting Torn."));
          }
        });
      });
    }
  };
  const LOGS_KEY = "tm_mug_logs";
  const CALLS_KEY = "tm_mug_api_calls";
  const MUG_LOG_TYPE = 8155;
  const PAGE_LIMIT = 100;
  const MAX_PAGES = 150;
  const PAGE_DELAY_MS = 350;
  const ATTACK_LOG_RE = /ID=([A-Za-z0-9]+)/;
  const EARLIEST_DATE = "2026-01-01";
  const MugLogs = {
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
      var _a, _b;
      const key = MugKey.get();
      if (!key) throw new Error("No Full Access key is connected.");
      const seen = /* @__PURE__ */ new Set();
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
        onProgress == null ? void 0 : onProgress(logs.length);
        if (oldest <= startTs) break;
        if (entries.length < PAGE_LIMIT) break;
        if (!((_b = (_a = data._metadata) == null ? void 0 : _a.links) == null ? void 0 : _b.prev)) break;
        to = oldest;
        await delay$1(PAGE_DELAY_MS);
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
        attackId: match ? match[1] : null
      };
    },
    stats(logs) {
      let energy = 0;
      let money2 = 0;
      let largest = null;
      for (const log of logs) {
        energy += log.energy;
        money2 += log.money;
        if (!largest || log.money > largest.money) largest = log;
      }
      return { mugs: logs.length, energy, money: money2, largest };
    }
  };
  function delay$1(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
  const CALC_KEY = "tm_mug_calc";
  const CARD_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="4" width="18" height="16" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/></svg>';
  class MuggingSection {
    constructor(api, mugHelper) {
      this.api = api;
      this.mugHelper = mugHelper;
    }
    render() {
      this.section = document.createElement("div");
      this.section.className = "tm-mugging";
      const title = document.createElement("h2");
      title.className = "tm-mugging-title";
      title.textContent = "Mugging";
      this.section.appendChild(title);
      this.body = document.createElement("div");
      this.section.appendChild(this.body);
      if (MugKey.get()) {
        this.renderDashboard();
      } else {
        this.renderKeyForm();
      }
      return this.section;
    }
    renderKeyForm() {
      this.body.innerHTML = "";
      const card = document.createElement("div");
      card.className = "tm-mugging-connect";
      const sub = document.createElement("p");
      sub.className = "tm-mugging-connect-sub";
      sub.innerHTML = "The Mugging tab reads your <strong>attack mug logs</strong>, which Torn only exposes to a Full Access key. It calls Torn directly and is stored only in this browser, never sent to TornManager.";
      card.appendChild(sub);
      this.input = document.createElement("input");
      this.input.type = "text";
      this.input.className = "tm-mugging-input";
      this.input.placeholder = "Full Access API key";
      this.input.autocomplete = "off";
      this.input.spellcheck = false;
      this.saveBtn = document.createElement("button");
      this.saveBtn.type = "submit";
      this.saveBtn.className = "tm-mugging-save";
      this.saveBtn.textContent = "Verify & save";
      this.saveBtn.disabled = true;
      this.error = document.createElement("p");
      this.error.className = "tm-mugging-error";
      this.disclosure = new ApiDisclosure(MUG_KEY_DISCLOSURE, (agreed) => {
        this.saveBtn.disabled = !agreed;
      });
      card.appendChild(this.disclosure.render());
      const form = document.createElement("form");
      form.className = "tm-mugging-form";
      form.appendChild(this.input);
      form.appendChild(this.saveBtn);
      form.appendChild(this.error);
      form.addEventListener("submit", (e) => {
        e.preventDefault();
        this.validateAndSave();
      });
      card.appendChild(form);
      this.body.appendChild(card);
    }
    validateAndSave() {
      if (!this.disclosure.isAgreed()) return;
      this.error.textContent = "";
      const key = this.input.value.trim();
      if (!key) {
        this.error.textContent = "Enter your Full Access API key.";
        return;
      }
      this.saveBtn.disabled = true;
      this.saveBtn.textContent = "Verifying…";
      TornDirect.keyInfo(key).then((data) => {
        var _a, _b;
        MugLogs.bumpApiCalls();
        const type = (_b = (_a = data == null ? void 0 : data.info) == null ? void 0 : _a.access) == null ? void 0 : _b.type;
        if (type !== "Full Access") {
          this.error.textContent = `This key is ${type || "not valid"}. A Full Access key is required.`;
          this.resetSaveButton();
          return;
        }
        MugKey.set(key);
        this.renderDashboard();
      }).catch((err) => {
        this.error.textContent = err.message || "Could not verify the key.";
        this.resetSaveButton();
      });
    }
    resetSaveButton() {
      this.saveBtn.disabled = false;
      this.saveBtn.textContent = "Verify & save";
    }
    renderDashboard() {
      this.body.innerHTML = "";
      this.helperBtn = document.createElement("button");
      this.helperBtn.type = "button";
      this.helperBtn.className = "tm-mug-helper-toggle";
      this.helperBtn.onclick = () => {
        var _a;
        (_a = this.mugHelper) == null ? void 0 : _a.toggle();
        this.updateHelperBtn();
      };
      this.body.appendChild(this.helperBtn);
      this.updateHelperBtn();
      const today = isoDate(/* @__PURE__ */ new Date());
      const defaultFrom = maxDate(isoDate(new Date(Date.now() - 30 * 864e5)), EARLIEST_DATE);
      const controls = document.createElement("div");
      controls.className = "tm-mug-controls";
      const from = this.dateField("From", defaultFrom, today);
      this.fromDate = from.input;
      controls.appendChild(from.field);
      const to = this.dateField("To", today, today);
      this.toDate = to.input;
      controls.appendChild(to.field);
      this.fetchBtn = document.createElement("button");
      this.fetchBtn.type = "button";
      this.fetchBtn.className = "tm-mug-fetch";
      this.fetchBtn.textContent = "Fetch";
      this.fetchBtn.onclick = () => this.runFetch();
      controls.appendChild(this.fetchBtn);
      this.body.appendChild(controls);
      this.results = document.createElement("div");
      this.results.className = "tm-mug-results";
      this.body.appendChild(this.results);
      this.renderCalculator();
      const usage = document.createElement("div");
      usage.className = "tm-mug-usage";
      this.usageText = document.createElement("span");
      usage.appendChild(this.usageText);
      const remove = document.createElement("button");
      remove.type = "button";
      remove.className = "tm-mug-remove";
      remove.textContent = "Remove key";
      remove.onclick = () => {
        MugKey.clear();
        MugLogs.clear();
        this.renderKeyForm();
      };
      usage.appendChild(remove);
      this.body.appendChild(usage);
      this.updateUsage();
      const stored = MugLogs.stored();
      if (stored && Array.isArray(stored.logs)) {
        this.renderStats(stored);
      } else {
        this.showMessage("Pick a date range and fetch your mug logs.");
      }
    }
    dateField(label, value, max) {
      const field = document.createElement("label");
      field.className = "tm-mug-field";
      const caption = document.createElement("span");
      caption.className = "tm-mug-field-label";
      caption.textContent = label;
      field.appendChild(caption);
      const input = document.createElement("input");
      input.type = "date";
      input.className = "tm-mug-input";
      input.min = EARLIEST_DATE;
      input.max = max;
      input.value = value;
      field.appendChild(input);
      return { field, input };
    }
    async runFetch() {
      const fromValue = this.fromDate.value;
      const toValue = this.toDate.value;
      if (!fromValue || !toValue) {
        this.showMessage("Pick a start and end date.");
        return;
      }
      if (fromValue > toValue) {
        this.showMessage("The start date must be on or before the end date.");
        return;
      }
      const startTs = Math.floor(Date.parse(`${fromValue}T00:00:00Z`) / 1e3);
      const nowTs = Math.floor(Date.now() / 1e3);
      const endTs = Math.min(Math.floor(Date.parse(`${toValue}T23:59:59Z`) / 1e3), nowTs);
      this.fetchBtn.disabled = true;
      this.fetchBtn.textContent = "Fetching…";
      this.showMessage("Fetching mug logs…");
      try {
        const logs = await MugLogs.fetch(startTs, endTs, (count) => {
          this.showMessage(`Fetching mug logs… ${formatNumber(count)} so far`);
          this.updateUsage();
        });
        const result = { startDate: fromValue, endDate: toValue, fetchedAt: Date.now(), logs };
        MugLogs.store(result);
        this.renderStats(result);
      } catch (err) {
        this.showMessage(err.message || "Could not fetch your mug logs.");
      } finally {
        this.fetchBtn.disabled = false;
        this.fetchBtn.textContent = "Fetch";
        this.updateUsage();
      }
    }
    renderStats(result) {
      const logs = Array.isArray(result.logs) ? result.logs : [];
      const stats = MugLogs.stats(logs);
      this.results.innerHTML = "";
      const caption = document.createElement("p");
      caption.className = "tm-mug-caption";
      caption.textContent = `${result.startDate} to ${result.endDate}`;
      this.results.appendChild(caption);
      if (!stats.mugs) {
        const empty = document.createElement("p");
        empty.className = "tm-mug-message";
        empty.textContent = "No mugs found in this range.";
        this.results.appendChild(empty);
        return;
      }
      const grid = document.createElement("div");
      grid.className = "tm-mug-stats";
      grid.appendChild(statCard("Mugs", formatNumber(stats.mugs)));
      grid.appendChild(statCard("Energy spent", formatNumber(stats.energy)));
      grid.appendChild(statCard("Money mugged", "$" + formatNumber(stats.money)));
      const largest = statCard("Largest mug", "$" + formatNumber(stats.largest.money));
      if (stats.largest.attackId) {
        const link2 = document.createElement("a");
        link2.className = "tm-mug-viewlog";
        link2.href = `https://www.torn.com/page.php?sid=attackLog&ID=${stats.largest.attackId}`;
        link2.target = "_blank";
        link2.rel = "noopener";
        link2.textContent = "View attack log";
        largest.appendChild(link2);
      }
      grid.appendChild(largest);
      this.results.appendChild(grid);
    }
    showMessage(text) {
      this.results.innerHTML = "";
      const msg = document.createElement("p");
      msg.className = "tm-mug-message";
      msg.textContent = text;
      this.results.appendChild(msg);
    }
    updateUsage() {
      this.usageText.textContent = `API calls used on this page: ${formatNumber(MugLogs.apiCalls())}`;
    }
    updateHelperBtn() {
      var _a;
      if (!this.helperBtn) return;
      const open = (_a = this.mugHelper) == null ? void 0 : _a.isOpen();
      this.helperBtn.innerHTML = `${CARD_ICON}<span>${open ? "Close mug helper" : "Open mug helper"}</span>`;
      this.helperBtn.classList.toggle("tm-mug-helper-toggle--on", !!open);
    }
    renderCalculator() {
      const wrap = document.createElement("div");
      wrap.className = "tm-mugcalc";
      const heading = document.createElement("h3");
      heading.className = "tm-mugcalc-heading";
      heading.textContent = "Mug calculator";
      wrap.appendChild(heading);
      const intro = document.createElement("p");
      intro.className = "tm-mugcalc-intro";
      intro.textContent = "Set your loot bonuses and a target amount to see how much cash a victim must be holding.";
      wrap.appendChild(intro);
      const saved = this.loadCalc();
      const inputs = document.createElement("div");
      inputs.className = "tm-mugcalc-inputs";
      const update = () => this.updateCalc();
      this.meritsStepper = stepper("Masterful Looting merits", clamp(Math.floor(Number(saved.merits)) || 0, 0, 10), {
        next: (v) => Math.min(10, v + 1),
        prev: (v) => Math.max(0, v - 1),
        isMin: (v) => v <= 0,
        isMax: (v) => v >= 10,
        format: (v) => String(v),
        onChange: update
      });
      this.plunderStepper = stepper("Plunder weapon bonus", snapPlunder(saved.plunder), {
        next: (v) => v === 0 ? 20 : Math.min(49, v + 1),
        prev: (v) => v <= 20 ? 0 : v - 1,
        isMin: (v) => v <= 0,
        isMax: (v) => v >= 49,
        format: (v) => `${v}%`,
        onChange: update
      });
      this.targetInput = calcField("Mug amount you want", "text", saved.target, {
        placeholder: "e.g. 10m",
        inputMode: "decimal"
      });
      this.targetInput.field.classList.add("tm-mugcalc-wide");
      this.targetInput.input.addEventListener("input", update);
      inputs.appendChild(this.meritsStepper.field);
      inputs.appendChild(this.plunderStepper.field);
      inputs.appendChild(this.targetInput.field);
      wrap.appendChild(inputs);
      this.calcOutput = document.createElement("div");
      this.calcOutput.className = "tm-mugcalc-output";
      wrap.appendChild(this.calcOutput);
      this.body.appendChild(wrap);
      this.updateCalc();
    }
    updateCalc() {
      const merits = this.meritsStepper.value;
      const plunder = this.plunderStepper.value;
      const target = parseMoney$1(this.targetInput.input.value);
      this.saveCalc({ merits, plunder, target: this.targetInput.input.value.trim() });
      const modifier = 1 + (merits * 5 + plunder) / 100;
      const minRate = 0.05 * modifier;
      const maxRate = 0.1 * modifier;
      this.calcOutput.innerHTML = "";
      const rate = document.createElement("p");
      rate.className = "tm-mugcalc-rate";
      rate.innerHTML = `Your mug rate: <strong>${(minRate * 100).toFixed(2)}% to ${(maxRate * 100).toFixed(2)}%</strong> of a victim's cash on hand.`;
      this.calcOutput.appendChild(rate);
      if (!Number.isFinite(target) || target <= 0) {
        const hint = document.createElement("p");
        hint.className = "tm-mugcalc-hint";
        hint.textContent = "Enter a mug amount to see how much the target must be holding.";
        this.calcOutput.appendChild(hint);
        return;
      }
      const caption = document.createElement("p");
      caption.className = "tm-mug-caption";
      caption.textContent = `Cash the target must hold to mug ${money(target)}`;
      this.calcOutput.appendChild(caption);
      const rows = [
        { label: "Normal target", typical: target / minRate, best: target / maxRate },
        { label: "7* Clothing Store target", typical: target / minRate * 4, best: target / maxRate * 4 }
      ];
      const table = document.createElement("table");
      table.className = "tm-mugcalc-table";
      table.innerHTML = "<thead><tr><th>Target</th><th>Typical roll</th><th>Best roll</th></tr></thead>";
      const tbody = document.createElement("tbody");
      for (const row of rows) {
        const tr = document.createElement("tr");
        tr.innerHTML = `<td>${row.label}</td><td>${money(row.typical)}</td><td>${money(row.best)}</td>`;
        tbody.appendChild(tr);
      }
      table.appendChild(tbody);
      this.calcOutput.appendChild(table);
      const note = document.createElement("p");
      note.className = "tm-mugcalc-note";
      note.textContent = "Torn favours the low end of the range, so the typical column is what you will usually need. A best roll near the top of your range is rare. A 7* Clothing Store cuts your mug by 75%.";
      this.calcOutput.appendChild(note);
    }
    loadCalc() {
      const defaults = { merits: 0, plunder: 0, target: "10m" };
      try {
        const raw = localStorage.getItem(CALC_KEY);
        return raw ? { ...defaults, ...JSON.parse(raw) } : defaults;
      } catch {
        return defaults;
      }
    }
    saveCalc(state) {
      try {
        localStorage.setItem(CALC_KEY, JSON.stringify(state));
      } catch {
        return;
      }
    }
    destroy() {
    }
  }
  const MINUS_ICON = '<svg viewBox="0 0 24 24" fill="none"><line x1="5" y1="12" x2="19" y2="12"/></svg>';
  const PLUS_ICON = '<svg viewBox="0 0 24 24" fill="none"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>';
  function stepper(label, initial, opts) {
    let value = initial;
    const field = document.createElement("div");
    field.className = "tm-mug-field";
    const caption = document.createElement("span");
    caption.className = "tm-mug-field-label";
    caption.textContent = label;
    field.appendChild(caption);
    const row = document.createElement("div");
    row.className = "tm-mug-stepper";
    const minus = document.createElement("button");
    minus.type = "button";
    minus.className = "tm-mug-step";
    minus.innerHTML = MINUS_ICON;
    minus.setAttribute("aria-label", `Decrease ${label}`);
    const display = document.createElement("span");
    display.className = "tm-mug-step-value";
    const plus = document.createElement("button");
    plus.type = "button";
    plus.className = "tm-mug-step";
    plus.innerHTML = PLUS_ICON;
    plus.setAttribute("aria-label", `Increase ${label}`);
    const paint = () => {
      display.textContent = opts.format(value);
      minus.disabled = opts.isMin(value);
      plus.disabled = opts.isMax(value);
    };
    minus.onclick = () => {
      value = opts.prev(value);
      paint();
      opts.onChange();
    };
    plus.onclick = () => {
      value = opts.next(value);
      paint();
      opts.onChange();
    };
    row.appendChild(minus);
    row.appendChild(display);
    row.appendChild(plus);
    field.appendChild(row);
    paint();
    return {
      field,
      get value() {
        return value;
      }
    };
  }
  function snapPlunder(raw) {
    const n = Math.floor(Number(raw)) || 0;
    if (n <= 0) return 0;
    if (n < 20) return 20;
    return Math.min(49, n);
  }
  function calcField(label, type, value, attrs) {
    const field = document.createElement("label");
    field.className = "tm-mug-field";
    const caption = document.createElement("span");
    caption.className = "tm-mug-field-label";
    caption.textContent = label;
    field.appendChild(caption);
    const input = document.createElement("input");
    input.type = type;
    input.className = "tm-mug-input";
    input.value = value;
    if (attrs) Object.assign(input, attrs);
    field.appendChild(input);
    return { field, input };
  }
  function parseMoney$1(str) {
    const s = String(str || "").trim().toLowerCase().replace(/[$,\s]/g, "");
    const match = /^([0-9]*\.?[0-9]+)([kmb])?$/.exec(s);
    if (!match) return NaN;
    let n = parseFloat(match[1]);
    if (match[2] === "k") n *= 1e3;
    else if (match[2] === "m") n *= 1e6;
    else if (match[2] === "b") n *= 1e9;
    return n;
  }
  function money(n) {
    if (!Number.isFinite(n) || n <= 0) return "$0";
    if (n >= 1e9) return "$" + trimZeros(n / 1e9) + "b";
    if (n >= 1e6) return "$" + trimZeros(n / 1e6) + "m";
    if (n >= 1e3) return "$" + trimZeros(n / 1e3) + "k";
    return "$" + Math.round(n).toLocaleString("en-US");
  }
  function trimZeros(x) {
    return x.toFixed(2).replace(/\.?0+$/, "");
  }
  function clamp(n, lo, hi) {
    return Math.min(hi, Math.max(lo, n));
  }
  function statCard(label, value) {
    const card = document.createElement("div");
    card.className = "tm-mug-stat";
    const val = document.createElement("span");
    val.className = "tm-mug-stat-value";
    val.textContent = value;
    card.appendChild(val);
    const lbl = document.createElement("span");
    lbl.className = "tm-mug-stat-label";
    lbl.textContent = label;
    card.appendChild(lbl);
    return card;
  }
  function formatNumber(n) {
    return n.toLocaleString("en-US");
  }
  function isoDate(date) {
    return date.toISOString().slice(0, 10);
  }
  function maxDate(a, b) {
    return a > b ? a : b;
  }
  class StorageViewer {
    render() {
      this.element = document.createElement("div");
      this.element.className = "tm-storage";
      this.renderList();
      return this.element;
    }
    keys() {
      const keys = [];
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        if (key && key.startsWith("tm_")) keys.push(key);
      }
      return keys.sort();
    }
    renderList() {
      this.element.innerHTML = "";
      const keys = this.keys();
      let total = 0;
      const head = document.createElement("div");
      head.className = "tm-storage-head";
      this.element.appendChild(head);
      if (!keys.length) {
        const empty = document.createElement("p");
        empty.className = "tm-storage-empty";
        empty.textContent = "No stored data.";
        this.element.appendChild(empty);
        head.textContent = "0 keys";
        return;
      }
      for (const key of keys) {
        const value = localStorage.getItem(key) || "";
        total += key.length + value.length;
        const item = document.createElement("details");
        item.className = "tm-storage-item";
        const summary = document.createElement("summary");
        summary.className = "tm-storage-summary";
        const name = document.createElement("code");
        name.className = "tm-storage-key";
        name.textContent = key;
        const size = document.createElement("span");
        size.className = "tm-storage-size";
        size.textContent = formatSize(value.length);
        const del = document.createElement("button");
        del.type = "button";
        del.className = "tm-storage-delete";
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
        pre.className = "tm-storage-value";
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
  const CURRENT = "0.4.2";
  const MANIFEST_URL = "https://raw.githubusercontent.com/ibramsterdam/tornmanager/main/userscripts/tm-chats/package.json";
  const DOWNLOAD_URL = "https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-chats.user.js";
  const CACHE_KEY$1 = "tm_version_check";
  const CACHE_TTL_MS$1 = 10 * 60 * 1e3;
  function isNewer(a, b) {
    const x = String(a).split(".").map(Number);
    const y = String(b).split(".").map(Number);
    for (let i = 0; i < Math.max(x.length, y.length); i++) {
      const diff = (x[i] || 0) - (y[i] || 0);
      if (diff !== 0) return diff > 0;
    }
    return false;
  }
  function cachedManifest() {
    try {
      const raw = localStorage.getItem(CACHE_KEY$1);
      if (!raw) return null;
      const { manifest, at } = JSON.parse(raw);
      if (!manifest || Date.now() - at > CACHE_TTL_MS$1) return null;
      return manifest;
    } catch {
      return null;
    }
  }
  function fetchManifest() {
    return new Promise((resolve) => {
      GM.xmlHttpRequest({
        method: "GET",
        url: `${MANIFEST_URL}?t=${Math.floor(Date.now() / CACHE_TTL_MS$1)}`,
        headers: { Accept: "application/json" },
        onload(response) {
          try {
            const parsed = JSON.parse(response.responseText);
            const manifest = { version: parsed.version, minSupportedVersion: parsed.minSupportedVersion || "0.0.0" };
            if (manifest.version) {
              localStorage.setItem(CACHE_KEY$1, JSON.stringify({ manifest, at: Date.now() }));
            }
            resolve(manifest.version ? manifest : null);
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
    // Resolves to { latest, outdated, forced }. `outdated` means a newer version
    // exists; `forced` means this build is below the minimum supported version
    // and should be hard-gated. Never rejects — a failed check reports neither.
    async status() {
      const manifest = cachedManifest() || await fetchManifest();
      if (!manifest || !manifest.version) {
        return { latest: null, outdated: false, forced: false };
      }
      return {
        latest: manifest.version,
        outdated: isNewer(manifest.version, CURRENT),
        forced: isNewer(manifest.minSupportedVersion, CURRENT)
      };
    }
  };
  const DEV_TORN_ID$1 = 2728237;
  const LOCK_ICON = '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';
  const COG_ICON = '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>';
  class Overlay {
    constructor(auth, api, logger, chatDock, mugHelper) {
      this.auth = auth;
      this.api = api;
      this.logger = logger;
      this.chatDock = chatDock;
      this.mugHelper = mugHelper;
      this.overlay = null;
      this.panel = null;
      this.isOpen = false;
      this.subscriptionSection = null;
      this.warSection = null;
      this.muggingSection = null;
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
      UpdateCheck.status().then(({ latest, outdated }) => {
        if (!outdated) return;
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
      text.textContent = `Update available. You're on v${UpdateCheck.current}, latest is v${this.latestVersion}.`;
      const link2 = document.createElement("a");
      link2.href = DOWNLOAD_URL;
      link2.target = "_blank";
      link2.rel = "noopener";
      link2.className = "tm-update-link";
      link2.textContent = "Update now";
      notice.appendChild(text);
      notice.appendChild(link2);
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
      if (this.muggingSection) {
        this.muggingSection.destroy();
        this.muggingSection = null;
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
      if (this.suspendedMessage && this.auth.isAuthenticated()) {
        return this.renderSuspendedPanel(this.suspendedMessage);
      }
      this.destroySections();
      this.panel.classList.remove("tm-overlay-panel--war", "tm-overlay-panel--chats");
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
        this.auth.fetchSubscription().then((sub) => this.setSubscription(sub)).catch((err) => {
          if (err.suspended) this.markSuspended(err.message);
        });
      }
      this.renderActiveTab();
    }
    markSuspended(message2) {
      this.suspendedMessage = message2;
      if (this.isOpen) this.renderSuspendedPanel(message2);
    }
    renderSuspendedPanel(message2) {
      this.destroySections();
      this.panel.classList.remove("tm-overlay-panel--war", "tm-overlay-panel--chats");
      this.panel.innerHTML = "";
      const closeBtn = document.createElement("button");
      closeBtn.className = "tm-overlay-close";
      closeBtn.textContent = "×";
      closeBtn.onclick = () => this.close();
      this.panel.appendChild(closeBtn);
      const notice = document.createElement("div");
      notice.className = "tm-suspended";
      notice.innerHTML = '<svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="10"/><line x1="4.9" y1="4.9" x2="19.1" y2="19.1"/></svg><p class="tm-suspended-title">You are suspended</p>';
      const text = document.createElement("p");
      text.className = "tm-suspended-text";
      text.textContent = message2;
      notice.appendChild(text);
      this.panel.appendChild(notice);
      this.panel.appendChild(this.createFooter());
    }
    devTabsEnabled() {
      var _a;
      return ((_a = this.auth.getUser()) == null ? void 0 : _a.torn_id) === DEV_TORN_ID$1;
    }
    createTabBar() {
      const tabs = document.createElement("div");
      tabs.className = "tm-tabs";
      this.chatsTab = this.createTab("Chats", "chats");
      this.warTab = null;
      this.warTabLock = null;
      this.muggingTab = null;
      tabs.appendChild(this.chatsTab);
      if (this.devTabsEnabled()) {
        this.warTab = this.createTab("Ranked War", "war");
        this.warTabLock = document.createElement("span");
        this.warTabLock.className = "tm-tab-lock";
        this.warTabLock.innerHTML = LOCK_ICON;
        this.warTab.appendChild(this.warTabLock);
        tabs.appendChild(this.warTab);
        this.muggingTab = this.createTab("Mugging", "mugging");
        tabs.appendChild(this.muggingTab);
      }
      this.settingsTab = this.createTab("", "settings");
      this.settingsTab.classList.add("tm-tab--icon");
      this.settingsTab.title = "Settings";
      this.settingsTab.innerHTML = COG_ICON;
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
      if ((this.activeTab === "war" || this.activeTab === "mugging") && !this.devTabsEnabled()) {
        this.activeTab = "chats";
      }
      if (this.activeTab === "war" && !((_a = this.subscription) == null ? void 0 : _a.active)) {
        this.activeTab = "settings";
      }
      this.destroySections();
      this.updateTabState();
      this.panel.classList.toggle("tm-overlay-panel--war", this.activeTab === "war");
      this.panel.classList.toggle("tm-overlay-panel--chats", this.activeTab === "chats");
      this.tabContent.innerHTML = "";
      if (this.activeTab === "war") {
        this.renderWarTab();
      } else if (this.activeTab === "mugging") {
        this.renderMuggingTab();
      } else if (this.activeTab === "chats") {
        this.renderChatsTab();
      } else {
        this.renderSettingsTab();
      }
    }
    updateTabState() {
      var _a;
      this.settingsTab.classList.toggle("tm-tab--active", this.activeTab === "settings");
      this.chatsTab.classList.toggle("tm-tab--active", this.activeTab === "chats");
      if (this.warTab) {
        const locked = !((_a = this.subscription) == null ? void 0 : _a.active);
        this.warTab.classList.toggle("tm-tab--active", this.activeTab === "war");
        this.warTab.classList.toggle("tm-tab--locked", locked);
        this.warTabLock.style.display = locked ? "" : "none";
        if (locked) {
          this.warTab.title = "Requires an active subscription";
        } else {
          this.warTab.removeAttribute("title");
        }
      }
      if (this.muggingTab) {
        this.muggingTab.classList.toggle("tm-tab--active", this.activeTab === "mugging");
      }
    }
    setSubscription(subscription) {
      this.subscription = subscription;
      if (this.warTab) this.updateTabState();
    }
    renderSettingsTab() {
      this.subscriptionSection = new SubscriptionSection(this.auth, (sub) => this.setSubscription(sub));
      this.tabContent.appendChild(this.subscriptionSection.render());
      const actions = document.createElement("div");
      actions.className = "tm-settings-actions";
      this.tabContent.appendChild(actions);
      const removeBtn = document.createElement("button");
      removeBtn.className = "tm-remove-key";
      removeBtn.textContent = "Remove API key";
      removeBtn.onclick = () => {
        this.auth.clear();
        this.subscription = null;
        this.activeTab = "chats";
        this.renderPanel();
      };
      actions.appendChild(removeBtn);
      const storageBtn = document.createElement("button");
      storageBtn.className = "tm-remove-key tm-storage-toggle";
      storageBtn.textContent = "View stored data";
      actions.appendChild(storageBtn);
      let viewer = null;
      storageBtn.onclick = () => {
        if (viewer) {
          viewer.remove();
          viewer = null;
          storageBtn.textContent = "View stored data";
          return;
        }
        viewer = new StorageViewer().render();
        this.tabContent.appendChild(viewer);
        storageBtn.textContent = "Hide stored data";
      };
    }
    renderWarTab() {
      this.warSection = new WarSection(this.api);
      this.tabContent.appendChild(this.warSection.render());
    }
    renderMuggingTab() {
      this.muggingSection = new MuggingSection(this.api, this.mugHelper);
      this.tabContent.appendChild(this.muggingSection.render());
    }
    renderChatsTab() {
      this.chatsSection = new ChatsSection(this.chatDock);
      this.tabContent.appendChild(this.chatsSection.render());
    }
    openChatMembers(room) {
      var _a;
      this.activeTab = "chats";
      if (this.isOpen) {
        this.renderActiveTab();
      } else {
        this.open();
      }
      (_a = this.chatsSection) == null ? void 0 : _a.openMembers(room);
    }
    renderUnauthenticatedPanel() {
      const authScreen = new AuthScreen(this.auth);
      this.panel.appendChild(
        authScreen.render(() => {
          var _a;
          (_a = this.chatDock) == null ? void 0 : _a.init();
          this.renderPanel();
        })
      );
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
      privacy.href = "https://tornmanager.com/legal#userscript-privacy-policy";
      privacy.target = "_blank";
      privacy.rel = "noopener";
      privacy.className = "tm-footer-link";
      privacy.textContent = "Privacy Policy";
      const tos = document.createElement("a");
      tos.href = "https://tornmanager.com/legal#userscript-terms-of-service";
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
      version.textContent = `v${"0.4.2"}`;
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
        `TornManager v${"0.4.2"}`,
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
    static el(tag, className, text) {
      const node = document.createElement(tag);
      if (className) node.className = className;
      if (text !== void 0) node.textContent = text;
      return node;
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
      if (!icons || document.getElementById("tornmanager-icon")) return;
      const icon = document.createElement("li");
      icon.id = "tornmanager-icon";
      icon.className = "tornmanager-icon";
      icon.onclick = () => this.overlay.toggle();
      icons.appendChild(icon);
    }
  }
  class SettingsMenuEntry {
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
      if (menu.querySelector(".tornmanager-menu-item")) return;
      const item = document.createElement("li");
      item.className = "link tornmanager-menu-item";
      const link2 = document.createElement("a");
      link2.href = window.location.href;
      link2.innerHTML = '<span class="tornmanager-menu-icon"></span><span>TornManager</span>';
      link2.addEventListener("click", (e) => {
        e.preventDefault();
        this.overlay.open();
      });
      item.appendChild(link2);
      const serverInfo = menu.querySelector(".server-info");
      if (serverInfo) {
        menu.insertBefore(item, serverInfo);
      } else {
        menu.appendChild(item);
      }
    }
  }
  const STORAGE_KEY = "tm_chat_house_rules";
  const HouseRules = {
    accepted() {
      try {
        return !!localStorage.getItem(STORAGE_KEY);
      } catch {
        return false;
      }
    },
    accept() {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify({ accepted_at: (/* @__PURE__ */ new Date()).toISOString() }));
      } catch {
        return;
      }
    }
  };
  const CHUNK = 32768;
  function bytesToBase64(bytes) {
    let binary = "";
    for (let i = 0; i < bytes.length; i += CHUNK) {
      binary += String.fromCharCode.apply(null, bytes.subarray(i, i + CHUNK));
    }
    return btoa(binary);
  }
  function base64ToBytes(b64) {
    const binary = atob(b64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    return bytes;
  }
  const POLL_INTERVAL_MS = 3e3;
  const MAX_LENGTH = 300;
  const DIVIDER_GAP_MS = 15 * 60 * 1e3;
  const POS_KEY$1 = "tm_chat_box_pos";
  const SIZE_KEY$1 = "tm_chat_box_size";
  const DRAG_THRESHOLD_PX$2 = 6;
  const MIN_WIDTH$1 = 280;
  const MIN_HEIGHT$1 = 300;
  const MAX_IMAGE_DIMENSION = 1600;
  const JPEG_QUALITY = 0.85;
  const MAX_UPLOAD_BYTES = 6 * 1024 * 1024;
  const LIGHTBOX_ANIM_MS = 200;
  const IMAGE_ICON_SVG = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>';
  const PEOPLE_ICON_SVG = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>';
  let zCounter$1 = 99991;
  class ChatBox {
    constructor(room, client, { onMinimize, onOpenMembers }) {
      this.room = room;
      this.client = client;
      this.onMinimize = onMinimize;
      this.onOpenMembers = onOpenMembers;
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
      if (!this.room.suspended && !(this.room.encrypted && !this.encKey)) {
        this.list.appendChild(this.createRetentionNotice());
      }
      this.skeleton = this.createSkeleton();
      this.list.appendChild(this.skeleton);
      this.element.appendChild(this.list);
      this.composer = this.createComposer();
      this.element.appendChild(this.composer);
      this.element.addEventListener("pointerdown", () => {
        this.element.style.zIndex = ++zCounter$1;
      });
      this.makeDraggable(header);
      this.applySize();
      this.addResizeHandle();
      this.applyPosition();
      if (this.room.suspended) {
        this.showSuspended();
      } else if (this.room.encrypted && !this.encKey) {
        this.showLocked();
      } else if (this.room.kind === "public" && !HouseRules.accepted()) {
        this.showHouseRules();
      } else {
        this.startPolling();
      }
      return this.element;
    }
    startPolling() {
      this.poll();
      this.pollInterval = setInterval(() => this.poll(), POLL_INTERVAL_MS);
    }
    showHouseRules() {
      var _a;
      (_a = this.skeleton) == null ? void 0 : _a.remove();
      this.composer.style.display = "none";
      const notice = document.createElement("div");
      notice.className = "tm-cb-rules";
      const title = document.createElement("p");
      title.className = "tm-cb-rules-title";
      title.textContent = "House rules";
      const list = document.createElement("ul");
      list.className = "tm-cb-rules-list";
      const rules = [
        "This chat is moderated. I (Bram) can remove messages and ban accounts.",
        this.room.anonymous ? "Anonymous to other players, but not encrypted. For moderation I can link messages to accounts." : "Shows your Torn name. Not encrypted, so I can read messages for moderation.",
        "Follow Torn's rules. No harassment, scams, or illegal content.",
        "Never share API keys, passwords, or personal information."
      ];
      for (const rule of rules) {
        const item = document.createElement("li");
        item.textContent = rule;
        list.appendChild(item);
      }
      const accept = document.createElement("button");
      accept.type = "button";
      accept.className = "tm-cb-rules-accept";
      accept.textContent = "I agree";
      accept.onclick = () => {
        HouseRules.accept();
        notice.remove();
        this.composer.style.display = "";
        this.startPolling();
      };
      const hint = document.createElement("p");
      hint.className = "tm-cb-rules-hint";
      hint.append(
        "Full details: ",
        link(PRIVACY_URL, "Privacy Policy"),
        " · ",
        link(TOS_URL, "Terms of Service"),
        ". Your agreement is saved on this device (View stored data in settings)."
      );
      notice.append(title, list, accept, hint);
      this.list.appendChild(notice);
    }
    createRetentionNotice() {
      const notice = document.createElement("div");
      notice.className = "tm-cb-retention";
      notice.textContent = this.room.kind === "public" ? `Messages older than 24 hours in ${this.room.name} are deleted.` : "Messages older than 7 days are deleted.";
      return notice;
    }
    // This device is a member of the encrypted room but doesn't hold its key, so
    // nothing here can be read or sent. Explain how to restore it rather than
    // showing a wall of locked-message placeholders.
    showLocked() {
      var _a;
      this.list.innerHTML = "";
      const notice = document.createElement("div");
      notice.className = "tm-cb-locked";
      notice.innerHTML = `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg><p class="tm-cb-locked-title">This room is locked on this device</p><p class="tm-cb-locked-text">Its messages are end-to-end encrypted and this device doesn't have the key. Open the room's invite link in this browser to unlock it. Copy the link from a device where the room already works.</p>`;
      this.list.appendChild(notice);
      (_a = this.composer) == null ? void 0 : _a.remove();
    }
    // Replace the conversation with a removed-notice and stop polling. Triggered
    // when the room arrives already suspended, or when a poll returns 403.
    showSuspended() {
      var _a;
      if (this.pollInterval) {
        clearInterval(this.pollInterval);
        this.pollInterval = null;
      }
      this.list.innerHTML = "";
      const notice = document.createElement("div");
      notice.className = "tm-cb-suspended";
      notice.innerHTML = `<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg><p>You've been suspended from this chat by the host.</p>`;
      this.list.appendChild(notice);
      (_a = this.composer) == null ? void 0 : _a.remove();
    }
    applyPosition() {
      const stagger = document.querySelectorAll(".tm-cb").length;
      const saved = this.savedPositions()[this.room.id];
      if (saved && typeof saved.left === "number" && typeof saved.top === "number") {
        this.moveTo(saved.left, saved.top);
        return;
      }
      this.element.style.right = `${12 + stagger * 28}px`;
      this.element.style.bottom = `${100 + stagger * 24}px`;
    }
    // Drag by the header; taps on the header buttons pass through untouched.
    makeDraggable(header) {
      let start = null;
      let dragging = false;
      header.addEventListener("pointerdown", (e) => {
        if (e.target.closest(".tm-cb-action, .tm-cb-members--link")) return;
        const rect = this.element.getBoundingClientRect();
        start = { x: e.clientX, y: e.clientY, left: rect.left, top: rect.top };
        dragging = false;
        header.setPointerCapture(e.pointerId);
      });
      header.addEventListener("pointermove", (e) => {
        if (!start) return;
        const dx = e.clientX - start.x;
        const dy = e.clientY - start.y;
        if (!dragging && Math.hypot(dx, dy) < DRAG_THRESHOLD_PX$2) return;
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
        localStorage.setItem(POS_KEY$1, JSON.stringify(positions));
      } catch {
      }
    }
    savedPositions() {
      try {
        const raw = localStorage.getItem(POS_KEY$1);
        const positions = raw ? JSON.parse(raw) : {};
        return typeof positions === "object" && positions !== null ? positions : {};
      } catch {
        return {};
      }
    }
    applySize() {
      const saved = this.savedSizes()[this.room.id];
      if (saved && saved.w && saved.h) {
        this.element.style.width = `${saved.w}px`;
        this.element.style.height = `${saved.h}px`;
      }
    }
    // A pointer-driven resize grip (works with mouse and touch alike, unlike the
    // CSS resize corner which ignores touch). Resizing pins the box to its
    // top-left so it grows down-right regardless of how it was anchored.
    addResizeHandle() {
      const handle = document.createElement("div");
      handle.className = "tm-cb-resize";
      this.element.appendChild(handle);
      let start = null;
      handle.addEventListener("pointerdown", (e) => {
        e.preventDefault();
        const rect = this.element.getBoundingClientRect();
        this.moveTo(rect.left, rect.top);
        start = { x: e.clientX, y: e.clientY, w: rect.width, h: rect.height, left: rect.left, top: rect.top };
        handle.setPointerCapture(e.pointerId);
        this.element.style.zIndex = ++zCounter$1;
      });
      handle.addEventListener("pointermove", (e) => {
        if (!start) return;
        const maxW = window.innerWidth - start.left - 8;
        const maxH = window.innerHeight - start.top - 8;
        const width = Math.min(Math.max(start.w + (e.clientX - start.x), MIN_WIDTH$1), maxW);
        const height = Math.min(Math.max(start.h + (e.clientY - start.y), MIN_HEIGHT$1), maxH);
        this.element.style.width = `${width}px`;
        this.element.style.height = `${height}px`;
      });
      const finish = () => {
        if (!start) return;
        start = null;
        this.saveSize();
      };
      handle.addEventListener("pointerup", finish);
      handle.addEventListener("pointercancel", finish);
    }
    saveSize() {
      const sizes = this.savedSizes();
      sizes[this.room.id] = { w: Math.round(this.element.offsetWidth), h: Math.round(this.element.offsetHeight) };
      try {
        localStorage.setItem(SIZE_KEY$1, JSON.stringify(sizes));
      } catch {
      }
    }
    savedSizes() {
      try {
        const raw = localStorage.getItem(SIZE_KEY$1);
        const sizes = raw ? JSON.parse(raw) : {};
        return typeof sizes === "object" && sizes !== null ? sizes : {};
      } catch {
        return {};
      }
    }
    destroy() {
      var _a, _b;
      if (this.pollInterval) {
        clearInterval(this.pollInterval);
        this.pollInterval = null;
      }
      if (this.imageUrls) {
        for (const url of Object.values(this.imageUrls)) URL.revokeObjectURL(url);
        this.imageUrls = null;
      }
      if ((_a = this.pendingImage) == null ? void 0 : _a.previewUrl) URL.revokeObjectURL(this.pendingImage.previewUrl);
      (_b = this.element) == null ? void 0 : _b.remove();
    }
    createHeader() {
      const header = document.createElement("div");
      header.className = "tm-cb-header";
      const title = document.createElement("div");
      title.className = "tm-cb-title";
      const name = document.createElement("span");
      name.className = "tm-cb-name";
      name.textContent = this.room.name;
      const isPublic = this.room.kind === "public";
      const count = document.createElement(isPublic ? "span" : "button");
      count.className = "tm-cb-members";
      count.innerHTML = `${PEOPLE_ICON_SVG}<span>${this.room.member_count}</span>`;
      if (isPublic) {
        count.title = `${this.room.member_count} members`;
      } else {
        count.type = "button";
        count.title = "View members";
        count.classList.add("tm-cb-members--link");
        count.onclick = () => {
          var _a;
          return (_a = this.onOpenMembers) == null ? void 0 : _a.call(this, this.room);
        };
      }
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
          this.appendSystem("Encryption key missing. Rejoin via an invite link first.");
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
      this.pending = document.createElement("div");
      this.pending.className = "tm-cb-pending";
      this.pending.hidden = true;
      const row = document.createElement("div");
      row.className = "tm-cb-composer-row";
      this.input = document.createElement("textarea");
      this.input.className = "tm-cb-input";
      this.input.placeholder = "Type your message...";
      this.input.rows = 1;
      this.input.maxLength = MAX_LENGTH;
      this.counter = document.createElement("span");
      this.counter.className = "tm-cb-counter";
      this.fileInput = document.createElement("input");
      this.fileInput.type = "file";
      this.fileInput.accept = "image/*";
      this.fileInput.style.display = "none";
      this.fileInput.addEventListener("change", () => this.handleFilePick());
      this.attachBtn = document.createElement("button");
      this.attachBtn.type = "button";
      this.attachBtn.className = "tm-cb-attach";
      this.attachBtn.title = "Attach an image";
      this.attachBtn.innerHTML = IMAGE_ICON_SVG;
      this.attachBtn.onclick = () => this.fileInput.click();
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
      row.appendChild(this.input);
      row.appendChild(this.counter);
      row.appendChild(this.attachBtn);
      row.appendChild(send);
      composer.appendChild(this.pending);
      composer.appendChild(row);
      composer.appendChild(this.fileInput);
      return composer;
    }
    async handleFilePick() {
      var _a;
      const file = (_a = this.fileInput.files) == null ? void 0 : _a[0];
      this.fileInput.value = "";
      if (!file) return;
      if (file.type && !file.type.startsWith("image/")) {
        this.appendTransientNotice("That's not an image. Attach a JPG or PNG.");
        return;
      }
      if (this.room.encrypted && !this.encKey) {
        this.appendTransientNotice("Rejoin via the invite link first to restore this room's key.");
        return;
      }
      this.setBusy(true);
      try {
        const bytes = await this.processImage(file);
        if (!bytes) throw new Error("read-failed");
        if (bytes.length > MAX_UPLOAD_BYTES) {
          this.appendTransientNotice("That image is too large. Try a smaller one.");
          return;
        }
        this.stagePendingImage(bytes);
      } catch {
        this.appendTransientNotice("Couldn't read that image. Try a JPG or PNG. iPhone HEIC photos aren't supported.");
      } finally {
        this.setBusy(false);
      }
    }
    stagePendingImage(bytes) {
      this.clearPendingImage();
      const previewUrl = URL.createObjectURL(new Blob([bytes], { type: "image/jpeg" }));
      this.pendingImage = { bytes, previewUrl };
      const thumb = document.createElement("img");
      thumb.className = "tm-cb-pending-thumb";
      thumb.src = previewUrl;
      thumb.alt = "";
      const label = document.createElement("span");
      label.className = "tm-cb-pending-label";
      label.textContent = "Image attached, add a message or send";
      const remove = document.createElement("button");
      remove.type = "button";
      remove.className = "tm-cb-pending-remove";
      remove.title = "Remove image";
      remove.textContent = "×";
      remove.onclick = () => this.clearPendingImage();
      this.pending.replaceChildren(thumb, label, remove);
      this.pending.hidden = false;
      this.input.focus();
    }
    clearPendingImage() {
      var _a;
      if ((_a = this.pendingImage) == null ? void 0 : _a.previewUrl) URL.revokeObjectURL(this.pendingImage.previewUrl);
      this.pendingImage = null;
      if (this.pending) {
        this.pending.replaceChildren();
        this.pending.hidden = true;
      }
    }
    setBusy(on) {
      if (!this.attachBtn) return;
      this.attachBtn.disabled = on;
      this.attachBtn.classList.toggle("tm-cb-attach--busy", on);
    }
    processImage(file) {
      return new Promise((resolve, reject) => {
        const objectUrl = URL.createObjectURL(file);
        const img = new Image();
        img.onload = () => {
          URL.revokeObjectURL(objectUrl);
          const scale = Math.min(1, MAX_IMAGE_DIMENSION / Math.max(img.naturalWidth, img.naturalHeight));
          const width = Math.max(1, Math.round(img.naturalWidth * scale));
          const height = Math.max(1, Math.round(img.naturalHeight * scale));
          const canvas = document.createElement("canvas");
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext("2d");
          ctx.fillStyle = "#ffffff";
          ctx.fillRect(0, 0, width, height);
          ctx.drawImage(img, 0, 0, width, height);
          canvas.toBlob(async (blob) => {
            if (!blob) {
              reject(new Error("Could not read that image."));
              return;
            }
            resolve(new Uint8Array(await blob.arrayBuffer()));
          }, "image/jpeg", JPEG_QUALITY);
        };
        img.onerror = () => {
          URL.revokeObjectURL(objectUrl);
          reject(new Error("Could not read that image."));
        };
        img.src = objectUrl;
      });
    }
    async send() {
      const caption = this.input.value.trim();
      if (!this.pendingImage && !caption) return;
      if (this.room.encrypted && !this.encKey) {
        this.appendSystem("Can't send. Rejoin via the invite link to restore this room's key.");
        return;
      }
      if (this.pendingImage) {
        await this.sendPendingImage(caption);
        return;
      }
      this.input.value = "";
      this.counter.textContent = "";
      try {
        const payload = this.room.encrypted ? await ChatCrypto.encrypt(this.encKey, caption) : caption;
        await this.client.sendMessage(this.room.id, payload);
        this.poll();
      } catch (err) {
        this.appendSystem(err.message || "Could not send message.");
      }
    }
    async sendPendingImage(caption) {
      this.setBusy(true);
      try {
        let bytes = this.pendingImage.bytes;
        if (this.room.encrypted) {
          bytes = await ChatCrypto.encryptBytes(this.encKey, bytes);
        }
        if (bytes.length > MAX_UPLOAD_BYTES) {
          throw new Error("That image is too large to send.");
        }
        let bodyPayload = "";
        if (caption) {
          bodyPayload = this.room.encrypted ? await ChatCrypto.encrypt(this.encKey, caption) : caption;
        }
        await this.client.sendImage(this.room.id, bytesToBase64(bytes), { body: bodyPayload });
        this.clearPendingImage();
        this.input.value = "";
        this.counter.textContent = "";
        this.poll();
      } catch (err) {
        this.appendTransientNotice(err.message || "Could not send image.");
      } finally {
        this.setBusy(false);
      }
    }
    appendTransientNotice(text) {
      const row = document.createElement("div");
      row.className = "tm-cb-notice";
      row.textContent = text;
      this.list.appendChild(row);
      this.list.scrollTop = this.list.scrollHeight;
      setTimeout(() => row.remove(), 5e3);
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
      }).catch((err) => {
        if ((err == null ? void 0 : err.status) === 403) {
          this.room.suspended = true;
          this.showSuspended();
        }
      });
    }
    async appendMessages(messages) {
      messages = messages.filter((message2) => message2.id > this.lastMessageId);
      if (!messages.length) return;
      for (const message2 of messages) {
        this.lastMessageId = Math.max(this.lastMessageId, message2.id);
      }
      const prepared = [];
      for (const message2 of messages) {
        prepared.push({ message: message2, ...await this.resolveBody(message2) });
      }
      const nearBottom = this.list.scrollHeight - this.list.scrollTop - this.list.clientHeight < 60;
      for (const { message: message2, body, locked } of prepared) {
        this.appendDividerIfNeeded(message2.at);
        if (message2.system) {
          this.appendSystem(message2.body);
          continue;
        }
        const row = document.createElement("div");
        row.className = "tm-cb-row";
        const own = message2.own ?? message2.torn_id === this.client.me().torn_id;
        if (own) row.classList.add("tm-cb-row--own");
        let sender;
        if (message2.torn_id) {
          sender = document.createElement("a");
          sender.href = `https://www.torn.com/profiles.php?XID=${message2.torn_id}`;
          sender.target = "_blank";
          sender.rel = "noopener";
        } else {
          sender = document.createElement("span");
        }
        sender.className = "tm-cb-sender";
        if (message2.admin) {
          sender.classList.add("tm-cb-sender--admin");
          sender.textContent = `${message2.name} (admin):`;
        } else {
          sender.style.color = this.colorForName(message2.name);
          sender.textContent = `${message2.name}:`;
        }
        row.appendChild(sender);
        if (message2.has_image) {
          const chip = document.createElement("button");
          chip.type = "button";
          chip.className = "tm-cb-image-chip";
          chip.innerHTML = `${IMAGE_ICON_SVG}<span>image</span>`;
          chip.onclick = () => this.openImage(message2);
          row.appendChild(chip);
          if (body && !locked) {
            const caption = document.createElement("span");
            caption.className = "tm-cb-body tm-cb-caption";
            caption.textContent = body;
            row.appendChild(caption);
          }
        } else {
          const bodyEl = document.createElement("span");
          bodyEl.className = locked ? "tm-cb-body tm-cb-body--locked" : "tm-cb-body";
          bodyEl.textContent = body;
          row.appendChild(bodyEl);
        }
        this.list.appendChild(row);
      }
      if (nearBottom) this.list.scrollTop = this.list.scrollHeight;
    }
    async resolveBody(message2) {
      if (message2.system || !this.room.encrypted) {
        return { body: message2.body, locked: false };
      }
      if (!message2.body) {
        return { body: "", locked: false };
      }
      if (!this.encKey) {
        return { body: "🔒 Encrypted. Rejoin via the invite link to read.", locked: true };
      }
      try {
        return { body: await ChatCrypto.decrypt(this.encKey, message2.body), locked: false };
      } catch {
        return { body: "🔒 Can't decrypt this message.", locked: true };
      }
    }
    async openImage(message2) {
      const overlay = document.createElement("div");
      overlay.className = "tm-lightbox";
      overlay.style.zIndex = 2147483647;
      const spinner = document.createElement("div");
      spinner.className = "tm-lightbox-spinner";
      overlay.appendChild(spinner);
      document.body.appendChild(overlay);
      requestAnimationFrame(() => overlay.classList.add("tm-lightbox--open"));
      let closed = false;
      const close = () => {
        if (closed) return;
        closed = true;
        overlay.classList.remove("tm-lightbox--open");
        document.removeEventListener("keydown", onKey);
        setTimeout(() => overlay.remove(), LIGHTBOX_ANIM_MS);
      };
      const onKey = (e) => {
        if (e.key === "Escape") close();
      };
      overlay.addEventListener("click", (e) => {
        if (e.target === overlay || e.target === spinner) close();
      });
      document.addEventListener("keydown", onKey);
      try {
        const url = await this.imageUrl(message2);
        if (closed) return;
        const img = document.createElement("img");
        img.className = "tm-lightbox-img";
        img.alt = "";
        img.onload = () => spinner.remove();
        img.src = url;
        overlay.appendChild(img);
      } catch (err) {
        spinner.remove();
        const notice = document.createElement("div");
        notice.className = "tm-lightbox-error";
        notice.textContent = err.message || "Could not load image.";
        overlay.appendChild(notice);
      }
    }
    async imageUrl(message2) {
      this.imageUrls || (this.imageUrls = {});
      if (this.imageUrls[message2.id]) return this.imageUrls[message2.id];
      if (this.room.encrypted && !this.encKey) {
        throw new Error("Encrypted. Rejoin via the invite link to view.");
      }
      const raw = base64ToBytes(await this.client.fetchImage(this.room.id, message2.id));
      const bytes = this.room.encrypted ? await ChatCrypto.decryptBytes(this.encKey, raw) : raw;
      const url = URL.createObjectURL(new Blob([bytes], { type: "image/jpeg" }));
      this.imageUrls[message2.id] = url;
      return url;
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
  function link(href, label) {
    const anchor = document.createElement("a");
    anchor.href = href;
    anchor.target = "_blank";
    anchor.rel = "noopener";
    anchor.textContent = label;
    return anchor;
  }
  const OPEN_KEY$1 = "tm_chat_open";
  const SEEN_KEY = "tm_chat_seen";
  const FAB_POS_KEY = "tm_chat_fab_pos";
  const BUTTON_MODE_KEY = "tm_chat_button_mode";
  const LEGACY_HIDDEN_KEY = "tm_chat_fab_hidden";
  const BUTTON_MODES = ["none", "floating", "integrated"];
  const UNREAD_POLL_MS = 8e3;
  const DRAG_THRESHOLD_PX$1 = 6;
  const TM_LOGO = '<svg width="34" height="34" viewBox="0 0 32 32"><rect width="32" height="32" rx="7" fill="#0070f3"/><text x="16" y="22" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="15" fill="#fff">TM</text></svg>';
  const TM_LOGO_URI = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='15' fill='white'%3ETM%3C/text%3E%3C/svg%3E";
  const REINJECT_DEBOUNCE_MS = 200;
  class ChatDock {
    constructor(auth, client, logger) {
      this.auth = auth;
      this.client = client;
      this.logger = logger;
      this.rooms = [];
      this.boxes = /* @__PURE__ */ new Map();
      this.menuItems = /* @__PURE__ */ new Map();
      this.unread = /* @__PURE__ */ new Set();
      this.menuOpen = false;
      this.unreadInterval = null;
    }
    // Idempotent: boot calls it before sign-in (no-op) and the overlay calls it
    // again after a successful sign-in, so rooms open without a page reload.
    init() {
      if (this.initialized || !this.auth.isAuthenticated()) return;
      this.initialized = true;
      Dom.ready("body", () => {
        this.fab = document.createElement("button");
        this.fab.type = "button";
        this.fab.className = "tm-chat-fab";
        this.fab.title = "TornManager chats (drag to move)";
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
          var _a;
          if (!this.menuOpen) return;
          if (this.menu.contains(e.target)) return;
          if (this.fab.contains(e.target)) return;
          if ((_a = this.barLauncher) == null ? void 0 : _a.contains(e.target)) return;
          this.toggleMenu(false);
        });
        this.observeChatBar();
        this.handleInviteHash().then(() => this.refresh());
        this.unreadInterval = setInterval(() => this.pollUnread(), UNREAD_POLL_MS);
      });
    }
    // Torn rebuilds its chat bar constantly (open/close, new messages), which
    // wipes our injected launcher — so re-inject on mutation, debounced, and only
    // while integrated mode is active.
    observeChatBar() {
      Dom.ready("#chatRoot", (root) => {
        let timer = null;
        new MutationObserver(() => {
          if (this.buttonMode() !== "integrated") return;
          clearTimeout(timer);
          timer = setTimeout(() => this.injectBarLauncher(), REINJECT_DEBOUNCE_MS);
        }).observe(root, { childList: true, subtree: true });
      });
    }
    // BETA: a single TM launcher button placed in Torn's chat bar, between the
    // People and Settings buttons (both stable ids). Clicking it opens the room
    // menu — same menu the floating button uses. We never join Torn's window row.
    injectBarLauncher() {
      var _a;
      if (this.buttonMode() !== "integrated" || !this.rooms.length) {
        (_a = document.getElementById("tm_chat_launcher")) == null ? void 0 : _a.remove();
        return;
      }
      if (document.getElementById("tm_chat_launcher")) return;
      const settingsBtn = document.getElementById("notes_settings_button");
      const bar = settingsBtn == null ? void 0 : settingsBtn.parentElement;
      if (!bar) return;
      const button = document.createElement("button");
      button.type = "button";
      button.id = "tm_chat_launcher";
      button.className = settingsBtn.className;
      button.title = "TornManager chats";
      const logo = document.createElement("img");
      logo.className = "tm-launcher-logo";
      logo.src = TM_LOGO_URI;
      logo.alt = "TM";
      button.appendChild(logo);
      button.addEventListener("click", (e) => {
        e.stopPropagation();
        this.toggleMenu(!this.menuOpen);
      });
      bar.insertBefore(button, settingsBtn);
      this.barLauncher = button;
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
        if (!dragging && Math.hypot(dx, dy) < DRAG_THRESHOLD_PX$1) return;
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
      const anchor = this.buttonMode() === "integrated" && this.barLauncher ? this.barLauncher : this.fab;
      const rect = anchor.getBoundingClientRect();
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
    buttonMode() {
      const stored = localStorage.getItem(BUTTON_MODE_KEY);
      if (BUTTON_MODES.includes(stored)) return stored;
      return localStorage.getItem(LEGACY_HIDDEN_KEY) === "1" ? "none" : "floating";
    }
    setButtonMode(mode) {
      try {
        localStorage.setItem(BUTTON_MODE_KEY, mode);
      } catch {
      }
      if (mode !== "floating") this.toggleMenu(false);
      this.updateFabDisplay();
    }
    updateFabDisplay() {
      if (!this.fab) return;
      const mode = this.buttonMode();
      this.fab.style.display = this.rooms.length && mode === "floating" ? "" : "none";
      this.injectBarLauncher();
    }
    async handleInviteHash() {
      const match = window.location.hash.match(/tmchat=([A-Za-z0-9_-]+)(?:~([A-Za-z0-9_-]+))?/);
      if (!match) return;
      history.replaceState(null, "", window.location.pathname + window.location.search);
      const [, token, encKey] = match;
      try {
        const room = await this.client.joinByToken(token);
        if (encKey) ChatCrypto.setKey(room.id, encKey);
        showToast(room.suspended ? `You're suspended from "${room.name}"` : `Joined "${room.name}"`);
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
      }).catch((err) => {
        var _a;
        if (err.suspended) {
          (_a = this.overlay) == null ? void 0 : _a.markSuspended(err.message);
          return;
        }
        this.logger.log(err, "chat rooms list");
      });
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
      if (!this.boxesEl) return;
      const room = this.rooms.find((r) => r.id === roomId);
      if (!room) return;
      const box = new ChatBox(room, this.client, {
        onMinimize: (id) => this.markOpen(id, false),
        onOpenMembers: (r) => {
          var _a;
          return (_a = this.overlay) == null ? void 0 : _a.openChatMembers(r);
        }
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
        const raw = localStorage.getItem(OPEN_KEY$1);
        const ids = raw ? JSON.parse(raw) : [];
        return Array.isArray(ids) ? ids : [];
      } catch {
        return [];
      }
    }
    saveOpenIds(ids) {
      try {
        localStorage.setItem(OPEN_KEY$1, JSON.stringify(ids));
      } catch {
      }
    }
  }
  const CACHE_KEY = "tm_mug_targets_cache";
  const SCAN_KEY = "tm_mug_targets_scan";
  const MARKET_PRICE_KEY = "tm_mug_market_prices";
  const BUDGET_KEY = "tm_mug_buy_budget";
  const CLOTHING_STORE_TYPE = 5;
  const CACHE_TTL_MS = 5 * 60 * 1e3;
  const SCAN_DELAY_MS = 750;
  const MAX_TARGETS = 120;
  const MugTargets = {
    onBazaarDirectory() {
      return location.pathname.endsWith("/page.php") && new URLSearchParams(location.search).get("sid") === "bazaar";
    },
    collectUserIds() {
      const ids = [];
      const seen = /* @__PURE__ */ new Set();
      for (const link2 of document.querySelectorAll('a[href*="bazaar.php?userId="]')) {
        const match = /userId=(\d+)/.exec(link2.getAttribute("href") || "");
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
      var _a, _b;
      const sellers = [];
      const seen = /* @__PURE__ */ new Set();
      for (const row of document.querySelectorAll(".sellerRow___PaRgK")) {
        const link2 = row.querySelector('a[href*="profiles.php?XID="]');
        const match = link2 && /XID=(\d+)/.exec(link2.getAttribute("href") || "");
        if (!match || seen.has(match[1])) continue;
        const price = parseInt((((_a = row.querySelector(".price___cFwLC")) == null ? void 0 : _a.textContent) || "").replace(/[^0-9]/g, ""), 10);
        const available = parseInt(
          (((_b = row.querySelector(".available___XH9yl")) == null ? void 0 : _b.textContent) || "").replace(/[^0-9]/g, ""),
          10
        );
        if (!Number.isFinite(price) || price <= 0) continue;
        seen.add(match[1]);
        sellers.push({
          id: match[1],
          name: (link2.getAttribute("aria-label") || "").replace(/^View profile of\s*/i, "") || `User ${match[1]}`,
          price,
          available: Number.isFinite(available) ? available : 1
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
      var _a, _b;
      const key = MugKey.get();
      if (!key) throw new Error("Connect your Full Access key on the Mugging tab first.");
      let data;
      try {
        data = await TornDirect.get(`/market/${itemId}/itemmarket`, key);
      } catch (err) {
        throw MugKey.invalidKeyError(err) || err;
      }
      MugLogs.bumpApiCalls();
      const value = (_b = (_a = data == null ? void 0 : data.itemmarket) == null ? void 0 : _a.item) == null ? void 0 : _b.average_price;
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
            cache[id] = { id, name: (cached == null ? void 0 : cached.name) || seller.name, error: true, at: Date.now() };
          }
          if (done < limited.length - 1) await delay(SCAN_DELAY_MS);
        }
        done += 1;
        const profile = cache[id];
        if (profile == null ? void 0 : profile.muggable) {
          const deal = buyMugDeal(seller, { marketValue, budget, mugRate });
          if (deal.qty > 0 && deal.profit > 0) {
            onTarget == null ? void 0 : onTarget({ ...seller, ...deal });
          }
        }
        onProgress == null ? void 0 : onProgress(done, limited.length);
      }
      this.writeCache(cache);
    },
    async scan(ids, { force = false, onProgress, onTarget } = {}) {
      var _a;
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
            cache[id] = { id, name: (cached == null ? void 0 : cached.name) || `User ${id}`, error: true, at: Date.now() };
          }
          if (done < limited.length - 1) await delay(SCAN_DELAY_MS);
        }
        done += 1;
        if ((_a = cache[id]) == null ? void 0 : _a.muggable) onTarget == null ? void 0 : onTarget(cache[id]);
        onProgress == null ? void 0 : onProgress(done, limited.length);
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
        at: Date.now()
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
        hospital: entries.filter((e) => e.state === "Hospital")
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
    }
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
  function parseMoney(str) {
    const s = String(str || "").trim().toLowerCase().replace(/[$,\s]/g, "");
    const match = /^([0-9]*\.?[0-9]+)([kmb])?$/.exec(s);
    if (!match) return NaN;
    let n = parseFloat(match[1]);
    if (match[2] === "k") n *= 1e3;
    else if (match[2] === "m") n *= 1e6;
    else if (match[2] === "b") n *= 1e9;
    return n;
  }
  function formatMoney(n) {
    if (!Number.isFinite(n) || n === 0) return "$0";
    const sign = n < 0 ? "-" : "";
    const abs = Math.abs(n);
    if (abs >= 1e9) return `${sign}$${trim(abs / 1e9)}b`;
    if (abs >= 1e6) return `${sign}$${trim(abs / 1e6)}m`;
    if (abs >= 1e3) return `${sign}$${trim(abs / 1e3)}k`;
    return `${sign}$${Math.round(abs).toLocaleString("en-US")}`;
  }
  function trim(x) {
    return x.toFixed(2).replace(/\.?0+$/, "");
  }
  const OPEN_KEY = "tm_mug_helper_open";
  const POS_KEY = "tm_mug_helper_pos";
  const SIZE_KEY = "tm_mug_helper_size";
  const DRAG_THRESHOLD_PX = 6;
  const MIN_WIDTH = 260;
  const MIN_HEIGHT = 240;
  const DEV_TORN_ID = 2728237;
  const HELPER_ICON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="4" width="18" height="16" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/></svg>';
  const NAV_LINKS = [
    { label: "Russian Roulette", url: "https://www.torn.com/page.php?sid=russianRoulette#/" },
    { label: "Poker", url: "https://www.torn.com/page.php?sid=holdem" },
    { label: "Item Market", url: "https://www.torn.com/page.php?sid=ItemMarket" },
    { label: "Bazaar", url: "https://www.torn.com/page.php?sid=bazaar" },
    { label: "Auction House", url: "https://www.torn.com/amarket.php" }
  ];
  let zCounter = 99995;
  class MugHelper {
    constructor(auth) {
      this.auth = auth;
      this.element = null;
      this.onResize = null;
    }
    init() {
      var _a, _b;
      if (((_b = (_a = this.auth) == null ? void 0 : _a.getUser()) == null ? void 0 : _b.torn_id) !== DEV_TORN_ID) return;
      if (!this.isOpen()) return;
      Dom.ready("body", () => this.open());
    }
    isOpen() {
      return localStorage.getItem(OPEN_KEY) === "1";
    }
    setOpenState(open) {
      try {
        localStorage.setItem(OPEN_KEY, open ? "1" : "0");
      } catch {
        return;
      }
    }
    toggle() {
      if (this.element) this.close();
      else this.open();
    }
    open() {
      if (this.element) {
        this.element.style.zIndex = ++zCounter;
        return;
      }
      this.render();
      this.setOpenState(true);
    }
    close() {
      var _a;
      if (this.onResize) {
        window.removeEventListener("resize", this.onResize);
        this.onResize = null;
      }
      if (this.navPoll) {
        clearInterval(this.navPoll);
        this.navPoll = null;
      }
      this.clearHighlights();
      (_a = this.element) == null ? void 0 : _a.remove();
      this.element = null;
      this.setOpenState(false);
    }
    render() {
      this.element = document.createElement("div");
      this.element.className = "tm-mh";
      const header = this.createHeader();
      this.element.appendChild(header);
      this.body = document.createElement("div");
      this.body.className = "tm-mh-body";
      this.element.appendChild(this.body);
      this.renderBody();
      this.element.addEventListener("pointerdown", () => {
        this.element.style.zIndex = ++zCounter;
      });
      this.makeDraggable(header);
      this.applySize();
      this.addResizeHandle();
      this.applyPosition();
      document.body.appendChild(this.element);
      this.onResize = () => this.clampPosition();
      window.addEventListener("resize", this.onResize);
      this.navPoll = setInterval(() => {
        if (MugTargets.currentItemId() !== this.lastItemId) this.renderBody();
      }, 700);
    }
    createHeader() {
      const header = document.createElement("div");
      header.className = "tm-mh-header";
      const title = document.createElement("span");
      title.className = "tm-mh-title";
      title.textContent = "Mug helper";
      header.appendChild(title);
      const close = document.createElement("button");
      close.type = "button";
      close.className = "tm-mh-action";
      close.title = "Close";
      close.textContent = "×";
      close.onclick = () => this.close();
      header.appendChild(close);
      return header;
    }
    renderBody() {
      this.lastItemId = MugTargets.currentItemId();
      this.body.innerHTML = "";
      this.body.appendChild(this.navEl());
      this.content = document.createElement("div");
      this.content.className = "tm-mh-content";
      this.body.appendChild(this.content);
      this.renderContent();
    }
    navEl() {
      const nav = document.createElement("div");
      nav.className = "tm-mh-nav";
      for (const link2 of NAV_LINKS) {
        const anchor = document.createElement("a");
        anchor.className = "tm-mh-nav-link";
        anchor.href = link2.url;
        anchor.textContent = link2.label;
        if (this.isCurrentPage(link2.url)) anchor.classList.add("tm-mh-nav-link--active");
        nav.appendChild(anchor);
      }
      return nav;
    }
    isCurrentPage(url) {
      try {
        const target = new URL(url);
        if (location.pathname !== target.pathname) return false;
        const targetSid = new URLSearchParams(target.search).get("sid");
        if (!targetSid) return true;
        const currentSid = new URLSearchParams(location.search).get("sid") || "";
        return currentSid.toLowerCase() === targetSid.toLowerCase();
      } catch {
        return false;
      }
    }
    renderContent() {
      this.content.innerHTML = "";
      if (!MugKey.get()) {
        this.content.appendChild(
          this.placeholder("Mug targets", "Connect your Full Access key on the Mugging tab to scan targets.")
        );
        return;
      }
      if (MugTargets.onBazaarDirectory()) {
        this.renderTargets();
        return;
      }
      if (MugTargets.onItemMarket()) {
        if (MugTargets.currentItemId()) {
          this.renderBuyMug();
        } else {
          this.content.appendChild(
            this.placeholder(
              "Buy & mug",
              "Open an item to load its sellers, then check which ones are worth buying from and mugging."
            )
          );
        }
        return;
      }
      this.content.appendChild(
        this.placeholder("Mug targets", "Open the Bazaar Directory or an Item Market item to find muggable sellers.")
      );
    }
    placeholder(title, text) {
      const wrap = document.createElement("div");
      wrap.className = "tm-mh-placeholder";
      wrap.innerHTML = HELPER_ICON + `<p class="tm-mh-placeholder-title">${title}</p><p class="tm-mh-placeholder-text">${text}</p>`;
      return wrap;
    }
    renderTargets() {
      var _a;
      const bar = document.createElement("div");
      bar.className = "tm-mh-bar";
      this.scanBtn = document.createElement("button");
      this.scanBtn.type = "button";
      this.scanBtn.className = "tm-mh-scan";
      const hasLast = !!((_a = MugTargets.lastResult()) == null ? void 0 : _a.scanned);
      this.scanBtn.textContent = hasLast ? "Rescan" : "Scan bazaar targets";
      this.scanBtn.onclick = () => this.runScan(hasLast);
      bar.appendChild(this.scanBtn);
      this.content.appendChild(bar);
      this.targetsEl = document.createElement("div");
      this.targetsEl.className = "tm-mh-targets";
      this.content.appendChild(this.targetsEl);
      const last = MugTargets.lastResult();
      if (last == null ? void 0 : last.scanned) {
        this.renderResults(last);
      } else {
        this.showTargetsMessage("Scan the page to find sellers you can mug right now.");
      }
    }
    renderBuyMug() {
      var _a;
      const itemId = MugTargets.currentItemId();
      const form = document.createElement("div");
      form.className = "tm-mh-buymug";
      const itemName = ((_a = document.querySelector(".sellerRow___PaRgK img[alt]")) == null ? void 0 : _a.getAttribute("alt")) || "";
      const heading = document.createElement("div");
      heading.className = "tm-mh-item";
      heading.textContent = itemName ? `${itemName} (${itemId})` : `Item ${itemId}`;
      form.appendChild(heading);
      const priceField = document.createElement("label");
      priceField.className = "tm-mh-field";
      const priceLabel = document.createElement("span");
      priceLabel.className = "tm-mh-field-label";
      priceLabel.textContent = "Item market value";
      priceField.appendChild(priceLabel);
      const priceRow = document.createElement("div");
      priceRow.className = "tm-mh-field-row";
      this.priceInput = document.createElement("input");
      this.priceInput.type = "text";
      this.priceInput.className = "tm-mh-input";
      this.priceInput.placeholder = "e.g. 13.4m";
      const storedPrice = MugTargets.marketPrice(itemId);
      if (storedPrice) this.priceInput.value = formatMoney(storedPrice);
      this.priceInput.addEventListener("input", () => {
        const value = parseMoney(this.priceInput.value);
        if (Number.isFinite(value) && value > 0) MugTargets.setMarketPrice(itemId, value);
      });
      this.fetchPriceBtn = document.createElement("button");
      this.fetchPriceBtn.type = "button";
      this.fetchPriceBtn.className = "tm-mh-fetch";
      this.fetchPriceBtn.textContent = "Fetch";
      this.fetchPriceBtn.onclick = () => this.fetchPrice(itemId);
      priceRow.append(this.priceInput, this.fetchPriceBtn);
      priceField.appendChild(priceRow);
      const budgetField = document.createElement("label");
      budgetField.className = "tm-mh-field";
      const budgetLabel = document.createElement("span");
      budgetLabel.className = "tm-mh-field-label";
      budgetLabel.textContent = "Buy budget";
      budgetField.appendChild(budgetLabel);
      this.budgetInput = document.createElement("input");
      this.budgetInput.type = "text";
      this.budgetInput.className = "tm-mh-input";
      this.budgetInput.placeholder = "e.g. 500m";
      const budget = MugTargets.buyBudget();
      if (budget) this.budgetInput.value = formatMoney(budget);
      this.budgetInput.addEventListener("input", () => {
        const value = parseMoney(this.budgetInput.value);
        MugTargets.setBuyBudget(Number.isFinite(value) ? value : 0);
      });
      budgetField.appendChild(this.budgetInput);
      this.scanBtn = document.createElement("button");
      this.scanBtn.type = "button";
      this.scanBtn.className = "tm-mh-scan";
      this.scanBtn.textContent = "Check targets";
      this.scanBtn.onclick = () => this.runBuyMug();
      form.append(priceField, budgetField, this.scanBtn);
      this.content.appendChild(form);
      this.targetsEl = document.createElement("div");
      this.targetsEl.className = "tm-mh-targets";
      this.content.appendChild(this.targetsEl);
      this.showTargetsMessage("Set the market value and your budget, then check for targets.");
    }
    async fetchPrice(itemId) {
      var _a;
      this.fetchPriceBtn.disabled = true;
      const label = this.fetchPriceBtn.textContent;
      this.fetchPriceBtn.textContent = "...";
      MugTargets.clearMarketPrice(itemId);
      this.priceInput.value = "";
      try {
        const value = await MugTargets.fetchMarketValue(itemId);
        MugTargets.setMarketPrice(itemId, value);
        this.priceInput.value = formatMoney(value);
        showToast(`Fetched Torn's market value: ${formatMoney(value)}`);
        if ((_a = this.targetsEl) == null ? void 0 : _a.querySelector(".tm-mh-target, .tm-mh-summary")) {
          this.showTargetsMessage("Market value updated. Check targets again.");
        }
      } catch (err) {
        this.showTargetsMessage(err.message || "Could not fetch the market value.");
      } finally {
        this.fetchPriceBtn.disabled = false;
        this.fetchPriceBtn.textContent = label;
      }
    }
    async runBuyMug(force = false) {
      let marketValue = parseMoney(this.priceInput.value);
      const budget = parseMoney(this.budgetInput.value);
      if (!Number.isFinite(budget) || budget <= 0) {
        this.showTargetsMessage("Set your buy budget first.");
        return;
      }
      if (!Number.isFinite(marketValue) || marketValue <= 0) {
        const itemId = MugTargets.currentItemId();
        this.scanBtn.disabled = true;
        this.scanBtn.textContent = "Fetching value…";
        try {
          marketValue = await MugTargets.fetchMarketValue(itemId);
          MugTargets.setMarketPrice(itemId, marketValue);
          this.priceInput.value = formatMoney(marketValue);
        } catch (err) {
          this.showTargetsMessage(err.message || "Could not fetch the market value.");
          return;
        } finally {
          this.scanBtn.disabled = false;
          this.scanBtn.textContent = "Check targets";
        }
      }
      const sellers = MugTargets.collectSellers();
      if (!sellers.length) {
        this.showTargetsMessage("No named sellers found on this page.");
        return;
      }
      const mugRate = mugRateFromSettings();
      const scannedAt = Date.now();
      this.scanBtn.disabled = true;
      this.scanBtn.textContent = "Scanning…";
      this.targetsEl.innerHTML = "";
      const bar = document.createElement("div");
      bar.className = "tm-mh-progress";
      const fill = document.createElement("div");
      fill.className = "tm-mh-progress-fill";
      bar.appendChild(fill);
      const progressLabel = document.createElement("p");
      progressLabel.className = "tm-mh-progress-label";
      progressLabel.textContent = `Checking 0 / ${sellers.length}...`;
      const list = document.createElement("div");
      list.className = "tm-mh-list";
      this.targetsEl.append(bar, progressLabel, list);
      let found = 0;
      try {
        await MugTargets.scanSellers(sellers, {
          marketValue,
          budget,
          mugRate,
          force,
          onProgress: (done, total) => {
            fill.style.width = `${Math.round(done / total * 100)}%`;
            progressLabel.textContent = `Checking ${done} / ${total}...`;
          },
          onTarget: (target) => {
            found += 1;
            this.insertByProfit(list, this.targetRow(target), target.profit);
          }
        });
        bar.remove();
        progressLabel.remove();
        this.targetsEl.insertBefore(
          this.makeSummary((count) => `${count} profitable of ${sellers.length} sellers, ${ago(scannedAt)}`, found),
          list
        );
        if (!found) {
          list.appendChild(message("No profitable targets here. Try a bigger budget or a different item."));
        }
      } catch (err) {
        this.showTargetsMessage(err.message || "Could not check targets.");
      } finally {
        this.scanBtn.disabled = false;
        this.scanBtn.onclick = () => this.runBuyMug(true);
        this.scanBtn.textContent = "Recheck targets";
      }
    }
    async runScan(force) {
      const ids = MugTargets.collectUserIds();
      if (!ids.length) {
        this.showTargetsMessage("No bazaar users found on this page.");
        return;
      }
      this.scanBtn.disabled = true;
      this.scanBtn.textContent = "Scanning…";
      this.targetsEl.innerHTML = "";
      const bar = document.createElement("div");
      bar.className = "tm-mh-progress";
      const fill = document.createElement("div");
      fill.className = "tm-mh-progress-fill";
      bar.appendChild(fill);
      const label = document.createElement("p");
      label.className = "tm-mh-progress-label";
      label.textContent = `Checking 0 / ${ids.length}...`;
      const list = document.createElement("div");
      list.className = "tm-mh-list";
      this.targetsEl.append(bar, label, list);
      try {
        const result = await MugTargets.scan(ids, {
          force,
          onProgress: (done, total) => {
            fill.style.width = `${Math.round(done / total * 100)}%`;
            label.textContent = `Checking ${done} / ${total}...`;
          },
          onTarget: (target) => list.appendChild(this.targetRow(target))
        });
        bar.remove();
        label.remove();
        if (result.truncated) this.targetsEl.insertBefore(this.truncatedNote(result), list);
        this.targetsEl.insertBefore(this.summaryEl(result), this.targetsEl.firstChild);
        if (!result.targets.length) {
          list.appendChild(message("No muggable targets right now. The rest are hospitalized or in clothing stores."));
        }
      } catch (err) {
        this.showTargetsMessage(err.message || "Could not scan targets.");
      } finally {
        this.scanBtn.disabled = false;
        this.scanBtn.onclick = () => this.runScan(true);
        this.scanBtn.textContent = "Rescan";
      }
    }
    renderResults(result) {
      this.targetsEl.innerHTML = "";
      this.targetsEl.appendChild(this.summaryEl(result));
      if (result.truncated) this.targetsEl.appendChild(this.truncatedNote(result));
      if (!result.targets.length) {
        this.targetsEl.appendChild(
          message("No muggable targets right now. The rest are hospitalized or in clothing stores.")
        );
        return;
      }
      const list = document.createElement("div");
      list.className = "tm-mh-list";
      for (const target of result.targets) list.appendChild(this.targetRow(target));
      this.targetsEl.appendChild(list);
    }
    targetRow(target) {
      const item = document.createElement("div");
      item.className = "tm-mh-target";
      const info = document.createElement("div");
      info.className = "tm-mh-target-info";
      if (target.profit != null) {
        const top = document.createElement("div");
        top.className = "tm-mh-target-top";
        const name = document.createElement("span");
        name.className = "tm-mh-target-name";
        name.textContent = target.name;
        const profit = document.createElement("span");
        profit.className = "tm-mh-target-profit";
        profit.title = "Estimated net profit: mug + resale at market value − what you pay";
        profit.textContent = `est profit +${formatMoney(target.profit)}`;
        top.append(name, profit);
        info.appendChild(top);
        const sub = document.createElement("span");
        sub.className = "tm-mh-target-sub";
        sub.title = "The mug estimate only counts the cash you hand the seller — anything they already hold is extra.";
        sub.textContent = `Buy ${target.qty} at ${formatMoney(target.price)} · est mug ${formatMoney(target.estMug)}`;
        info.appendChild(sub);
        const attack = document.createElement("a");
        attack.className = "tm-mh-target-link";
        attack.href = `https://www.torn.com/loader.php?sid=attack&user2ID=${target.id}`;
        attack.target = "_blank";
        attack.rel = "noopener";
        attack.textContent = "Attack";
        info.appendChild(attack);
      } else {
        const name = document.createElement("span");
        name.className = "tm-mh-target-name";
        name.textContent = target.name;
        info.appendChild(name);
        const link2 = document.createElement("a");
        link2.className = "tm-mh-target-link";
        link2.href = `https://www.torn.com/bazaar.php?userId=${target.id}#/`;
        link2.target = "_blank";
        link2.rel = "noopener";
        link2.textContent = "Open bazaar";
        info.appendChild(link2);
      }
      item.appendChild(info);
      const remove = document.createElement("button");
      remove.type = "button";
      remove.className = "tm-mh-target-remove";
      remove.title = "Remove from this list";
      remove.textContent = "×";
      remove.onclick = () => {
        this.highlightSeller(target.id, false);
        item.remove();
        this.updateSummary();
      };
      item.appendChild(remove);
      item.addEventListener("mouseenter", () => this.highlightSeller(target.id, true));
      item.addEventListener("mouseleave", () => this.highlightSeller(target.id, false));
      return item;
    }
    // Targets stream in as the scan walks the page, so place each row where it
    // belongs instead of appending — the list stays sorted by profit throughout.
    insertByProfit(list, row, profit) {
      row.dataset.profit = profit;
      for (const existing of list.children) {
        if (Number(existing.dataset.profit) < profit) {
          list.insertBefore(row, existing);
          return;
        }
      }
      list.appendChild(row);
    }
    highlightSeller(id, on) {
      const row = this.findSellerRow(id);
      row == null ? void 0 : row.classList.toggle("tm-mh-seller-highlight", on);
    }
    findSellerRow(id) {
      const target = String(id);
      for (const anchor of document.querySelectorAll('a[href*="userId="], a[href*="XID="]')) {
        const match = /(?:userId|XID)=(\d+)/.exec(anchor.getAttribute("href") || "");
        if (match && match[1] === target) return anchor.closest("li") || anchor;
      }
      return null;
    }
    clearHighlights() {
      for (const el of document.querySelectorAll(".tm-mh-seller-highlight")) {
        el.classList.remove("tm-mh-seller-highlight");
      }
    }
    summaryEl(result) {
      return this.makeSummary(
        (count) => `${count} muggable of ${result.scanned} checked, ${ago(result.at)}`,
        result.targets.length
      );
    }
    makeSummary(template, initialCount) {
      this.summaryTemplate = template;
      const summary = document.createElement("p");
      summary.className = "tm-mh-summary";
      summary.textContent = template(initialCount);
      this.summaryElement = summary;
      return summary;
    }
    updateSummary() {
      if (!this.summaryElement || !this.summaryTemplate) return;
      const count = this.targetsEl.querySelectorAll(".tm-mh-target").length;
      this.summaryElement.textContent = this.summaryTemplate(count);
      if (count === 0 && !this.targetsEl.querySelector(".tm-mh-msg")) {
        const list = this.targetsEl.querySelector(".tm-mh-list") || this.targetsEl;
        list.appendChild(message("Nothing left in the list. Rescan to check again."));
      }
    }
    truncatedNote(result) {
      const note = document.createElement("p");
      note.className = "tm-mh-note";
      note.textContent = `Only the first ${result.scanned} of ${result.found} sellers were checked.`;
      return note;
    }
    showTargetsMessage(text) {
      this.targetsEl.innerHTML = "";
      this.targetsEl.appendChild(message(text));
    }
    applyPosition() {
      const saved = this.savedPosition();
      if (saved && typeof saved.left === "number" && typeof saved.top === "number") {
        this.moveTo(saved.left, saved.top);
        return;
      }
      this.element.style.right = "18px";
      this.element.style.bottom = "90px";
    }
    makeDraggable(header) {
      let start = null;
      let dragging = false;
      header.addEventListener("pointerdown", (e) => {
        if (e.target.closest(".tm-mh-action")) return;
        const rect = this.element.getBoundingClientRect();
        start = { x: e.clientX, y: e.clientY, left: rect.left, top: rect.top };
        dragging = false;
        header.setPointerCapture(e.pointerId);
      });
      header.addEventListener("pointermove", (e) => {
        if (!start) return;
        const dx = e.clientX - start.x;
        const dy = e.clientY - start.y;
        if (!dragging && Math.hypot(dx, dy) < DRAG_THRESHOLD_PX) return;
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
      const width = rect.width || 300;
      const height = rect.height || 340;
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
      const rect = this.element.getBoundingClientRect();
      try {
        localStorage.setItem(POS_KEY, JSON.stringify({ left: Math.round(rect.left), top: Math.round(rect.top) }));
      } catch {
        return;
      }
    }
    savedPosition() {
      try {
        const raw = localStorage.getItem(POS_KEY);
        return raw ? JSON.parse(raw) : null;
      } catch {
        return null;
      }
    }
    applySize() {
      const saved = this.savedSize();
      if (saved && saved.w && saved.h) {
        this.element.style.width = `${saved.w}px`;
        this.element.style.height = `${saved.h}px`;
      }
    }
    addResizeHandle() {
      const handle = document.createElement("div");
      handle.className = "tm-mh-resize";
      this.element.appendChild(handle);
      let start = null;
      handle.addEventListener("pointerdown", (e) => {
        e.preventDefault();
        const rect = this.element.getBoundingClientRect();
        this.moveTo(rect.left, rect.top);
        start = { x: e.clientX, y: e.clientY, w: rect.width, h: rect.height, left: rect.left, top: rect.top };
        handle.setPointerCapture(e.pointerId);
        this.element.style.zIndex = ++zCounter;
      });
      handle.addEventListener("pointermove", (e) => {
        if (!start) return;
        const maxW = window.innerWidth - start.left - 8;
        const maxH = window.innerHeight - start.top - 8;
        const width = Math.min(Math.max(start.w + (e.clientX - start.x), MIN_WIDTH), maxW);
        const height = Math.min(Math.max(start.h + (e.clientY - start.y), MIN_HEIGHT), maxH);
        this.element.style.width = `${width}px`;
        this.element.style.height = `${height}px`;
      });
      const finish = () => {
        if (!start) return;
        start = null;
        this.saveSize();
      };
      handle.addEventListener("pointerup", finish);
      handle.addEventListener("pointercancel", finish);
    }
    saveSize() {
      try {
        localStorage.setItem(
          SIZE_KEY,
          JSON.stringify({ w: Math.round(this.element.offsetWidth), h: Math.round(this.element.offsetHeight) })
        );
      } catch {
        return;
      }
    }
    savedSize() {
      try {
        const raw = localStorage.getItem(SIZE_KEY);
        return raw ? JSON.parse(raw) : null;
      } catch {
        return null;
      }
    }
  }
  function message(text) {
    const el = document.createElement("p");
    el.className = "tm-mh-msg";
    el.textContent = text;
    return el;
  }
  function ago(ts) {
    const mins = Math.floor((Date.now() - ts) / 6e4);
    if (mins <= 0) return "just now";
    if (mins === 1) return "1 minute ago";
    if (mins < 60) return `${mins} minutes ago`;
    const hours = Math.floor(mins / 60);
    return hours === 1 ? "1 hour ago" : `${hours} hours ago`;
  }
  function mugRateFromSettings() {
    let merits = 0;
    let plunder = 0;
    try {
      const raw = localStorage.getItem("tm_mug_calc");
      if (raw) {
        const calc = JSON.parse(raw);
        merits = Math.min(10, Math.max(0, Math.floor(Number(calc.merits)) || 0));
        plunder = Math.max(0, Number(calc.plunder) || 0);
      }
    } catch {
      merits = 0;
    }
    const modifier = 1 + (merits * 5 + plunder) / 100;
    return 0.05 * modifier;
  }
  const CHECK_INTERVAL_MS = 10 * 60 * 1e3;
  class UpdateGate {
    start() {
      const begin = () => {
        this.check();
        setInterval(() => this.check(), CHECK_INTERVAL_MS);
      };
      if (document.body) {
        begin();
      } else {
        window.addEventListener("DOMContentLoaded", begin, { once: true });
      }
    }
    check() {
      UpdateCheck.status().then(({ forced, latest }) => forced ? this.engage(latest) : this.disengage()).catch(() => {
      });
    }
    engage(latest) {
      document.documentElement.classList.add("tm-force-update");
      if (document.querySelector(".tm-force-update-bar")) return;
      const bar = document.createElement("div");
      bar.className = "tm-force-update-bar";
      const text = document.createElement("span");
      text.textContent = `TornManager needs updating to keep working. A required update (v${latest}) is out. You're on v${UpdateCheck.current}.`;
      const link2 = document.createElement("a");
      link2.href = DOWNLOAD_URL;
      link2.target = "_blank";
      link2.rel = "noopener";
      link2.className = "tm-force-update-link";
      link2.textContent = "Update now";
      bar.appendChild(text);
      bar.appendChild(link2);
      document.body.appendChild(bar);
    }
    disengage() {
      var _a;
      document.documentElement.classList.remove("tm-force-update");
      (_a = document.querySelector(".tm-force-update-bar")) == null ? void 0 : _a.remove();
    }
  }
  function fromAnotherUserscript(source) {
    if (!source) return false;
    const match = source.match(/userscript\.html\?name=([^&]+)/i);
    return !!match && !decodeURIComponent(match[1]).toLowerCase().includes("torn-manager");
  }
  function opaqueCrossOriginError(e) {
    var _a;
    const msg = ((_a = e.error) == null ? void 0 : _a.message) || e.message || "";
    return !e.error && !e.filename && (msg === "" || msg === "Script error.");
  }
  function boot() {
    const logger = new Logger();
    const auth = new Auth(Store);
    const api = new ApiClient(auth);
    Preferences.applyChatFontSize();
    const chatClient = new ChatClient(auth);
    const chatDock = new ChatDock(auth, chatClient, logger);
    chatDock.init();
    window.addEventListener("error", (e) => {
      var _a, _b;
      const msg = ((_a = e.error) == null ? void 0 : _a.message) || e.message || "";
      if (msg.includes("ResizeObserver")) return;
      if (opaqueCrossOriginError(e)) return;
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
    const mugHelper = new MugHelper(auth);
    mugHelper.init();
    const overlay = new Overlay(auth, api, logger, chatDock, mugHelper);
    chatDock.overlay = overlay;
    const sidebar = new Sidebar(overlay);
    sidebar.init();
    const settingsMenuEntry = new SettingsMenuEntry(overlay);
    settingsMenuEntry.init();
    const updateGate = new UpdateGate();
    updateGate.start();
  }
  if (window.self === window.top) boot();

})();