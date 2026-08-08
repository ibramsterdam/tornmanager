import { Dom } from "../core/Dom.js";
import { ChatBox } from "./ChatBox.js";
import { showToast } from "../core/Clipboard.js";

const OPEN_KEY = "tm_chat_open";
const SEEN_KEY = "tm_chat_seen";
const UNREAD_POLL_MS = 8000;
const REPOSITION_MS = 1500;
const DOCK_GAP = 12;
const MIN_VISIBLE_WIDTH = 350;

// Torn's chat elements carry stable ids (unlike its hashed CSS classes):
// strip buttons and opened panels. Used to measure how far its dock reaches.
const TORN_CHAT_SELECTOR = [
  '[id^="channel_panel_button"]',
  "#notes_panel_button",
  "#people_panel_button",
  "#notes_settings_button",
  '[id^="private-"]',
  '[id^="faction-"]',
  '[id^="company-"]',
  '[id^="public_"]',
].join(", ");

export class ChatDock {
  constructor(auth, client, logger) {
    this.auth = auth;
    this.client = client;
    this.logger = logger;
    this.rooms = [];
    this.boxes = new Map();
    this.buttons = new Map();
    this.unreadInterval = null;
  }

  init() {
    if (!this.auth.isAuthenticated()) return;

    Dom.ready("body", () => {
      this.strip = document.createElement("div");
      this.strip.className = "tm-chat-strip";

      this.boxesEl = document.createElement("div");
      this.boxesEl.className = "tm-chat-boxes";

      document.body.appendChild(this.strip);
      document.body.appendChild(this.boxesEl);

      this.updatePosition();
      window.addEventListener("resize", () => this.updatePosition());
      setInterval(() => this.updatePosition(), REPOSITION_MS);
      this.observeTornChat();

      this.handleInviteHash().then(() => this.refresh());
      this.unreadInterval = setInterval(() => this.pollUnread(), UNREAD_POLL_MS);
    });
  }

  // Keep our dock just left of Torn's chat strip and any open chat panels.
  updatePosition() {
    if (!this.strip) return;

    const offset = Math.max(
      DOCK_GAP,
      Math.min(this.tornChatWidth() + DOCK_GAP, window.innerWidth - MIN_VISIBLE_WIDTH)
    );

    this.strip.style.right = `${offset}px`;
    this.boxesEl.style.right = `${offset}px`;
  }

  tornChatWidth() {
    const chatRoot = document.getElementById("chatRoot");
    if (!chatRoot) return 8;

    let minLeft = window.innerWidth;
    for (const el of chatRoot.querySelectorAll(TORN_CHAT_SELECTOR)) {
      const rect = el.getBoundingClientRect();
      if (!rect.width && !rect.height) continue;
      if (rect.left < minLeft) minLeft = rect.left;
    }

    return Math.max(0, window.innerWidth - minLeft);
  }

  observeTornChat() {
    Dom.ready("#chatRoot", (chatRoot) => {
      this.updatePosition();

      let debounce = null;
      const observer = new MutationObserver(() => {
        clearTimeout(debounce);
        debounce = setTimeout(() => this.updatePosition(), 120);
      });
      observer.observe(chatRoot, { childList: true, subtree: true });
    });
  }

  async handleInviteHash() {
    const match = window.location.hash.match(/tmchat=([A-Za-z0-9_-]+)/);
    if (!match) return;

    history.replaceState(null, "", window.location.pathname + window.location.search);

    try {
      const room = await this.client.joinByToken(match[1]);
      showToast(`Joined "${room.name}"`);
      this.openRoom(room);
    } catch (err) {
      this.logger.log(err, "chat invite join");
      showToast("Could not join the chat room");
    }
  }

  refresh() {
    return this.client
      .listRooms()
      .then((rooms) => {
        this.rooms = rooms;
        this.renderStrip();
        this.syncBoxes();
      })
      .catch((err) => this.logger.log(err, "chat rooms list"));
  }

  renderStrip() {
    this.strip.innerHTML = "";
    this.buttons.clear();

    for (const room of this.rooms) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "tm-chat-tab";
      button.title = room.name;

      const label = document.createElement("span");
      label.className = "tm-chat-tab-label";
      label.textContent = room.name;

      const dot = document.createElement("span");
      dot.className = "tm-chat-tab-dot";

      button.appendChild(label);
      button.appendChild(dot);
      button.onclick = () => this.toggleRoom(room.id);

      this.buttons.set(room.id, button);
      this.strip.appendChild(button);
    }

    this.strip.style.display = this.rooms.length ? "" : "none";
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

    this.updateButtonStates();
  }

  mountBox(roomId) {
    const room = this.rooms.find((r) => r.id === roomId);
    if (!room) return;

    const box = new ChatBox(room, this.client, {
      onMinimize: (id) => this.markOpen(id, false),
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

    this.renderStrip();
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

  updateButtonStates() {
    const openIds = this.getOpenIds();
    for (const [id, button] of this.buttons) {
      button.classList.toggle("tm-chat-tab--open", openIds.includes(id));
    }
  }

  pollUnread() {
    const openIds = this.getOpenIds();
    const seen = this.getSeen();

    for (const room of this.rooms) {
      if (openIds.includes(room.id)) {
        this.markSeen(room.id);
        continue;
      }

      this.client
        .fetchMessages(room.id, seen[room.id] || 0)
        .then((messages) => {
          if (messages.length) this.setUnread(room.id, true);
        })
        .catch(() => {});
    }
  }

  setUnread(roomId, unread) {
    const button = this.buttons.get(roomId);
    if (button) button.classList.toggle("tm-chat-tab--unread", unread);
    if (!unread) this.markSeen(roomId);
  }

  markSeen(roomId) {
    const box = this.boxes.get(roomId);
    const seen = this.getSeen();
    seen[roomId] = Math.max(seen[roomId] || 0, box?.lastMessageId || 0);
    try {
      localStorage.setItem(SEEN_KEY, JSON.stringify(seen));
    } catch {
      // localStorage full or unavailable
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
      // localStorage full or unavailable
    }
  }
}
