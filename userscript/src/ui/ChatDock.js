import { Dom } from "../core/Dom.js";
import { ChatBox } from "./ChatBox.js";
import { showToast } from "../core/Clipboard.js";

const OPEN_KEY = "tm_chat_open";
const SEEN_KEY = "tm_chat_seen";
const UNREAD_POLL_MS = 8000;

const CHAT_ICON =
  '<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2z"/></svg>';

export class ChatDock {
  constructor(auth, client, logger) {
    this.auth = auth;
    this.client = client;
    this.logger = logger;
    this.rooms = [];
    this.boxes = new Map();
    this.menuItems = new Map();
    this.unread = new Set();
    this.menuOpen = false;
    this.unreadInterval = null;
  }

  init() {
    if (!this.auth.isAuthenticated()) return;

    Dom.ready("body", () => {
      this.fab = document.createElement("button");
      this.fab.type = "button";
      this.fab.className = "tm-chat-fab";
      this.fab.title = "TornManager chats";
      this.fab.innerHTML = `${CHAT_ICON}<span class="tm-chat-fab-dot"></span>`;
      this.fab.style.display = "none";
      this.fab.onclick = (e) => {
        e.stopPropagation();
        this.toggleMenu(!this.menuOpen);
      };

      this.menu = document.createElement("div");
      this.menu.className = "tm-chat-menu";

      this.boxesEl = document.createElement("div");
      this.boxesEl.className = "tm-chat-boxes";

      document.body.appendChild(this.fab);
      document.body.appendChild(this.menu);
      document.body.appendChild(this.boxesEl);

      document.addEventListener("click", (e) => {
        if (this.menuOpen && !this.menu.contains(e.target)) this.toggleMenu(false);
      });

      this.handleInviteHash().then(() => this.refresh());
      this.unreadInterval = setInterval(() => this.pollUnread(), UNREAD_POLL_MS);
    });
  }

  toggleMenu(open) {
    this.menuOpen = open;
    this.menu.classList.toggle("tm-chat-menu--open", open);
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
      showToast(err.message || "Could not join the chat room");
    }
  }

  refresh() {
    return this.client
      .listRooms()
      .then((rooms) => {
        this.rooms = rooms;
        this.renderMenu();
        this.syncBoxes();
      })
      .catch((err) => this.logger.log(err, "chat rooms list"));
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

    this.fab.style.display = this.rooms.length ? "" : "none";
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

      this.client
        .fetchMessages(room.id, seen[room.id] || 0)
        .then((messages) => {
          if (messages.length) this.setUnread(room.id, true);
        })
        .catch(() => {});
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
    const openIds = this.getOpenIds();
    for (const [id, item] of this.menuItems) {
      item.classList.toggle("tm-chat-menu-item--unread", this.unread.has(id));
      item.classList.toggle("tm-chat-menu-item--open", openIds.includes(id));
    }
    this.fab?.classList.toggle("tm-chat-fab--unread", this.unread.size > 0);
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
