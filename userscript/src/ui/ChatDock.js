import { Dom } from "../core/Dom.js";
import { ChatBox } from "./ChatBox.js";
import { showToast } from "../core/Clipboard.js";
import { ChatCrypto } from "../core/ChatCrypto.js";

const OPEN_KEY = "tm_chat_open";
const SEEN_KEY = "tm_chat_seen";
const FAB_POS_KEY = "tm_chat_fab_pos";
const BUTTON_MODE_KEY = "tm_chat_button_mode";
const LEGACY_HIDDEN_KEY = "tm_chat_fab_hidden";
const BUTTON_MODES = ["none", "floating", "integrated"];
const UNREAD_POLL_MS = 8000;
const DRAG_THRESHOLD_PX = 6;

const TM_LOGO =
  '<svg width="34" height="34" viewBox="0 0 32 32"><rect width="32" height="32" rx="7" fill="#0070f3"/><text x="16" y="22" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="15" fill="#fff">TM</text></svg>';

// An <img> (not inline <svg>): Torn's chat code calls e.className.includes()
// while walking the bar, which throws on SVG elements. An <img> is safe.
const TM_LOGO_URI =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='7' fill='%230070f3'/%3E%3Ctext x='16' y='22' text-anchor='middle' font-family='Arial,sans-serif' font-weight='700' font-size='15' fill='white'%3ETM%3C/text%3E%3C/svg%3E";

const REINJECT_DEBOUNCE_MS = 200;

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
        if (!this.menuOpen) return;
        if (this.menu.contains(e.target)) return;
        if (this.fab.contains(e.target)) return;
        if (this.barLauncher?.contains(e.target)) return;
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
    if (this.buttonMode() !== "integrated" || !this.rooms.length) {
      document.getElementById("tm_chat_launcher")?.remove();
      return;
    }
    if (document.getElementById("tm_chat_launcher")) return;

    const settingsBtn = document.getElementById("notes_settings_button");
    const bar = settingsBtn?.parentElement;
    if (!bar) return; // No Torn chat bar here (e.g. mobile) — nothing to dock into.

    const button = document.createElement("button");
    button.type = "button";
    button.id = "tm_chat_launcher";
    button.className = settingsBtn.className; // clone Torn's utility-button styling
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
    // Anchor the menu to whichever launcher is active: the bar button in
    // integrated mode, otherwise the floating button.
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
    // Migrate the old hide checkbox: hidden -> none, otherwise floating.
    return localStorage.getItem(LEGACY_HIDDEN_KEY) === "1" ? "none" : "floating";
  }

  setButtonMode(mode) {
    try {
      localStorage.setItem(BUTTON_MODE_KEY, mode);
    } catch {
      // localStorage full or unavailable
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
    // #tmchat=<serverToken>~<encKey> — only the server token is sent to the
    // server; the encryption key (second half) stays in this browser.
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
    return this.client
      .listRooms()
      .then(({ rooms }) => {
        this.rooms = rooms;
        this.renderMenu();
        this.syncBoxes();
      })
      .catch((err) => {
        if (err.suspended) {
          this.overlay?.markSuspended(err.message);
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
    const room = this.rooms.find((r) => r.id === roomId);
    if (!room) return;

    const box = new ChatBox(room, this.client, {
      onMinimize: (id) => this.markOpen(id, false),
      onOpenMembers: (r) => this.overlay?.openChatMembers(r),
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
