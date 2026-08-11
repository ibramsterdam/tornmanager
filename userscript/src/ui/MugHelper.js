import { Dom } from "../core/Dom.js";

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

    const body = document.createElement("div");
    body.className = "tm-mh-body";
    body.appendChild(this.createPlaceholder());
    this.element.appendChild(body);

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

  createPlaceholder() {
    const wrap = document.createElement("div");
    wrap.className = "tm-mh-placeholder";
    wrap.innerHTML =
      HELPER_ICON +
      '<p class="tm-mh-placeholder-title">Mug helper</p>' +
      '<p class="tm-mh-placeholder-text">Live mugging tools will live here. ' +
      "Drag the header to move it, drag the corner to resize.</p>";
    return wrap;
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
