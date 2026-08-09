import { copyText } from "../core/Clipboard.js";
import { ChatCrypto } from "../core/ChatCrypto.js";

const POLL_INTERVAL_MS = 3000;
const MAX_LENGTH = 300;
const DIVIDER_GAP_MS = 15 * 60 * 1000;
const POS_KEY = "tm_chat_box_pos";
const SIZE_KEY = "tm_chat_box_size";
const DRAG_THRESHOLD_PX = 6;
const MIN_WIDTH = 280;
const MIN_HEIGHT = 300;

let zCounter = 99991;

export class ChatBox {
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

    this.composer = this.createComposer();
    this.element.appendChild(this.composer);

    this.element.addEventListener("pointerdown", () => {
      this.element.style.zIndex = ++zCounter;
    });

    this.makeDraggable(header);
    this.applySize();
    this.addResizeHandle();
    this.applyPosition();

    if (this.room.suspended) {
      this.showSuspended();
    } else {
      this.poll();
      this.pollInterval = setInterval(() => this.poll(), POLL_INTERVAL_MS);
    }

    return this.element;
  }

  // Replace the conversation with a removed-notice and stop polling. Triggered
  // when the room arrives already suspended, or when a poll returns 403.
  showSuspended() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }

    this.list.innerHTML = "";
    const notice = document.createElement("div");
    notice.className = "tm-cb-suspended";
    notice.innerHTML =
      '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>' +
      "<p>You've been suspended from this chat by the host.</p>";
    this.list.appendChild(notice);

    this.composer?.remove();
  }

  applyPosition() {
    const stagger = document.querySelectorAll(".tm-cb").length;
    const saved = this.savedPositions()[this.room.id];
    if (saved && typeof saved.left === "number" && typeof saved.top === "number") {
      this.moveTo(saved.left, saved.top);
      return;
    }

    // New boxes cascade from the bottom-right so they never fully overlap.
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
      // localStorage full or unavailable
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
    const sizes = this.savedSizes();
    sizes[this.room.id] = { w: Math.round(this.element.offsetWidth), h: Math.round(this.element.offsetHeight) };
    try {
      localStorage.setItem(SIZE_KEY, JSON.stringify(sizes));
    } catch {
      // localStorage full or unavailable
    }
  }

  savedSizes() {
    try {
      const raw = localStorage.getItem(SIZE_KEY);
      const sizes = raw ? JSON.parse(raw) : {};
      return typeof sizes === "object" && sizes !== null ? sizes : {};
    } catch {
      return {};
    }
  }

  destroy() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
    this.element?.remove();
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
      lock.innerHTML =
        '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';
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
      invite.innerHTML =
        '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';
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
    send.innerHTML =
      '<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M2 21l21-9L2 3v7l15 2-15 2v7z"/></svg>';
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
      row.innerHTML =
        `<span class="tm-cb-skel" style="width:${nameWidth}px"></span>` +
        `<span class="tm-cb-skel" style="width:${textWidth}px"></span>`;
      skeleton.appendChild(row);
    }

    return skeleton;
  }

  poll() {
    this.client
      .fetchMessages(this.room.id, this.lastMessageId)
      .then((messages) => {
        if (!this.loaded) {
          this.loaded = true;
          this.skeleton?.remove();
          this.skeleton = null;
        }
        this.appendMessages(messages);
      })
      .catch((err) => {
        if (err?.status === 403) {
          this.room.suspended = true;
          this.showSuspended();
        }
      });
  }

  async appendMessages(messages) {
    if (!messages.length) return;

    // Reserve ids up front so an overlapping poll won't refetch the same
    // messages while decryption is still awaiting.
    for (const message of messages) {
      this.lastMessageId = Math.max(this.lastMessageId, message.id);
    }

    const prepared = [];
    for (const message of messages) {
      prepared.push({ message, ...(await this.resolveBody(message)) });
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

      // Anonymous senders (public rooms) carry no torn_id, so they render as
      // plain text with no profile link; "own" comes from the server flag.
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
      hash = (hash * 31 + name.charCodeAt(i)) | 0;
    }
    const hue = Math.abs(hash) % 360;
    return `hsl(${hue}, 60%, 68%)`;
  }
}
