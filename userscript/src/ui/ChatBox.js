import { copyText } from "../core/Clipboard.js";

const POLL_INTERVAL_MS = 3000;
const MAX_LENGTH = 300;
const DIVIDER_GAP_MS = 15 * 60 * 1000;
const POS_KEY = "tm_chat_box_pos";
const DRAG_THRESHOLD_PX = 6;

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

    // New boxes cascade from the bottom-right so they never fully overlap.
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
      invite.onclick = () => copyText(this.room.invite_url, "Invite link copied");
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

  send() {
    const body = this.input.value.trim();
    if (!body) return;

    this.input.value = "";
    this.counter.textContent = "";

    this.client
      .sendMessage(this.room.id, body)
      .then(() => this.poll())
      .catch((err) => this.appendSystem(err.message || "Could not send message."));
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
      .catch(() => {});
  }

  appendMessages(messages) {
    if (!messages.length) return;

    const nearBottom = this.list.scrollHeight - this.list.scrollTop - this.list.clientHeight < 60;

    for (const message of messages) {
      this.lastMessageId = Math.max(this.lastMessageId, message.id);
      this.appendDividerIfNeeded(message.at);

      if (message.system) {
        this.appendSystem(message.body);
        continue;
      }

      const row = document.createElement("div");
      row.className = "tm-cb-row";

      const sender = document.createElement("a");
      sender.className = "tm-cb-sender";
      if (message.torn_id === this.client.me().torn_id) sender.classList.add("tm-cb-sender--own");
      sender.href = `https://www.torn.com/profiles.php?XID=${message.torn_id}`;
      sender.target = "_blank";
      sender.rel = "noopener";
      sender.textContent = `${message.name}:`;

      const body = document.createElement("span");
      body.className = "tm-cb-body";
      body.textContent = message.body;

      row.appendChild(sender);
      row.appendChild(body);
      this.list.appendChild(row);
    }

    if (nearBottom) this.list.scrollTop = this.list.scrollHeight;
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
}
