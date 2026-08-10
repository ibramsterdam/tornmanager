import { copyText, showToast } from "../core/Clipboard.js";
import { ChatCrypto } from "../core/ChatCrypto.js";
import { Preferences, FONT_SIZES } from "../core/Preferences.js";

const INVITE_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';
const LEAVE_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>';
const MEMBERS_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>';
const LOCK_ICON =
  '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';

export class ChatsSection {
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
    hint.textContent = "Share a room's invite link in any Torn chat — clicking it joins automatically.";
    wrap.appendChild(hint);

    return wrap;
  }

  setBrowseChrome(visible) {
    for (const el of this.browseChrome || []) el.hidden = !visible;
  }

  destroy() {}

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

    this.client
      .createRoom(name)
      .then((room) => {
        // Mint the room's encryption key locally the moment it exists; it
        // never touches the server, only the invite link and localStorage.
        if (room.encrypted) ChatCrypto.setKey(room.id, ChatCrypto.generateKey());
        this.input.value = "";
        this.chatDock.openRoom(room);
        this.refresh();
      })
      .catch((err) => {
        this.error.textContent = err.message || "Could not create the room.";
      })
      .finally(() => {
        button.disabled = false;
        button.textContent = "Create room";
      });
  }

  refresh() {
    this.setBrowseChrome(true);
    this.client
      .listRooms()
      .then(({ rooms, publicRooms }) => this.renderList(rooms, publicRooms))
      .catch(() => {
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
      this.sectionHead("Your rooms", `${LOCK_ICON}<span>End-to-end encrypted</span>`)
    );
    this.listEl.appendChild(this.createForm());

    if (!privateRooms.length) {
      const empty = document.createElement("div");
      empty.className = "tm-chats-empty";
      empty.innerHTML =
        '<svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"><path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2z"/></svg>' +
        '<p class="tm-chats-empty-title">Chat rooms beyond faction chat</p>' +
        '<p class="tm-chats-empty-text">Create a room with anyone in Torn — war squads, trade partners, friends. ' +
        "Share its invite link in any chat and clicking it joins instantly. Free for everyone.</p>";
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
      { value: "integrated", label: "Integrated", beta: true },
    ];

    const current = this.chatDock.buttonMode();
    for (const mode of modes) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "tm-chats-mode";
      button.classList.toggle("tm-chats-mode--active", mode.value === current);
      button.innerHTML = mode.beta
        ? `${mode.label}<span class="tm-chats-beta">beta</span>`
        : mode.label;
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
    const row = this.roomRow(room.name, members, { chip: "anonymous", chipClass: "tm-chats-room-chip--anon" });
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
    back.innerHTML =
      '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>';
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

    this.client
      .roomMembers(room.id)
      .then((members) => this.renderMembers(room, list, members))
      .catch((err) => {
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

    for (const member of members) {
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
          const call = member.suspended
            ? this.client.unsuspend(room.id, member.torn_id)
            : this.client.suspend(room.id, member.torn_id);
          call
            .then(() => this.openMembers(room))
            .catch((err) => {
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
      hash = (hash * 31 + name.charCodeAt(i)) | 0;
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
      showToast("Encryption key missing — rejoin via an invite link first");
      return;
    }
    copyText(`${room.invite_url}~${key}`, "Invite link copied");
  }

  openPublic(room) {
    this.client
      .joinPublic(room.id)
      .then((joined) => {
        this.chatDock.openRoom(joined);
        this.refresh();
      })
      .catch((err) => {
        this.error.textContent = err.message || "Could not open the room.";
      });
  }

  renderRoom(room) {
    const locked = room.encrypted && !ChatCrypto.getKey(room.id);
    const members = `${room.member_count} member${room.member_count === 1 ? "" : "s"}`;
    const row = room.host
      ? this.roomRow(room.name, members, { chip: "Host", chipClass: "tm-chats-room-chip--host" })
      : this.roomRow(room.name, members);
    row.onclick = () => this.chatDock.openRoomById(room.id);

    if (locked) {
      const chip = document.createElement("span");
      chip.className = "tm-chats-room-chip tm-chats-room-chip--locked";
      chip.textContent = "Locked";
      chip.title = "This device doesn't have this room's key. Open its invite link here to unlock.";
      row.querySelector(".tm-chats-room-nameline").appendChild(chip);
    }

    const actions = row.querySelector(".tm-chats-room-actions");

    actions.appendChild(
      this.iconButton(MEMBERS_ICON, "Members", () => this.openMembers(room))
    );

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

  // A compact one-line room row: click anywhere to open; small icon buttons on
  // the right handle secondary actions without stealing the row's click.
  roomRow(name, meta, { chip, chipClass = "" } = {}) {
    const row = document.createElement("div");
    row.className = "tm-chats-room";
    row.setAttribute("role", "button");
    row.tabIndex = 0;

    const info = document.createElement("div");
    info.className = "tm-chats-room-info";

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

    const metaEl = document.createElement("span");
    metaEl.className = "tm-chats-room-meta";
    metaEl.textContent = meta;

    info.appendChild(nameLine);
    info.appendChild(metaEl);

    const actions = document.createElement("div");
    actions.className = "tm-chats-room-actions";

    row.appendChild(info);
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
