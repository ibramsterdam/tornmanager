// ==UserScript==
// @name         Torn Manager Company
// @namespace    torn-company
// @version      0.1.0
// @author       Bram [2728237]
// @description  Company insights for Torn directors
// @license      All rights reserved
// @icon         data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%2310b981'/%3E%3Ctext x='32' y='43' text-anchor='middle' font-family='Arial,Helvetica,sans-serif' font-weight='900' font-size='34' fill='white'%3EC%3C/text%3E%3C/svg%3E
// @downloadURL  https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-company.user.js
// @updateURL    https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-company.user.js
// @match        https://www.torn.com/*
// @connect      tornmanager.com
// @grant        GM.xmlHttpRequest
// @grant        GM_addStyle
// @run-at       document-start
// @noframes
// ==/UserScript==

(function() {
	"use strict";
	var s = new Set();
	var _css = async (t) => {
		if (s.has(t)) return;
		s.add(t);
		((c) => {
			if (typeof GM_addStyle === "function") GM_addStyle(c);
			else (document.head || document.documentElement).appendChild(document.createElement("style")).append(c);
		})(t);
	};
	_css(".company-icon{cursor:pointer!important;background-image:url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='6' fill='%2310b981'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='18' fill='white'%3EC%3C/text%3E%3C/svg%3E\")!important;background-position:50%!important;background-repeat:no-repeat!important;background-size:contain!important}.company-icon:before,.company-icon:after{content:none!important;display:none!important}.company-menu-item a{align-items:center;gap:8px;background-image:none!important;display:flex!important}.company-menu-icon{background-image:url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%2310b981'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='17' fill='white'%3EC%3C/text%3E%3C/svg%3E\");background-position:50%;background-repeat:no-repeat;background-size:contain;border-radius:4px;flex:none;width:16px;height:16px}.tc-backdrop{z-index:999998;pointer-events:none;background:0 0;justify-content:center;align-items:center;transition:background .25s;display:flex;position:fixed;inset:0}.tc-backdrop--visible{pointer-events:auto;background:#0009}.tc-panel{color:#fff;opacity:0;background:#1c1c1e;border:1px solid #333;border-radius:12px;flex-direction:column;width:680px;max-width:94vw;max-height:82vh;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:13px;line-height:1.45;transition:opacity .25s,transform .25s;display:flex;overflow:hidden;transform:translateY(20px)scale(.97);box-shadow:0 24px 64px #00000080}.tc-backdrop--visible .tc-panel{opacity:1;transform:translateY(0)scale(1)}.tc-head{background:#161618;border-bottom:1px solid #2e2e30;align-items:center;gap:10px;padding:12px 16px;display:flex}.tc-logo{background:#10b981;border-radius:6px;justify-content:center;align-items:center;width:22px;height:22px;font-size:12px;font-weight:800;display:inline-flex}.tc-head-title{font-size:14.5px;font-weight:700}.tc-head-sub{color:#6a6a70;font-size:11px}.tc-nav{gap:2px;margin-left:auto;display:flex}.tc-nav-link{color:#9a9aa2;cursor:pointer;background:0 0;border:none;border-radius:7px;padding:6px 11px;font-size:12.5px;font-weight:600}.tc-nav-link:hover{color:#d6d6db}.tc-nav-link--active{color:#fff;background:#10b981}.tc-nav-link--icon{align-items:center;padding:6px 8px;display:inline-flex}.tc-nav-link--icon svg{display:block}.tc-close{color:#888;cursor:pointer;background:0 0;border:none;border-radius:4px;padding:2px 8px;font-size:20px;line-height:1}.tc-close:hover{color:#fff;background:#ffffff1a}.tc-body{scrollbar-width:thin;scrollbar-color:#3a3a3e transparent;padding:16px 18px 18px;overflow-y:auto}.tc-card{background:#161618;border:1px solid #303032;border-radius:10px;padding:13px 14px}.tc-card+.tc-card{margin-top:12px}.tc-label{text-transform:uppercase;letter-spacing:.05em;color:#8a8a92;margin-bottom:6px;font-size:11px;font-weight:600}.tc-row{align-items:flex-end;gap:10px;display:flex}.tc-row--filters{margin-top:14px}.tc-field{flex:1;min-width:0}.tc-input{color:#fff;box-sizing:border-box;--lightningcss-light: ;--lightningcss-dark:initial;color-scheme:dark;background:#111;border:1px solid #333;border-radius:9px;outline:none;width:100%;padding:8px 11px;font-size:13px}.tc-input:focus{border-color:#10b981}.tc-btn{color:#fff;white-space:nowrap;cursor:pointer;background:#10b981;border:none;border-radius:8px;padding:8px 14px;font-size:12.5px;font-weight:600}.tc-btn:disabled{opacity:.6;cursor:default}.tc-btn--ghost{color:#d6d6db;background:0 0;border:1px solid #333}.tc-feedback{min-height:16px;margin-top:8px;font-size:12px}.tc-feedback--ok{color:#5cb85c}.tc-feedback--error{color:#e05252}.tc-list{flex-direction:column;gap:8px;margin-top:12px;display:flex}.tc-list-row{background:#161618;border:1px solid #303032;border-radius:10px;grid-template-columns:68px 110px 1fr auto auto;align-items:center;gap:12px;padding:10px 14px;display:grid}.tc-mono{color:#d6d6db;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12px}.tc-dim{color:#6a6a70;white-space:nowrap;text-overflow:ellipsis;font-size:11.5px;overflow:hidden}.tc-badge{white-space:nowrap;border-radius:6px;justify-self:start;align-items:center;gap:6px;padding:3px 10px;font-size:11px;font-weight:600;display:inline-flex}.tc-badge:before{content:\"\";background:currentColor;border-radius:50%;width:6px;height:6px}.tc-badge--fresh{color:#5cb85c;background:#1c2f1f}.tc-badge--aging{color:#e8a33d;background:#33290f}.tc-badge--stale{color:#e05252;background:#351d1d}.tc-scope{color:#bbf7d0;background:#0d2a20;border:1px solid #16503b;border-radius:10px;margin-top:12px;padding:11px 14px;font-size:12.5px}.tc-syncs{flex-direction:column;gap:8px;display:flex}.tc-sync{background:#161618;border:1px solid #303032;border-radius:10px;grid-template-columns:108px 1fr auto auto;align-items:center;gap:12px;padding:10px 14px;display:grid}.tc-sync-name{font-size:12.5px;font-weight:700}.tc-progress{color:#9a9aa2;min-height:16px;margin-top:10px;font-size:12px}.tc-meta{color:#9a9aa2;justify-content:space-between;align-items:center;margin:12px 2px 8px;font-size:11.5px;display:flex}.tc-table{border:1px solid #303032;border-radius:10px;overflow:hidden}.tc-thead,.tc-trow{grid-template-columns:1.25fr .85fr .95fr 1.35fr 40px;align-items:center;gap:10px;padding:9px 13px;display:grid}.tc-thead{text-transform:uppercase;letter-spacing:.05em;color:#8a8a92;background:#161618;border-bottom:1px solid #303032;font-size:10.5px;font-weight:700}.tc-trow{border-bottom:1px solid #242426}.tc-trow:last-child{border-bottom:none}.tc-name{color:#fff;white-space:nowrap;text-overflow:ellipsis;font-size:13px;font-weight:600;overflow:hidden}.tc-name--co{font-size:12.5px}.tc-star{color:#e8b93d;font-size:11px}.tc-ws{font-variant-numeric:tabular-nums;font-size:13.5px;font-weight:700}.tc-ws small{color:#6a6a70;font-size:10.5px;font-weight:500;display:block}.tc-state{color:#d6d6db;white-space:nowrap;align-items:center;gap:7px;font-size:12px;display:flex}.tc-dot{border-radius:50%;flex:none;width:8px;height:8px}.tc-dot--on{background:#5cb85c;box-shadow:0 0 6px #5cb85c99}.tc-dot--idle{background:#e8a33d}.tc-dot--off{background:#55555c}.tc-acts{justify-content:flex-end;gap:4px;display:flex}.tc-act{color:#9a9aa2;cursor:pointer;background:0 0;border:1px solid #333;border-radius:6px;justify-content:center;align-items:center;width:22px;height:22px;font-size:11px;text-decoration:none;display:inline-flex}.tc-act:hover{color:#fff;border-color:#555}.tc-empty{text-align:center;color:#6a6a70;padding:26px 20px;font-size:12.5px}.tc-chips{flex-wrap:wrap;gap:7px;display:flex}.tc-chip{color:#9a9aa2;cursor:pointer;background:#111;border:1px solid #333;border-radius:8px;padding:5px 11px;font-size:12px}.tc-chip--on{color:#fff;background:#0d2a20;border-color:#10b981}.tc-footer-row{align-items:center;gap:10px;margin-top:14px;display:flex}.tc-auth{flex-direction:column;align-items:center;gap:16px;display:flex}.tc-auth-banner{width:100%;max-width:480px}.tc-auth-banner svg{border-radius:10px;width:100%;height:auto;display:block}.tc-auth-form{flex-direction:column;gap:8px;width:100%;max-width:480px;margin-top:8px;display:flex}.tc-auth-row{align-items:stretch;gap:10px;display:flex}.tc-auth-input{color:#fff;box-sizing:border-box;background:#111;border:1px solid #333;border-radius:8px;outline:none;flex:1;min-width:0;padding:10px 14px;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:14px;transition:border-color .15s}.tc-auth-input:focus{border-color:#10b981}.tc-auth-button{white-space:nowrap;color:#fff;cursor:pointer;background:#10b981;border:none;border-radius:8px;flex:none;padding:10px 22px;font-size:14px;font-weight:600;transition:background .15s}.tc-auth-button:hover{background:#059669}.tc-auth-button:disabled{cursor:not-allowed;color:#666;background:#333}.tc-auth-error{color:#e53935;text-align:center;min-height:18px;margin:0;font-size:13px}.tc-auth-hint{color:#777;text-align:center;margin:0;font-size:12px;line-height:1.5}.tc-auth-hint strong{color:#aaa}.tc-auth-hint a,.tc-tos-agree a,.tc-sub-info a{color:#10b981;text-decoration:none}.tc-auth-hint a:hover,.tc-tos-agree a:hover,.tc-sub-info a:hover{text-decoration:underline}.tc-tos{text-align:left;background:#141416;border:1px solid #2a2a2c;border-radius:10px;margin-top:4px;padding:12px 14px}.tc-tos-heading{text-transform:uppercase;letter-spacing:.06em;color:#8a8a92;margin:0 0 12px;font-size:11px;font-weight:700}.tc-tos-grid{grid-template-columns:1fr 1fr;gap:12px 20px;display:grid}.tc-tos-item{flex-direction:column;gap:3px;font-size:12px;line-height:1.45;display:flex}.tc-tos-label{text-transform:uppercase;letter-spacing:.06em;color:#6a6a70;font-size:10px;font-weight:700}.tc-tos-value{color:#d6d6db}.tc-tos-agree{color:#9a9aa2;cursor:pointer;align-items:flex-start;gap:8px;margin-top:10px;font-size:12px;display:flex}.tc-tos-agree input{accent-color:#10b981;margin:2px 0 0}.tc-sub{text-align:center;flex-direction:column;align-items:center;gap:14px;padding:4px 8px 0;display:flex}.tc-sub-title{color:#fff;align-self:flex-start;margin:0;font-size:19px;font-weight:700}.tc-sub-note{color:#bbf7d0;background:#0d2a20;border:1px solid #16503b;border-radius:10px;margin:0;padding:12px 16px;font-size:12.5px;line-height:1.5}.tc-sub-status{text-transform:uppercase;letter-spacing:.04em;color:#8a8a92;font-size:13px;font-weight:700}.tc-sub-status--active{color:#5cb85c}.tc-sub-status--inactive{color:#9a9aa2}.tc-sub-status--warn{color:#e8a33d}.tc-sub-status--error{color:#e05252}.tc-sub-countdown{color:#fff;margin:-6px 0 0;font-size:21px;font-weight:800}.tc-sub-refresh{color:#d6d6db;cursor:pointer;background:0 0;border:1px solid #333;border-radius:8px;padding:8px 16px;font-size:12.5px;font-weight:600}.tc-sub-refresh:hover{border-color:#555}.tc-sub-refresh:disabled{opacity:.6;cursor:default}.tc-sub-info{color:#6a6a70;border-top:1px solid #2e2e30;width:100%;padding-top:14px;font-size:12px;line-height:1.6}.tc-sub-info strong{color:#d6d6db}.tc-actions-row{justify-content:center;gap:10px;margin-top:4px;display:flex}.tc-btn-danger{color:#e05252;cursor:pointer;background:0 0;border:1px solid #5a2626;border-radius:8px;padding:8px 16px;font-size:12.5px;font-weight:600}.tc-btn-danger:hover{border-color:#e05252}.tc-footer{background:#1c1c1e;border-top:1px solid #2e2e30;padding:12px 18px 14px}.tc-footer-links{color:#6a6a70;flex-wrap:wrap;justify-content:center;align-items:center;gap:8px;font-size:12px;display:flex}.tc-footer-links a,.tc-footer-link{color:#9a9aa2;cursor:pointer;background:0 0;border:none;padding:0;font-size:12px;text-decoration:none}.tc-footer-links a:hover,.tc-footer-link:hover{color:#fff}.tc-footer-links a.tc-footer-user{color:#34d399}.tc-footer-version{text-align:center;color:#55555c;margin-top:5px;font-size:11px}.tc-hint{color:#6a6a70;margin-top:10px;font-size:11.5px;line-height:1.5}.tc-stepper{align-items:center;gap:6px;display:flex}.tc-stepper-btn{color:#d6d6db;cursor:pointer;background:#111;border:1px solid #333;border-radius:9px;justify-content:center;align-items:center;width:30px;height:32px;font-size:15px;line-height:1;display:inline-flex}.tc-stepper-btn:hover:not(:disabled){color:#fff;border-color:#555}.tc-stepper-btn:disabled{opacity:.4;cursor:default}.tc-stepper-value{text-align:center;font-variant-numeric:tabular-nums;color:#fff;min-width:34px;font-size:13.5px;font-weight:700}.tc-bar{background:#111;border:1px solid #303032;border-radius:9px;height:28px;margin-top:10px;position:relative;overflow:hidden}.tc-bar-fill{background:linear-gradient(90deg,#059669,#10b981);border-radius:8px;width:0%;transition:width .6s;position:absolute;top:0;bottom:0;left:0;overflow:hidden}.tc-bar-fill:after{content:\"\";background:linear-gradient(90deg,#0000,#fff3,#0000);animation:1.8s infinite tc-shimmer;position:absolute;inset:0;transform:translate(-100%)}.tc-bar--indeterminate .tc-bar-fill{width:30%;transition:none;animation:1.6s linear infinite tc-indet}.tc-bar-text{z-index:1;font-variant-numeric:tabular-nums;color:#fff;text-shadow:0 1px 2px #0009;white-space:nowrap;text-overflow:ellipsis;justify-content:center;align-items:center;height:100%;padding:0 12px;font-size:11.5px;font-weight:600;display:flex;position:relative;overflow:hidden}@keyframes tc-shimmer{to{transform:translate(100%)}}@keyframes tc-indet{0%{transform:translate(-100%)}to{transform:translate(433%)}}@media (prefers-reduced-motion:reduce){.tc-bar-fill:after,.tc-bar--indeterminate .tc-bar-fill{animation:none}}.tc-subcard{margin-top:12px}.tc-subcard-row{align-items:center;gap:12px;display:flex}.tc-subcard-count{font-variant-numeric:tabular-nums;color:#fff;flex:1;font-size:13px;font-weight:700}.tc-link{text-decoration:none;display:block}a.tc-link:hover{color:#34d399;text-decoration:underline}.tc-pager{justify-content:center;align-items:center;gap:14px;margin-top:12px;display:flex}.tc-act svg{display:block}.tc-field--chip{flex:none}.tc-chip--filter{box-sizing:border-box;justify-content:center;align-items:center;min-width:110px;height:38px;padding:0 14px;font-weight:600;display:inline-flex}.tc-storage{text-align:left;margin-top:16px}.tc-storage-head{color:#777;margin-bottom:8px;font-size:11.5px}.tc-storage-empty{color:#888;font-size:12.5px}.tc-storage-item{background:#161618;border:1px solid #2a2a2c;border-radius:8px;margin-bottom:6px}.tc-storage-summary{cursor:pointer;align-items:center;gap:10px;padding:8px 12px;list-style:none;display:flex}.tc-storage-summary::-webkit-details-marker{display:none}.tc-storage-key{text-overflow:ellipsis;white-space:nowrap;color:#d6d6d9;flex:1;min-width:0;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;overflow:hidden}.tc-storage-size{color:#777;font-variant-numeric:tabular-nums;flex:none;font-size:11px}.tc-storage-delete{color:#e05650;cursor:pointer;background:0 0;border:1px solid #3a2a2a;border-radius:6px;flex:none;padding:3px 10px;font-size:11px;font-weight:600}.tc-storage-delete:hover{background:#e539351f;border-color:#e53935}.tc-storage-value{color:#9a9aa2;white-space:pre-wrap;word-break:break-all;scrollbar-width:thin;scrollbar-color:#3a3a3e transparent;border-top:1px solid #2a2a2c;max-height:260px;margin:0;padding:10px 12px;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:11px;line-height:1.5;overflow-y:auto}.tc-chip{transition:background .16s,border-color .16s,color .16s,transform .1s}.tc-chip:active{transform:scale(.95)}.tc-filters{opacity:0;border-width:0;max-height:0;margin-top:0;padding-top:0;padding-bottom:0;transition:max-height .28s,opacity .22s,padding .28s,margin .28s;overflow:hidden}.tc-filters--open{opacity:1;border-width:1px;max-height:620px;margin-top:12px;padding-top:13px;padding-bottom:14px}.tc-filters-stars{align-items:flex-end;margin-top:14px}.tc-filters-hint{flex:2}.tc-meta-right{align-items:center;gap:10px;display:inline-flex}.tc-btn--sm{padding:5px 10px;font-size:11.5px}.tc-co-head{justify-content:space-between;align-items:center;gap:12px;margin-bottom:12px;display:flex}.tc-co-title{min-width:0}.tc-co-name{color:#fff;font-size:16px;font-weight:700;text-decoration:none}.tc-co-name:hover{color:#34d399}.tc-kpis{grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;margin-bottom:12px;display:grid}.tc-kpi{background:#161618;border:1px solid #303032;border-radius:10px;min-width:0;padding:10px 12px}.tc-kpi--bad .tc-kpi-value{color:#e05252}.tc-kpi-label{text-transform:uppercase;letter-spacing:.05em;color:#8a8a92;font-size:10.5px;font-weight:600}.tc-kpi-value{color:#fff;font-variant-numeric:tabular-nums;margin-top:4px;font-size:18px;font-weight:700}.tc-kpi-sub{color:#6a6a70;white-space:nowrap;text-overflow:ellipsis;margin-top:2px;font-size:11px;overflow:hidden}.tc-rank-row{grid-template-columns:repeat(4,minmax(0,1fr));gap:8px;display:grid}.tc-rank-value{font-variant-numeric:tabular-nums;margin-top:3px;font-size:14px;font-weight:700}.tc-meter{background:#232326;border-radius:3px;height:6px;margin-top:12px;position:relative}.tc-meter-fill{background:#10b981;border-radius:3px;height:100%}.tc-meter-mark{background:#d6d6db;width:2px;height:12px;position:absolute;top:-3px}.tc-status{margin:12px 0}.tc-status .tc-chip,.tc-emp-parts .tc-chip{cursor:default}.tc-chip--bad{color:#e05252;border-color:#5a2626}.tc-advice{flex-direction:column;gap:8px;display:flex}.tc-advice-item{background:#1c1c1e;border-left:3px solid #55555c;border-radius:0 8px 8px 0;padding:9px 12px}.tc-advice-item--warning{border-left-color:#e8a33d}.tc-advice-item--tip{border-left-color:#60a5fa}.tc-advice-item--good{border-left-color:#10b981}.tc-advice-title{font-size:13px;font-weight:600}.tc-advice-detail{color:#9a9aa2;margin-top:2px;font-size:12px;line-height:1.5}.tc-charts{margin-top:12px}.tc-chart-head{justify-content:space-between;align-items:baseline;gap:10px;display:flex}.tc-chart-readout{text-align:right;white-space:normal}.tc-chart-svg{width:100%;height:auto;display:block}.tc-chart-grid{stroke:#2a2a2c;stroke-width:1px}.tc-chart-axis{fill:#6a6a70;font-family:inherit;font-size:10px}.tc-chart-line{fill:none;stroke-width:2px;stroke-linejoin:round;stroke-linecap:round}.tc-chart-line--dashed{stroke-width:1.5px;stroke-dasharray:4 3}.tc-chart-cursor{stroke:#55555c;stroke-width:1px}.tc-chart-legend{color:#9a9aa2;flex-wrap:wrap;gap:12px;margin-top:4px;font-size:11px;display:flex}.tc-chart-key{align-items:center;gap:5px;display:inline-flex}.tc-chart-swatch{border-radius:2px;width:10px;height:3px}.tc-chart-empty{text-align:center;padding:18px 0}.tc-positions{grid-template-columns:repeat(2,minmax(0,1fr));gap:6px 14px;display:grid}.tc-position{align-items:baseline;gap:8px;font-size:12.5px;display:flex}.tc-position--empty{color:#e8a33d}.tc-position-count{font-variant-numeric:tabular-nums;min-width:18px;font-weight:700}.tc-emp{border-top:1px solid #2a2a2c}.tc-emp-summary{cursor:pointer;grid-template-columns:minmax(0,1.4fr) minmax(0,1.4fr) auto;align-items:center;gap:10px;padding:9px 0;list-style:none;display:grid}.tc-emp-summary::-webkit-details-marker{display:none}.tc-emp-who{min-width:0}.tc-flags{flex-wrap:wrap;gap:4px;display:flex}.tc-flag{white-space:nowrap;border-radius:5px;padding:2px 7px;font-size:10.5px;font-weight:600}.tc-flag--bad{color:#e05252;background:#351d1d}.tc-flag--warn{color:#e8a33d;background:#33290f}.tc-flag--info{color:#9a9aa2;background:#242426}.tc-emp-numbers{text-align:right}.tc-emp-eff{font-variant-numeric:tabular-nums;font-weight:700}.tc-emp-details{padding:0 0 12px}.tc-emp-stats{grid-template-columns:repeat(3,minmax(0,1fr));gap:8px;margin-bottom:8px;display:grid}.tc-emp-stat{background:#1c1c1e;border-radius:7px;padding:7px 9px;font-size:12.5px}.tc-emp-stat--low{box-shadow:inset 0 0 0 1px #e8a33d}.tc-emp-parts{flex-wrap:wrap;gap:5px;margin-bottom:6px;display:flex}.tc-tbl{border-collapse:collapse;font-variant-numeric:tabular-nums;width:100%;font-size:12px}.tc-tbl th{text-align:left;text-transform:uppercase;letter-spacing:.04em;color:#8a8a92;padding:0 8px 6px 0;font-size:10.5px;font-weight:600}.tc-tbl td{border-top:1px solid #2a2a2c;padding:6px 8px 6px 0}.tc-bad{color:#e05252;font-weight:700}.tc-news-item{border-top:1px solid #2a2a2c;padding:8px 0;font-size:12.5px;line-height:1.5}.tc-news-item:first-child{border-top:none}@media (width<=560px){.tc-kpis,.tc-rank-row{grid-template-columns:repeat(2,minmax(0,1fr))}.tc-emp-summary{grid-template-columns:minmax(0,1fr) auto}.tc-flags{order:3;grid-column:1/-1}}");
	var API_BASE = "https://tornmanager.com";
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
					if (response.status >= 200 && response.status < 300) resolve(data);
					else {
						const error = new Error(data?.error || "Request failed");
						error.status = response.status;
						error.data = data;
						if (response.status === 429) error.rateLimited = true;
						if (data?.suspended) error.suspended = true;
						reject(error);
					}
				},
				onerror() {
					reject(new Error("Network error. Could not reach Tornmanager."));
				}
			});
		});
	}
	var Auth = class {
		constructor(store) {
			this.store = store;
		}
		getUser() {
			return this.store.get("user");
		}
		getToken() {
			return this.getUser()?.token || null;
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
				this.store.set("user", {
					...data.user,
					token: data.token
				});
				return data.user;
			});
		}
		fetchSubscription({ refresh = false } = {}) {
			const token = this.getToken();
			if (!token) return Promise.reject(new Error("Not signed in"));
			const body = {};
			if (refresh) body.refresh = true;
			return post("/api/subscription", body, { token }).then((data) => {
				const subscription = {
					...data.subscription,
					checkedAt: Date.now()
				};
				this.store.set("subscription", subscription);
				return subscription;
			});
		}
		subscription() {
			return this.store.get("subscription");
		}
		isSubscribed() {
			const sub = this.subscription();
			if (!sub?.active) return false;
			return !sub.expires_at || new Date(sub.expires_at) > new Date();
		}
	};
	var CompanyAuth = class extends Auth {
		authenticate(apiKey) {
			return post("/api/company/session", { api_key: apiKey }).then((data) => {
				this.store.set("user", {
					...data.user,
					token: data.token
				});
				this.store.set("company", data.company);
				return data;
			});
		}
		company() {
			return this.store.get("company");
		}
		clear() {
			super.clear();
			this.store.remove("company");
		}
	};
	var OVERVIEW_TTL_MS = 6e4;
	var CompanyApi = class {
		constructor(auth) {
			this.auth = auth;
			this.cached = null;
		}
		overview({ fresh = false } = {}) {
			if (!fresh && this.cached && Date.now() - this.cached.at < OVERVIEW_TTL_MS) return this.cached.promise;
			const promise = this.post("/api/company/overview").catch((error) => {
				this.cached = null;
				throw error;
			});
			this.cached = {
				at: Date.now(),
				promise
			};
			return promise;
		}
		history(days) {
			return this.post("/api/company/history", { days });
		}
		news() {
			return this.post("/api/company/news");
		}
		refresh() {
			this.cached = null;
			return this.post("/api/company/refresh");
		}
		revokeKey() {
			this.cached = null;
			return this.post("/api/company/revoke_key");
		}
		post(path, body = {}) {
			const token = this.auth.getToken();
			if (!token) return Promise.reject(Object.assign(new Error("Not signed in"), { reauth: true }));
			return post(path, body, { token }).catch((error) => {
				if (error.status === 401) error.reauth = true;
				if (error.data?.subscription_required) error.subscriptionRequired = true;
				throw error;
			});
		}
	};
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
	var Store = createStore("tc_");
	var Dom = class {
		static ready(selector, callback) {
			const el = document.querySelector(selector);
			if (el) return callback(el);
			new MutationObserver((_, observer) => {
				const el = document.querySelector(selector);
				if (el) {
					observer.disconnect();
					callback(el);
				}
			}).observe(document.documentElement, {
				childList: true,
				subtree: true
			});
		}
		static el(tag, className, text) {
			const node = document.createElement(tag);
			if (className) node.className = className;
			if (text !== void 0) node.textContent = text;
			return node;
		}
	};
	var COG_ICON = "<svg width=\"15\" height=\"15\" viewBox=\"0 0 24 24\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\"><circle cx=\"12\" cy=\"12\" r=\"3\"/><path d=\"M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z\"/></svg>";
	var SUBSCRIPTION_RECHECK_MS = 216e5;
	var Overlay = class {
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
			this.backdrop = Dom.el("div", "tc-backdrop");
			this.backdrop.addEventListener("click", (e) => {
				if (e.target === this.backdrop) this.close();
			});
			this.panel = Dom.el("div", "tc-panel");
			const head = Dom.el("div", "tc-head");
			const logo = Dom.el("span", "tc-logo", "C");
			const title = Dom.el("div", "tc-head-text");
			title.append(Dom.el("div", "tc-head-title", "Company"), this.subtitle = Dom.el("div", "tc-head-sub", ""));
			this.nav = Dom.el("div", "tc-nav");
			for (const [name, label] of [
				["overview", "Overview"],
				["charts", "Charts"],
				["staff", "Staff"],
				["stock", "Stock"],
				["news", "News"]
			]) {
				const link = Dom.el("button", "tc-nav-link", label);
				link.dataset.screen = name;
				link.addEventListener("click", () => this.show(name));
				this.nav.appendChild(link);
			}
			const gear = Dom.el("button", "tc-nav-link tc-nav-link--icon");
			gear.dataset.screen = "settings";
			gear.title = "Settings";
			gear.innerHTML = COG_ICON;
			gear.addEventListener("click", () => this.show("settings"));
			this.nav.appendChild(gear);
			const close = Dom.el("button", "tc-close", "×");
			close.addEventListener("click", () => this.close());
			head.append(logo, title, this.nav, close);
			this.body = Dom.el("div", "tc-body");
			this.footer = Dom.el("div", "tc-footer");
			this.panel.append(head, this.body, this.footer);
			this.backdrop.appendChild(this.panel);
			document.body.appendChild(this.backdrop);
		}
		renderFooter() {
			this.footer.replaceChildren();
			const links = Dom.el("div", "tc-footer-links");
			const user = this.auth.getUser();
			if (user) {
				const profile = Dom.el("a", "tc-footer-user", `${user.name} [${user.torn_id}]`);
				profile.href = `https://www.torn.com/profiles.php?XID=${user.torn_id}`;
				profile.target = "_blank";
				profile.rel = "noopener";
				links.append(profile, Dom.el("span", null, "·"));
			}
			const privacy = Dom.el("a", "tc-footer-link", "Privacy Policy");
			privacy.href = "https://tornmanager.com/legal#company-privacy-policy";
			privacy.target = "_blank";
			privacy.rel = "noopener";
			const terms = Dom.el("a", "tc-footer-link", "Terms of Service");
			terms.href = "https://tornmanager.com/legal#company-terms-of-service";
			terms.target = "_blank";
			terms.rel = "noopener";
			const debug = Dom.el("button", "tc-footer-link", "Copy debug info");
			debug.addEventListener("click", () => this.copyDebugInfo(debug));
			links.append(privacy, Dom.el("span", null, "·"), terms, Dom.el("span", null, "·"), debug);
			this.footer.appendChild(links);
			this.footer.appendChild(Dom.el("div", "tc-footer-version", `v0.1.0`));
		}
		copyDebugInfo(button) {
			const info = {
				version: "0.1.0",
				generatedAt: new Date().toISOString(),
				user: this.auth.getUser() ? {
					name: this.auth.getUser().name,
					tornId: this.auth.getUser().torn_id
				} : null,
				subscribed: this.auth.isSubscribed(),
				company: this.auth.company(),
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
			this.mount();
			const gate = this.gateScreen();
			if (gate) name = gate;
			this.current = name;
			this.nav.style.display = gate ? "none" : "flex";
			this.nav.querySelectorAll(".tc-nav-link").forEach((link) => {
				link.classList.toggle("tc-nav-link--active", link.dataset.screen === name);
			});
			const screen = this.screens[name];
			this.subtitle.textContent = screen.subtitle?.() || "";
			this.body.replaceChildren();
			screen.render(this.body);
			this.renderFooter();
		}
		open(name = null) {
			this.mount();
			this.backdrop.classList.add("tc-backdrop--visible");
			this.show(name || this.defaultScreen());
			this.recheckSubscription();
		}
		recheckSubscription() {
			if (this.gateScreen()) return;
			const checkedAt = this.auth.subscription()?.checkedAt || 0;
			if (Date.now() - checkedAt < SUBSCRIPTION_RECHECK_MS) return;
			this.auth.fetchSubscription().then(() => {
				if (this.gateScreen()) this.open();
			}).catch(() => null);
		}
		close() {
			this.backdrop?.classList.remove("tc-backdrop--visible");
		}
		toggle() {
			this.mount();
			if (this.backdrop.classList.contains("tc-backdrop--visible")) this.close();
			else this.open();
		}
		defaultScreen() {
			return "overview";
		}
		handleError(error, container) {
			if (error.reauth) {
				this.auth.clear();
				this.show("auth");
				return;
			}
			if (error.subscriptionRequired) {
				this.auth.store.set("subscription", {
					active: false,
					checkedAt: Date.now()
				});
				this.show(this.current);
				return;
			}
			container.replaceChildren(Dom.el("div", "tc-empty", error.message));
		}
		refresh() {
			if (this.current && this.backdrop?.classList.contains("tc-backdrop--visible")) this.show(this.current);
		}
	};
	var Sidebar = class {
		constructor(overlay) {
			this.overlay = overlay;
		}
		init() {
			Dom.ready("#sidebar", (sidebar) => this.onReady(sidebar));
		}
		onReady(sidebar) {
			const icons = sidebar.querySelector("ul[class^='status-icon']");
			if (!icons || document.getElementById("company-icon")) return;
			const icon = document.createElement("li");
			icon.id = "company-icon";
			icon.className = "company-icon";
			icon.onclick = () => this.overlay.toggle();
			icons.appendChild(icon);
		}
	};
	var MenuEntry = class {
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
			if (menu.querySelector(".company-menu-item")) return;
			const item = document.createElement("li");
			item.className = "link company-menu-item";
			const link = document.createElement("a");
			link.href = window.location.href;
			link.innerHTML = "<span class=\"company-menu-icon\"></span><span>Company</span>";
			link.addEventListener("click", (e) => {
				e.preventDefault();
				this.overlay.open();
			});
			item.appendChild(link);
			const serverInfo = menu.querySelector(".server-info");
			if (serverInfo) menu.insertBefore(item, serverInfo);
			else menu.appendChild(item);
		}
	};
	var company_banner_default = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 480 180\" role=\"img\" aria-label=\"Company income growing\">\n  <style>\n    .cb-wall { fill: #2c2c30; }\n    .cb-roof { fill: #3a3a3e; }\n    .cb-win { fill: #3f3f45; }\n    .cb-bar { fill: #3f3f45; transform-box: fill-box; transform-origin: bottom; animation: cb-grow 10s ease-out infinite; }\n    .cb-bar--top { fill: #10b981; }\n    .cb-b2 { animation-delay: 0.3s; }\n    .cb-b3 { animation-delay: 0.6s; }\n    .cb-b4 { animation-delay: 0.9s; }\n    .cb-b5 { animation-delay: 1.2s; }\n    .cb-b6 { animation-delay: 1.5s; }\n    .cb-line { fill: none; stroke: #34d399; stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round; stroke-dasharray: 260; stroke-dashoffset: 260; animation: cb-draw 10s ease-in-out infinite; }\n    .cb-dot { fill: #34d399; opacity: 0; animation: cb-dot 10s linear infinite; }\n    .cb-coin { opacity: 0; transform-box: fill-box; transform-origin: center; animation: cb-coin 10s ease-out infinite; }\n    .cb-w1 { animation: cb-lit 10s steps(1) infinite; }\n    .cb-w2 { animation: cb-lit 10s steps(1) infinite; animation-delay: 0.8s; }\n    .cb-w3 { animation: cb-lit 10s steps(1) infinite; animation-delay: 1.6s; }\n    .cb-w4 { animation: cb-lit 10s steps(1) infinite; animation-delay: 2.4s; }\n    .cb-w5 { animation: cb-lit 10s steps(1) infinite; animation-delay: 3.2s; }\n    .cb-w6 { animation: cb-lit 10s steps(1) infinite; animation-delay: 4s; }\n\n    @keyframes cb-grow {\n      0% { transform: scaleY(0); }\n      10%, 86% { transform: scaleY(1); }\n      94%, 100% { transform: scaleY(0); }\n    }\n    @keyframes cb-draw {\n      0%, 22% { stroke-dashoffset: 260; opacity: 1; }\n      42%, 86% { stroke-dashoffset: 0; opacity: 1; }\n      94%, 100% { stroke-dashoffset: 0; opacity: 0; }\n    }\n    @keyframes cb-dot {\n      0%, 41% { opacity: 0; }\n      43%, 86% { opacity: 1; }\n      92%, 100% { opacity: 0; }\n    }\n    @keyframes cb-coin {\n      0%, 43% { opacity: 0; transform: translateY(8px) scale(0.4); }\n      48% { opacity: 1; transform: translateY(0) scale(1.15); }\n      52%, 84% { opacity: 1; transform: translateY(0) scale(1); }\n      92%, 100% { opacity: 0; transform: translateY(-6px) scale(0.8); }\n    }\n    @keyframes cb-lit {\n      0% { fill: #3f3f45; }\n      8% { fill: #6ee7b7; }\n      70% { fill: #3f3f45; }\n    }\n\n    @media (prefers-reduced-motion: reduce) {\n      .cb-bar, .cb-line, .cb-dot, .cb-coin,\n      .cb-w1, .cb-w2, .cb-w3, .cb-w4, .cb-w5, .cb-w6 { animation: none; }\n      .cb-bar { transform: none; }\n      .cb-line { stroke-dashoffset: 0; }\n      .cb-dot, .cb-coin { opacity: 1; }\n      .cb-w2, .cb-w5 { fill: #6ee7b7; }\n    }\n  </style>\n\n  <rect x=\"0.5\" y=\"0.5\" width=\"479\" height=\"179\" rx=\"10\" fill=\"#141416\" stroke=\"#2a2a2c\"/>\n\n  <rect x=\"20\" y=\"18\" width=\"16\" height=\"16\" rx=\"4\" fill=\"#10b981\"/>\n  <text x=\"28\" y=\"30.5\" text-anchor=\"middle\" font-family=\"Arial, Helvetica, sans-serif\" font-weight=\"900\" font-size=\"11\" fill=\"#ffffff\">C</text>\n  <text x=\"46\" y=\"30.5\" font-family=\"Arial, Helvetica, sans-serif\" font-weight=\"700\" font-size=\"11\" letter-spacing=\"3.5\" fill=\"#9a9aa2\">COMPANY</text>\n\n  <line x1=\"30\" y1=\"150.5\" x2=\"450\" y2=\"150.5\" stroke=\"#2a2a2c\" stroke-width=\"1\"/>\n\n  <path class=\"cb-roof\" d=\"M44 76l52-22l52 22z\"/>\n  <rect class=\"cb-wall\" x=\"50\" y=\"76\" width=\"92\" height=\"74\" rx=\"2\"/>\n  <rect class=\"cb-win cb-w1\" x=\"60\" y=\"86\" width=\"16\" height=\"12\" rx=\"2\"/>\n  <rect class=\"cb-win cb-w4\" x=\"88\" y=\"86\" width=\"16\" height=\"12\" rx=\"2\"/>\n  <rect class=\"cb-win cb-w2\" x=\"116\" y=\"86\" width=\"16\" height=\"12\" rx=\"2\"/>\n  <rect class=\"cb-win cb-w5\" x=\"60\" y=\"106\" width=\"16\" height=\"12\" rx=\"2\"/>\n  <rect class=\"cb-win cb-w3\" x=\"116\" y=\"106\" width=\"16\" height=\"12\" rx=\"2\"/>\n  <rect class=\"cb-win cb-w6\" x=\"60\" y=\"126\" width=\"16\" height=\"12\" rx=\"2\"/>\n  <rect class=\"cb-win\" x=\"116\" y=\"126\" width=\"16\" height=\"12\" rx=\"2\"/>\n  <rect x=\"88\" y=\"124\" width=\"16\" height=\"26\" rx=\"2\" fill=\"#10b981\" opacity=\"0.85\"/>\n\n  <rect class=\"cb-bar cb-b1\" x=\"200\" y=\"120\" width=\"26\" height=\"30\" rx=\"3\"/>\n  <rect class=\"cb-bar cb-b2\" x=\"242\" y=\"108\" width=\"26\" height=\"42\" rx=\"3\"/>\n  <rect class=\"cb-bar cb-b3\" x=\"284\" y=\"112\" width=\"26\" height=\"38\" rx=\"3\"/>\n  <rect class=\"cb-bar cb-b4\" x=\"326\" y=\"94\" width=\"26\" height=\"56\" rx=\"3\"/>\n  <rect class=\"cb-bar cb-b5\" x=\"368\" y=\"80\" width=\"26\" height=\"70\" rx=\"3\"/>\n  <rect class=\"cb-bar cb-bar--top cb-b6\" x=\"410\" y=\"58\" width=\"26\" height=\"92\" rx=\"3\"/>\n\n  <polyline class=\"cb-line\" points=\"213,112 255,100 297,104 339,86 381,72 423,50\"/>\n  <circle class=\"cb-dot\" cx=\"423\" cy=\"50\" r=\"3.5\"/>\n\n  <g class=\"cb-coin\">\n    <circle cx=\"423\" cy=\"30\" r=\"11\" fill=\"#e8b93d\"/>\n    <circle cx=\"423\" cy=\"30\" r=\"8\" fill=\"none\" stroke=\"#c99a24\" stroke-width=\"1.5\"/>\n    <text x=\"423\" y=\"34.5\" text-anchor=\"middle\" font-family=\"Arial, Helvetica, sans-serif\" font-weight=\"900\" font-size=\"12\" fill=\"#7a5a10\">$</text>\n  </g>\n</svg>\n";
	var DISCLOSURE = [
		["Data Storage", "Your key and a daily copy of your company data, until you remove your key"],
		["Data Sharing", "Nobody (your data is private)"],
		["Purpose of Use", "Signing in, verifying your subscription, and your daily company history and advice"],
		["Key Storage & Sharing", "Stored encrypted on TornManager. Only used to read your own company. Never shared"],
		["Key Access Level", "Limited access (required)"]
	];
	var KEY_URL = "https://www.torn.com/preferences.php#tab=api?&step=addNewKey&title=TM%20Company&type=3";
	var AuthScreen = class {
		constructor(auth, overlay) {
			this.auth = auth;
			this.overlay = overlay;
		}
		subtitle() {
			return "sign in";
		}
		render(container) {
			const wrap = Dom.el("div", "tc-auth");
			const banner = Dom.el("div", "tc-auth-banner");
			banner.innerHTML = company_banner_default;
			wrap.appendChild(banner);
			const form = Dom.el("form", "tc-auth-form");
			const row = Dom.el("div", "tc-auth-row");
			const input = Dom.el("input", "tc-auth-input");
			input.type = "text";
			input.placeholder = "Add Limited Torn API key";
			input.autocomplete = "off";
			input.spellcheck = false;
			const button = Dom.el("button", "tc-auth-button", "Sign in");
			button.type = "submit";
			button.disabled = true;
			const error = Dom.el("p", "tc-auth-error");
			row.append(input, button);
			form.append(row, error);
			form.appendChild(this.disclosure(button));
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
					await this.auth.authenticate(apiKey);
					await this.verifySubscription();
					this.overlay.open();
				} catch (err) {
					error.textContent = err.message;
					button.disabled = false;
					button.textContent = "Sign in";
				}
			});
			const hint = Dom.el("p", "tc-auth-hint");
			hint.append("Only company directors can sign in, with a key that has ", Dom.el("strong", null, "Limited"), " access. Torn only shares wages, stock and employee effectiveness with Limited keys. ");
			const create = Dom.el("a", null, "Create one here");
			create.href = KEY_URL;
			create.target = "_blank";
			create.rel = "noopener";
			hint.append(create, ". TM Company requires an active TornManager subscription.");
			wrap.append(form, hint);
			container.appendChild(wrap);
		}
		disclosure(button) {
			const tos = Dom.el("div", "tc-tos");
			tos.appendChild(Dom.el("p", "tc-tos-heading", "How your key and data are handled"));
			const grid = Dom.el("div", "tc-tos-grid");
			for (const [label, value] of DISCLOSURE) {
				const item = Dom.el("div", "tc-tos-item");
				item.append(Dom.el("span", "tc-tos-label", label), Dom.el("span", "tc-tos-value", value));
				grid.appendChild(item);
			}
			tos.appendChild(grid);
			const agree = Dom.el("label", "tc-tos-agree");
			const checkbox = Dom.el("input");
			checkbox.type = "checkbox";
			checkbox.addEventListener("change", () => {
				button.disabled = !checkbox.checked;
			});
			const text = Dom.el("span");
			text.append("I agree to the ", legalLink("Privacy Policy", "company-privacy-policy"), " and ", legalLink("Terms of Service", "company-terms-of-service"), ".");
			agree.append(checkbox, text);
			tos.appendChild(agree);
			return tos;
		}
		async verifySubscription() {
			await this.auth.fetchSubscription().catch(() => null);
			if (this.auth.isSubscribed()) return;
			this.auth.clear();
			throw new Error("No active subscription. Send Xanax to Bram [2728237], each adds 1 week, then sign in again.");
		}
	};
	function legalLink(label, anchor) {
		const link = Dom.el("a", null, label);
		link.href = `https://tornmanager.com/legal#${anchor}`;
		link.target = "_blank";
		link.rel = "noopener";
		return link;
	}
	var SubscriptionSection = class {
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
			info.innerHTML = "Send <strong>Xanax</strong> to <a href=\"https://www.torn.com/profiles.php?XID=2728237\" target=\"_blank\" rel=\"noopener\">Bram [2728237]</a> to extend your subscription. Each Xanax adds <strong>1 week</strong>. Payments are checked automatically once a day.";
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
	};
	var SUBSCRIPTION_NOTE = "TM Company requires an active TornManager subscription. The script stays locked until your subscription is active.";
	var SubscriptionScreen = class {
		constructor(auth, overlay, api) {
			this.auth = auth;
			this.overlay = overlay;
			this.api = api;
		}
		subtitle() {
			return "subscription";
		}
		render(container) {
			this.section?.destroy();
			this.section = new SubscriptionSection(this.auth, {
				classPrefix: "tc",
				note: SUBSCRIPTION_NOTE,
				onUpdate: (sub) => {
					if (sub.active && this.auth.isSubscribed()) this.overlay.open();
				}
			});
			container.appendChild(this.section.render());
			container.appendChild(removeKeyRow(this));
		}
	};
	function removeKeyRow(screen) {
		const actions = Dom.el("div", "tc-actions-row");
		const removeKey = Dom.el("button", "tc-btn-danger", "Remove API key");
		removeKey.addEventListener("click", async () => {
			screen.section?.destroy();
			await screen.api.revokeKey().catch(() => null);
			screen.auth.clear();
			screen.overlay.open();
		});
		actions.appendChild(removeKey);
		return actions;
	}
	var StorageViewer = class {
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
	};
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
	var SettingsScreen = class {
		constructor(auth, overlay, api) {
			this.auth = auth;
			this.overlay = overlay;
			this.api = api;
		}
		subtitle() {
			return "settings";
		}
		render(container) {
			this.section?.destroy();
			this.section = new SubscriptionSection(this.auth, {
				classPrefix: "tc",
				note: SUBSCRIPTION_NOTE
			});
			container.appendChild(this.section.render());
			const actions = removeKeyRow(this);
			const storageBtn = Dom.el("button", "tc-btn tc-btn--ghost", "View stored data");
			let viewer = null;
			storageBtn.addEventListener("click", () => {
				if (viewer) {
					viewer.remove();
					viewer = null;
					storageBtn.textContent = "View stored data";
					return;
				}
				viewer = new StorageViewer({
					storagePrefix: "tc_",
					classPrefix: "tc"
				}).render();
				container.appendChild(viewer);
				storageBtn.textContent = "Hide stored data";
			});
			actions.appendChild(storageBtn);
			container.appendChild(actions);
			container.appendChild(Dom.el("p", "tc-hint", "Removing your key deletes it from TornManager and stops the daily reads. To also delete your stored company history, message Bram [2728237]."));
		}
	};
	var SUFFIXES = [
		[0xe8d4a51000, "t"],
		[1e9, "b"],
		[1e6, "m"],
		[1e3, "k"]
	];
	function money(value) {
		if (value == null) return "–";
		return `${value < 0 ? "-" : ""}$${short(Math.abs(value))}`;
	}
	function short(value) {
		if (value == null) return "–";
		for (const [size, suffix] of SUFFIXES) if (Math.abs(value) >= size) return `${trim(value / size)}${suffix}`;
		return trim(value);
	}
	function number(value) {
		if (value == null) return "–";
		return Math.round(value).toLocaleString("en-US");
	}
	function percent(value) {
		if (value == null) return "–";
		return `${trim(value)}%`;
	}
	function day(value) {
		return new Date(`${value}T00:00:00Z`).toLocaleDateString("en-GB", {
			day: "numeric",
			month: "short",
			timeZone: "UTC"
		});
	}
	function ago(value) {
		if (!value) return "never";
		const minutes = Math.round((Date.now() - new Date(value).getTime()) / 6e4);
		if (minutes < 1) return "just now";
		if (minutes < 60) return `${minutes} min ago`;
		const hours = Math.round(minutes / 60);
		if (hours < 48) return `${hours} h ago`;
		return `${Math.round(hours / 24)} days ago`;
	}
	function trim(value) {
		const rounded = Math.abs(value) >= 100 ? Math.round(value) : Math.round(value * 10) / 10;
		return String(rounded);
	}
	var PENDING_POLL_MS = 1e4;
	var PENDING_MAX_POLLS = 18;
	var OverviewScreen = class {
		constructor(api, overlay) {
			this.api = api;
			this.overlay = overlay;
			this.polls = 0;
		}
		subtitle() {
			return "overview";
		}
		render(container) {
			clearTimeout(this.pollTimer);
			container.replaceChildren(Dom.el("div", "tc-empty", "Loading your company…"));
			this.api.overview().then((data) => {
				if (data.pending) return this.renderPending(container);
				this.polls = 0;
				this.renderReport(container, data);
			}).catch((error) => this.overlay.handleError(error, container));
		}
		renderPending(container) {
			if (this.polls >= PENDING_MAX_POLLS) {
				container.replaceChildren(Dom.el("div", "tc-empty", "Your company could not be loaded yet. Try again in a few minutes."));
				return;
			}
			this.polls += 1;
			container.replaceChildren(Dom.el("div", "tc-empty", "Reading your company from Torn for the first time. This takes about a minute…"));
			this.pollTimer = setTimeout(() => {
				if (this.overlay.current !== "overview") return;
				this.api.overview({ fresh: true }).then(() => this.render(container)).catch((error) => this.overlay.handleError(error, container));
			}, PENDING_POLL_MS);
		}
		renderReport(container, data) {
			const { company, benchmark, advice } = data;
			container.replaceChildren();
			container.appendChild(this.header(container, company));
			container.appendChild(this.kpis(company));
			if (benchmark) container.appendChild(this.rank(company, benchmark));
			container.appendChild(this.status(company));
			container.appendChild(this.advice(advice));
		}
		header(container, company) {
			const head = Dom.el("div", "tc-co-head");
			const title = Dom.el("div", "tc-co-title");
			const name = Dom.el("a", "tc-co-name", company.name);
			name.href = `https://www.torn.com/joblist.php#/p=corpinfo&ID=${company.id}`;
			name.target = "_blank";
			name.rel = "noopener";
			title.append(name, Dom.el("div", "tc-dim", `${company.type_name} · ${"★".repeat(company.rating || 0)} · updated ${ago(company.captured_at)}`));
			const refresh = Dom.el("button", "tc-btn tc-btn--ghost tc-btn--sm", "Refresh");
			refresh.addEventListener("click", () => this.refresh(container, refresh));
			head.append(title, refresh);
			return head;
		}
		refresh(container, button) {
			button.disabled = true;
			button.textContent = "Refreshing…";
			this.api.refresh().then((result) => {
				if (!result.queued) {
					button.textContent = "Up to date";
					return;
				}
				setTimeout(() => {
					if (this.overlay.current === "overview") this.render(container);
				}, 2e4);
			}).catch((error) => this.overlay.handleError(error, container));
		}
		kpis(company) {
			const grid = Dom.el("div", "tc-kpis");
			const items = [
				[
					"Income / day",
					money(company.income_daily),
					`${money(company.income_weekly)} this week`
				],
				[
					"Profit / day",
					money(company.profit_daily),
					company.profit_daily == null ? "needs wage data" : "income minus wages and ads"
				],
				[
					"Customers / day",
					number(company.customers_daily),
					`${number(company.customers_weekly)} this week`
				],
				[
					"Wages / day",
					money(company.wages_daily),
					company.advertising_daily ? `${money(company.advertising_daily)} ads` : "no advertising"
				],
				[
					"Staff",
					`${number(company.hired)} / ${number(company.capacity)}`,
					company.capacity > company.hired ? `${company.capacity - company.hired} empty` : "full"
				],
				[
					"Funds",
					money(company.funds),
					"company bank"
				]
			];
			for (const [label, value, sub] of items) {
				const kpi = Dom.el("div", "tc-kpi");
				kpi.append(Dom.el("div", "tc-kpi-label", label), Dom.el("div", "tc-kpi-value", value), Dom.el("div", "tc-kpi-sub", sub));
				if (label === "Profit / day" && company.profit_daily < 0) kpi.classList.add("tc-kpi--bad");
				grid.appendChild(kpi);
			}
			return grid;
		}
		rank(company, benchmark) {
			const card = Dom.el("div", "tc-card tc-rank");
			card.appendChild(Dom.el("div", "tc-label", `Among ${benchmark.peers} ${company.rating}★ ${company.type_name} companies`));
			const row = Dom.el("div", "tc-rank-row");
			row.append(stat("Rank by income", benchmark.rank ? `${benchmark.rank} of ${benchmark.peers}` : "–"), stat("You, per employee", money(benchmark.income_per_employee)), stat("Median", money(benchmark.median_per_employee)), stat("Top 10%", money(benchmark.top_per_employee)));
			card.appendChild(row);
			const max = Math.max(benchmark.income_per_employee || 0, benchmark.top_per_employee || 0, 1);
			const bar = Dom.el("div", "tc-meter");
			const fill = Dom.el("div", "tc-meter-fill");
			fill.style.width = `${Math.min(100, (benchmark.income_per_employee || 0) / max * 100)}%`;
			const median = Dom.el("div", "tc-meter-mark");
			median.style.left = `${Math.min(100, (benchmark.median_per_employee || 0) / max * 100)}%`;
			median.title = "Median";
			bar.append(fill, median);
			card.appendChild(bar);
			return card;
		}
		status(company) {
			const row = Dom.el("div", "tc-chips tc-status");
			const items = [
				["Popularity", percent(company.popularity)],
				["Efficiency", percent(company.efficiency)],
				["Environment", percent(company.environment)],
				["Trains", company.trains == null ? "–" : `${company.trains} / 20`]
			];
			for (const [label, value] of items) {
				const chip = Dom.el("span", "tc-chip");
				chip.append(Dom.el("span", "tc-dim", `${label} `), Dom.el("strong", null, value));
				row.appendChild(chip);
			}
			return row;
		}
		advice(items) {
			const card = Dom.el("div", "tc-card");
			card.appendChild(Dom.el("div", "tc-label", "Advice"));
			if (!items.length) {
				card.appendChild(Dom.el("div", "tc-dim", "Nothing to fix right now."));
				return card;
			}
			const list = Dom.el("div", "tc-advice");
			for (const item of items) {
				const entry = Dom.el("div", `tc-advice-item tc-advice-item--${item.level}`);
				entry.append(Dom.el("div", "tc-advice-title", item.title), Dom.el("div", "tc-advice-detail", item.detail));
				list.appendChild(entry);
			}
			card.appendChild(list);
			return card;
		}
	};
	function stat(label, value) {
		const node = Dom.el("div", "tc-rank-stat");
		node.append(Dom.el("div", "tc-kpi-label", label), Dom.el("div", "tc-rank-value", value));
		return node;
	}
	var SVG_NS = "http://www.w3.org/2000/svg";
	var WIDTH = 600;
	var HEIGHT = 170;
	var PAD = {
		top: 10,
		right: 10,
		bottom: 22,
		left: 52
	};
	var COLORS = [
		"#34d399",
		"#9a9aa2",
		"#e8b93d",
		"#60a5fa"
	];
	var LineChart = class {
		constructor({ title, dates, series, format }) {
			this.title = title;
			this.dates = dates;
			this.series = series.map((item, index) => ({
				...item,
				color: item.color || COLORS[index % COLORS.length]
			}));
			this.format = format;
		}
		render() {
			const card = Dom.el("div", "tc-card tc-chart");
			const head = Dom.el("div", "tc-chart-head");
			head.appendChild(Dom.el("div", "tc-label", this.title));
			this.readout = Dom.el("div", "tc-chart-readout tc-dim");
			head.appendChild(this.readout);
			card.appendChild(head);
			const values = this.series.flatMap((item) => item.values).filter((value) => value != null);
			if (!values.length) {
				card.appendChild(Dom.el("div", "tc-chart-empty tc-dim", "No data yet. It fills up day by day."));
				return card;
			}
			this.min = Math.min(...values, 0);
			this.max = Math.max(...values);
			if (this.max === this.min) this.max = this.min + 1;
			const svg = svgEl("svg", {
				viewBox: `0 0 ${WIDTH} ${HEIGHT}`,
				class: "tc-chart-svg",
				role: "img",
				"aria-label": this.title
			});
			this.drawGrid(svg);
			for (const item of this.series) svg.appendChild(this.line(item));
			this.drawHover(svg);
			card.appendChild(svg);
			card.appendChild(this.legend());
			this.showReadout(this.lastIndex());
			return card;
		}
		x(index) {
			const span = Math.max(this.dates.length - 1, 1);
			return PAD.left + index / span * (WIDTH - PAD.left - PAD.right);
		}
		y(value) {
			return PAD.top + (1 - (value - this.min) / (this.max - this.min)) * (HEIGHT - PAD.top - PAD.bottom);
		}
		drawGrid(svg) {
			for (const fraction of [
				0,
				.5,
				1
			]) {
				const value = this.min + (this.max - this.min) * fraction;
				const y = this.y(value);
				svg.appendChild(svgEl("line", {
					x1: PAD.left,
					x2: WIDTH - PAD.right,
					y1: y,
					y2: y,
					class: "tc-chart-grid"
				}));
				const label = svgEl("text", {
					x: PAD.left - 6,
					y: y + 3,
					"text-anchor": "end",
					class: "tc-chart-axis"
				});
				label.textContent = this.format(value);
				svg.appendChild(label);
			}
			const last = this.dates.length - 1;
			for (const index of [
				0,
				Math.round(last / 2),
				last
			]) {
				const label = svgEl("text", {
					x: this.x(index),
					y: 164,
					"text-anchor": index === 0 ? "start" : index === last ? "end" : "middle",
					class: "tc-chart-axis"
				});
				label.textContent = day(this.dates[index]);
				svg.appendChild(label);
			}
		}
		line(item) {
			let path = "";
			let open = false;
			item.values.forEach((value, index) => {
				if (value == null) {
					open = false;
					return;
				}
				path += `${open ? "L" : "M"}${this.x(index).toFixed(1)},${this.y(value).toFixed(1)}`;
				open = true;
			});
			const group = svgEl("g");
			group.appendChild(svgEl("path", {
				d: path,
				stroke: item.color,
				class: `tc-chart-line${item.dashed ? " tc-chart-line--dashed" : ""}`
			}));
			item.values.forEach((value, index) => {
				const prev = item.values[index - 1];
				const next = item.values[index + 1];
				if (value != null && prev == null && next == null) group.appendChild(svgEl("circle", {
					cx: this.x(index),
					cy: this.y(value),
					r: 2.5,
					fill: item.color
				}));
			});
			return group;
		}
		drawHover(svg) {
			const cursor = svgEl("line", {
				y1: PAD.top,
				y2: HEIGHT - PAD.bottom,
				class: "tc-chart-cursor"
			});
			cursor.style.display = "none";
			const area = svgEl("rect", {
				x: PAD.left,
				y: PAD.top,
				width: WIDTH - PAD.left - PAD.right,
				height: HEIGHT - PAD.top - PAD.bottom,
				fill: "transparent"
			});
			area.addEventListener("mousemove", (event) => {
				const box = svg.getBoundingClientRect();
				const svgX = (event.clientX - box.left) / box.width * WIDTH;
				const span = Math.max(this.dates.length - 1, 1);
				const index = Math.max(0, Math.min(this.dates.length - 1, Math.round((svgX - PAD.left) / (WIDTH - PAD.left - PAD.right) * span)));
				cursor.setAttribute("x1", this.x(index));
				cursor.setAttribute("x2", this.x(index));
				cursor.style.display = "";
				this.showReadout(index);
			});
			area.addEventListener("mouseleave", () => {
				cursor.style.display = "none";
				this.showReadout(this.lastIndex());
			});
			svg.append(cursor, area);
		}
		legend() {
			const legend = Dom.el("div", "tc-chart-legend");
			for (const item of this.series) {
				const entry = Dom.el("span", "tc-chart-key");
				const swatch = Dom.el("span", "tc-chart-swatch");
				swatch.style.background = item.color;
				entry.append(swatch, item.label);
				legend.appendChild(entry);
			}
			return legend;
		}
		lastIndex() {
			for (let index = this.dates.length - 1; index >= 0; index -= 1) if (this.series.some((item) => item.values[index] != null)) return index;
			return this.dates.length - 1;
		}
		showReadout(index) {
			const parts = this.series.filter((item) => item.values[index] != null).map((item) => `${item.label} ${this.format(item.values[index])}`);
			this.readout.textContent = parts.length ? `${day(this.dates[index])} · ${parts.join(" · ")}` : day(this.dates[index]);
		}
	};
	function svgEl(tag, attributes = {}) {
		const node = document.createElementNS(SVG_NS, tag);
		for (const [name, value] of Object.entries(attributes)) node.setAttribute(name, value);
		return node;
	}
	var RANGES = [
		[30, "30 days"],
		[90, "90 days"],
		[365, "1 year"]
	];
	var ChartsScreen = class {
		constructor(api, overlay) {
			this.api = api;
			this.overlay = overlay;
			this.days = 30;
		}
		subtitle() {
			return "charts";
		}
		render(container) {
			container.replaceChildren();
			container.appendChild(this.rangePicker(container));
			const charts = Dom.el("div", "tc-charts");
			charts.appendChild(Dom.el("div", "tc-empty", "Loading history…"));
			container.appendChild(charts);
			this.api.history(this.days).then((data) => this.renderCharts(charts, data)).catch((error) => this.overlay.handleError(error, charts));
		}
		rangePicker(container) {
			const row = Dom.el("div", "tc-chips");
			for (const [days, label] of RANGES) {
				const chip = Dom.el("button", `tc-chip tc-chip--filter${days === this.days ? " tc-chip--on" : ""}`, label);
				chip.addEventListener("click", () => {
					this.days = days;
					this.render(container);
				});
				row.appendChild(chip);
			}
			return row;
		}
		renderCharts(charts, { dates, series }) {
			charts.replaceChildren(new LineChart({
				title: "Income per day",
				dates,
				format: money,
				series: [{
					label: "Income",
					values: series.income
				}]
			}).render(), new LineChart({
				title: "Income per employee against similar companies",
				dates,
				format: money,
				series: [
					{
						label: "You",
						values: series.income_per_employee
					},
					{
						label: "Median",
						values: series.peer_median_per_employee,
						dashed: true
					},
					{
						label: "Top 10%",
						values: series.peer_top_per_employee,
						dashed: true
					}
				]
			}).render(), new LineChart({
				title: "Customers per day",
				dates,
				format: number,
				series: [{
					label: "Customers",
					values: series.customers
				}]
			}).render(), new LineChart({
				title: "Wages against income",
				dates,
				format: money,
				series: [{
					label: "Income",
					values: series.income
				}, {
					label: "Wages",
					values: series.wages
				}]
			}).render(), new LineChart({
				title: "Company funds",
				dates,
				format: money,
				series: [{
					label: "Funds",
					values: series.funds
				}]
			}).render(), new LineChart({
				title: "Popularity, efficiency and environment",
				dates,
				format: percent,
				series: [
					{
						label: "Popularity",
						values: series.popularity
					},
					{
						label: "Efficiency",
						values: series.efficiency
					},
					{
						label: "Environment",
						values: series.environment
					}
				]
			}).render(), new LineChart({
				title: "Average staff effectiveness",
				dates,
				format: number,
				series: [{
					label: "Effectiveness",
					values: series.effectiveness
				}]
			}).render());
		}
	};
	var FLAGS = {
		addicted: ["Addicted", "bad"],
		inactive: ["Inactive", "bad"],
		low_effectiveness: ["Low effectiveness", "bad"],
		below_requirement: ["Below requirement", "warn"],
		costs_more_than_value: ["Costs more than value", "warn"],
		settling_in: ["Settling in", "info"]
	};
	var STATS = [
		["manual_labor", "MAN"],
		["intelligence", "INT"],
		["endurance", "END"]
	];
	var EFFECTIVENESS_PARTS = [
		["working_stats", "Working stats"],
		["settled_in", "Settled in"],
		["book", "Book"],
		["merits", "Merits"],
		["director_education", "Director education"],
		["management", "Management"],
		["wrong_gender", "Wrong gender"],
		["addiction", "Addiction"],
		["inactivity", "Inactivity"]
	];
	var StaffScreen = class {
		constructor(api, overlay) {
			this.api = api;
			this.overlay = overlay;
		}
		subtitle() {
			return "staff";
		}
		render(container) {
			container.replaceChildren(Dom.el("div", "tc-empty", "Loading staff…"));
			this.api.overview().then((data) => {
				if (data.pending) {
					container.replaceChildren(Dom.el("div", "tc-empty", "Your company is still being read. Check the Overview in a minute."));
					return;
				}
				container.replaceChildren(this.balance(data.balance), this.employees(data.employees));
			}).catch((error) => this.overlay.handleError(error, container));
		}
		balance(balance) {
			const card = Dom.el("div", "tc-card");
			card.appendChild(Dom.el("div", "tc-label", "Staff per position"));
			const list = Dom.el("div", "tc-positions");
			for (const position of balance.positions) {
				const item = Dom.el("div", `tc-position${position.count === 0 ? " tc-position--empty" : ""}`);
				item.append(Dom.el("span", "tc-position-count", String(position.count)), Dom.el("span", null, position.name));
				if (position.ability) item.appendChild(Dom.el("span", "tc-dim", position.ability));
				list.appendChild(item);
			}
			card.appendChild(list);
			if (balance.missing_abilities.length) card.appendChild(Dom.el("div", "tc-hint", `Nobody fills these special roles: ${balance.missing_abilities.join(", ")}.`));
			return card;
		}
		employees(employees) {
			const card = Dom.el("div", "tc-card");
			card.appendChild(Dom.el("div", "tc-label", `Employees (${employees.length})`));
			const sorted = [...employees].sort((a, b) => b.flags.length - a.flags.length || (a.effectiveness?.total ?? 0) - (b.effectiveness?.total ?? 0));
			for (const employee of sorted) card.appendChild(this.employee(employee));
			return card;
		}
		employee(employee) {
			const row = Dom.el("details", "tc-emp");
			const summary = Dom.el("summary", "tc-emp-summary");
			const who = Dom.el("div", "tc-emp-who");
			const link = Dom.el("a", "tc-name", employee.name);
			link.href = `https://www.torn.com/profiles.php?XID=${employee.id}`;
			link.target = "_blank";
			link.rel = "noopener";
			who.append(link, Dom.el("div", "tc-dim", `${employee.position} · ${employee.days_in_company ?? "?"} days · ${employee.last_action || ""}`));
			const flags = Dom.el("div", "tc-flags");
			for (const flag of employee.flags) {
				const [label, tone] = FLAGS[flag] || [flag, "info"];
				flags.appendChild(Dom.el("span", `tc-flag tc-flag--${tone}`, label));
			}
			const numbers = Dom.el("div", "tc-emp-numbers");
			const total = employee.effectiveness?.total;
			numbers.append(Dom.el("div", "tc-emp-eff", total == null ? "–" : `${total}%`), Dom.el("div", "tc-dim", employee.wage == null ? "" : `${money(employee.wage)}/day`));
			summary.append(who, flags, numbers);
			row.appendChild(summary);
			row.appendChild(this.details(employee));
			return row;
		}
		details(employee) {
			const body = Dom.el("div", "tc-emp-details");
			const stats = Dom.el("div", "tc-emp-stats");
			for (const [key, label] of STATS) {
				const required = employee.required?.[key] || 0;
				const value = employee.stats?.[key];
				const cell = Dom.el("div", `tc-emp-stat${required && value != null && value < required ? " tc-emp-stat--low" : ""}`);
				cell.append(Dom.el("div", "tc-kpi-label", label), Dom.el("div", null, value == null ? "–" : short(value)), Dom.el("div", "tc-dim", required ? `needs ${short(required)}` : "not needed"));
				stats.appendChild(cell);
			}
			body.appendChild(stats);
			if (employee.effectiveness && Object.keys(employee.effectiveness).length) {
				const parts = Dom.el("div", "tc-emp-parts");
				for (const [key, label] of EFFECTIVENESS_PARTS) {
					const value = employee.effectiveness[key];
					if (!value) continue;
					parts.appendChild(Dom.el("span", `tc-chip${value < 0 ? " tc-chip--bad" : ""}`, `${label} ${value > 0 ? "+" : ""}${value}`));
				}
				body.appendChild(parts);
			}
			if (employee.status && employee.status !== "Okay") body.appendChild(Dom.el("div", "tc-dim", employee.status));
			if (employee.value != null) body.appendChild(Dom.el("div", "tc-dim", `Value ${money(employee.value)}/day, wage ${money(employee.wage)}/day`));
			return body;
		}
	};
	var StockScreen = class {
		constructor(api, overlay) {
			this.api = api;
			this.overlay = overlay;
		}
		subtitle() {
			return "stock";
		}
		render(container) {
			container.replaceChildren(Dom.el("div", "tc-empty", "Loading stock…"));
			this.api.overview().then((data) => {
				if (data.pending) {
					container.replaceChildren(Dom.el("div", "tc-empty", "Your company is still being read. Check the Overview in a minute."));
					return;
				}
				container.replaceChildren(this.table(data.stock));
			}).catch((error) => this.overlay.handleError(error, container));
		}
		table(stock) {
			const card = Dom.el("div", "tc-card");
			card.appendChild(Dom.el("div", "tc-label", "Stock"));
			if (!stock.length) {
				card.appendChild(Dom.el("div", "tc-dim", "No stock data. Torn only shares stock with a Limited key."));
				return card;
			}
			const table = Dom.el("table", "tc-tbl");
			const head = Dom.el("tr");
			for (const label of [
				"Item",
				"Price",
				"RRP",
				"Cost",
				"In stock",
				"On order",
				"Sold",
				"Days left"
			]) head.appendChild(Dom.el("th", null, label));
			table.appendChild(head);
			for (const item of stock) {
				const row = Dom.el("tr");
				const daysLeft = Dom.el("td", item.days_left != null && item.days_left < 2 ? "tc-bad" : null, item.days_left == null ? "–" : String(item.days_left));
				row.append(Dom.el("td", null, item.name), Dom.el("td", null, money(item.price)), Dom.el("td", null, money(item.rrp)), Dom.el("td", null, money(item.cost)), Dom.el("td", null, number(item.in_stock)), Dom.el("td", null, number(item.on_order)), Dom.el("td", null, `${number(item.sold_amount)} (${money(item.sold_worth)})`), daysLeft);
				table.appendChild(row);
			}
			card.appendChild(table);
			card.appendChild(Dom.el("div", "tc-hint", "Days left is stock plus orders divided by the last day's sales."));
			return card;
		}
	};
	var NewsScreen = class {
		constructor(api, overlay) {
			this.api = api;
			this.overlay = overlay;
		}
		subtitle() {
			return "news";
		}
		render(container) {
			container.replaceChildren(Dom.el("div", "tc-empty", "Loading news…"));
			this.api.news().then(({ news }) => {
				if (!news.length) {
					container.replaceChildren(Dom.el("div", "tc-empty", "No company news stored yet."));
					return;
				}
				const list = Dom.el("div", "tc-card tc-news");
				for (const entry of news) {
					const item = Dom.el("div", "tc-news-item");
					const when = new Date(entry.occurred_at).toLocaleString("en-GB", {
						day: "numeric",
						month: "short",
						hour: "2-digit",
						minute: "2-digit",
						timeZone: "UTC"
					});
					item.append(Dom.el("div", "tc-dim", `${when} TCT`), Dom.el("div", null, entry.text));
					list.appendChild(item);
				}
				container.replaceChildren(list);
			}).catch((error) => this.overlay.handleError(error, container));
		}
	};
	function boot() {
		const auth = new CompanyAuth(Store);
		const api = new CompanyApi(auth);
		const overlay = new Overlay(auth);
		overlay.register("auth", new AuthScreen(auth, overlay));
		overlay.register("subscription", new SubscriptionScreen(auth, overlay, api));
		overlay.register("settings", new SettingsScreen(auth, overlay, api));
		overlay.register("overview", new OverviewScreen(api, overlay));
		overlay.register("charts", new ChartsScreen(api, overlay));
		overlay.register("staff", new StaffScreen(api, overlay));
		overlay.register("stock", new StockScreen(api, overlay));
		overlay.register("news", new NewsScreen(api, overlay));
		new Sidebar(overlay).init();
		new MenuEntry(overlay).init();
		console.log(`%cCompany %cv0.1.0 is running.`, "font-weight: 700; color: #10b981;", "color: inherit;");
	}
	if (window.self === window.top) boot();
})();
