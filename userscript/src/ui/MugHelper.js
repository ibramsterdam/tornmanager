import { Dom } from "../core/Dom.js";
import { MugKey } from "../core/MugKey.js";
import { MugTargets } from "../core/MugTargets.js";

const OPEN_KEY = "tm_mug_helper_open";
const POS_KEY = "tm_mug_helper_pos";
const SIZE_KEY = "tm_mug_helper_size";
const DRAG_THRESHOLD_PX = 6;
const MIN_WIDTH = 260;
const MIN_HEIGHT = 240;

// Mirrors DEV_TORN_ID in Overlay.js. The helper only mounts for the dev account
// while the Mugging tools are in development.
const DEV_TORN_ID = 2728237;

const HELPER_ICON =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="4" width="18" height="16" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/></svg>';

const NAV_LINKS = [
  { label: "Russian Roulette", url: "https://www.torn.com/page.php?sid=russianRoulette#/" },
  { label: "Poker", url: "https://www.torn.com/page.php?sid=holdem" },
  { label: "Item Market", url: "https://www.torn.com/page.php?sid=ItemMarket" },
  { label: "Bazaar", url: "https://www.torn.com/page.php?sid=bazaar" },
  { label: "Auction House", url: "https://www.torn.com/amarket.php" },
];

let zCounter = 99995;

export class MugHelper {
  constructor(auth) {
    this.auth = auth;
    this.element = null;
    this.onResize = null;
  }

  init() {
    if (this.auth?.getUser()?.torn_id !== DEV_TORN_ID) return;
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
    if (this.onResize) {
      window.removeEventListener("resize", this.onResize);
      this.onResize = null;
    }
    this.element?.remove();
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
    for (const link of NAV_LINKS) {
      const anchor = document.createElement("a");
      anchor.className = "tm-mh-nav-link";
      anchor.href = link.url;
      anchor.textContent = link.label;
      if (this.isCurrentPage(link.url)) anchor.classList.add("tm-mh-nav-link--active");
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
      this.content.appendChild(this.placeholder("Connect your Full Access key on the Mugging tab to scan targets."));
      return;
    }

    if (!MugTargets.onBazaarDirectory()) {
      this.content.appendChild(
        this.placeholder("Open the Bazaar Directory and this finds sellers you can mug right now."),
      );
      return;
    }

    this.renderTargets();
  }

  placeholder(text) {
    const wrap = document.createElement("div");
    wrap.className = "tm-mh-placeholder";
    wrap.innerHTML =
      HELPER_ICON +
      '<p class="tm-mh-placeholder-title">Bazaar targets</p>' +
      `<p class="tm-mh-placeholder-text">${text}</p>`;
    return wrap;
  }

  renderTargets() {
    const bar = document.createElement("div");
    bar.className = "tm-mh-bar";

    this.scanBtn = document.createElement("button");
    this.scanBtn.type = "button";
    this.scanBtn.className = "tm-mh-scan";
    const hasLast = !!MugTargets.lastResult()?.scanned;
    this.scanBtn.textContent = hasLast ? "Rescan" : "Scan bazaar targets";
    this.scanBtn.onclick = () => this.runScan(hasLast);
    bar.appendChild(this.scanBtn);
    this.content.appendChild(bar);

    this.targetsEl = document.createElement("div");
    this.targetsEl.className = "tm-mh-targets";
    this.content.appendChild(this.targetsEl);

    const last = MugTargets.lastResult();
    if (last?.scanned) {
      this.renderResults(last);
    } else {
      this.showTargetsMessage("Scan the page to find sellers you can mug right now.");
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
          fill.style.width = `${Math.round((done / total) * 100)}%`;
          label.textContent = `Checking ${done} / ${total}...`;
        },
        onTarget: (target) => list.appendChild(this.targetRow(target)),
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
        message("No muggable targets right now. The rest are hospitalized or in clothing stores."),
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

    const name = document.createElement("span");
    name.className = "tm-mh-target-name";
    name.textContent = target.name;
    info.appendChild(name);

    const link = document.createElement("a");
    link.className = "tm-mh-target-link";
    link.href = `https://www.torn.com/bazaar.php?userId=${target.id}#/`;
    link.target = "_blank";
    link.rel = "noopener";
    link.textContent = "Open bazaar";
    info.appendChild(link);

    item.appendChild(info);

    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "tm-mh-target-remove";
    remove.title = "Remove, not worth mugging";
    remove.textContent = "×";
    remove.onclick = () => {
      MugTargets.dismiss(target.id);
      item.remove();
      this.updateSummary();
    };
    item.appendChild(remove);

    return item;
  }

  summaryEl(result) {
    const summary = document.createElement("p");
    summary.className = "tm-mh-summary";
    summary.textContent = `${result.targets.length} muggable of ${result.scanned} checked, ${ago(result.at)}`;
    this.summaryElement = summary;
    this.summaryData = { scanned: result.scanned, at: result.at };
    return summary;
  }

  updateSummary() {
    if (!this.summaryElement || !this.summaryData) return;

    const count = this.targetsEl.querySelectorAll(".tm-mh-target").length;
    this.summaryElement.textContent = `${count} muggable of ${this.summaryData.scanned} checked, ${ago(this.summaryData.at)}`;

    if (count === 0 && !this.targetsEl.querySelector(".tm-mh-msg")) {
      const list = this.targetsEl.querySelector(".tm-mh-list") || this.targetsEl;
      list.appendChild(message("No muggable targets left. Rescan to check again."));
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
        JSON.stringify({ w: Math.round(this.element.offsetWidth), h: Math.round(this.element.offsetHeight) }),
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
  const mins = Math.floor((Date.now() - ts) / 60000);
  if (mins <= 0) return "just now";
  if (mins === 1) return "1 minute ago";
  if (mins < 60) return `${mins} minutes ago`;
  const hours = Math.floor(mins / 60);
  return hours === 1 ? "1 hour ago" : `${hours} hours ago`;
}
