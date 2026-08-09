import { Dom } from "../core/Dom.js";
import { ChatBox } from "./ChatBox.js";
import { showToast } from "../core/Clipboard.js";

const OPEN_KEY = "tm_chat_open";
const SEEN_KEY = "tm_chat_seen";
const FAB_POS_KEY = "tm_chat_fab_pos";
const FAB_HIDDEN_KEY = "tm_chat_fab_hidden";
const UNREAD_POLL_MS = 8000;
const DRAG_THRESHOLD_PX = 6;

const TM_LOGO =
  '<svg width="34" height="34" viewBox="0 0 32 32"><rect width="32" height="32" rx="7" fill="#0070f3"/><text x="16" y="22" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="15" fill="#fff">TM</text></svg>';

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
      // localStorage full or unavailable
    }
  }

  applyFabPos() {
    try {
      const raw = localStorage.getItem(FAB_POS_KEY);
      if (!raw) return;
      const pos = JSON.parse(raw);
      if (typeof pos?.left === "number" && typeof pos?.top === "number") {
        this.moveFab(pos.left, pos.top);
      }
    } catch {
      // ignore corrupt position data
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
      // localStorage full or unavailable
    }
    if (!visible) this.toggleMenu(false);
    this.updateFabDisplay();
  }

  updateFabDisplay() {
    if (!this.fab) return;
    this.fab.style.display = this.rooms.length && !this.isFabHidden() ? "" : "none";
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
      .then(({ rooms }) => {
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
