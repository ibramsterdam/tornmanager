import { copyText, showToast } from "../core/Clipboard.js";
import { ChatCrypto } from "../core/ChatCrypto.js";
import { Preferences, FONT_SIZES } from "../core/Preferences.js";

const INVITE_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>';
const LEAVE_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>';
const MANAGE_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>';

export class ChatsSection {
  constructor(chatDock) {
    this.chatDock = chatDock;
    this.client = chatDock.client;
  }

  render() {
    this.section = document.createElement("div");
    this.section.className = "tm-chats";

    this.section.appendChild(this.createForm());

    this.listEl = document.createElement("div");
    this.listEl.className = "tm-chats-list";
    this.section.appendChild(this.listEl);

    const hint = document.createElement("p");
    hint.className = "tm-chats-hint";
    hint.textContent = "Share a room's invite link in any Torn chat — clicking it joins automatically.";
    this.section.appendChild(hint);

    const toggle = document.createElement("label");
    toggle.className = "tm-chats-toggle";

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = !this.chatDock.isFabHidden();
    checkbox.onchange = () => this.chatDock.setFabVisible(checkbox.checked);

    const caption = document.createElement("span");
    caption.textContent = "Show floating chat button (drag it anywhere)";

    toggle.appendChild(checkbox);
    toggle.appendChild(caption);
    this.section.appendChild(toggle);

    this.section.appendChild(this.createFontControl());

    this.refresh();

    return this.section;
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
      this.listEl.appendChild(this.sectionLabel("Your rooms"));
      this.listEl.appendChild(this.sectionNote("🔒 End-to-end encrypted — only people with the invite link can read them. A room self-destructs 7 days after everyone leaves."));
      for (const room of privateRooms) this.listEl.appendChild(this.renderRoom(room));
    }

    if (publicRooms.length) {
      this.listEl.appendChild(this.sectionLabel("Public rooms · anonymous"));
      this.listEl.appendChild(this.sectionNote("Messages older than 24 hours are deleted."));
      for (const room of publicRooms) {
        this.listEl.appendChild(this.renderPublicRoom(room, joinedIds.has(room.id)));
      }
    }
  }

  sectionLabel(text) {
    const label = document.createElement("p");
    label.className = "tm-chats-section-label";
    label.textContent = text;
    return label;
  }

  createFontControl() {
    const row = document.createElement("div");
    row.className = "tm-chats-fontrow";

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

  sectionNote(text) {
    const note = document.createElement("p");
    note.className = "tm-chats-section-note";
    note.textContent = text;
    return note;
  }

  renderPublicRoom(room, joined) {
    const members = `${room.member_count} member${room.member_count === 1 ? "" : "s"}`;
    const row = this.roomRow(room.name, `${members} · anonymous`);
    row.onclick = () => this.openPublic(room);

    if (!joined) {
      const tag = document.createElement("span");
      tag.className = "tm-chats-room-tag";
      tag.textContent = "Join";
      row.querySelector(".tm-chats-room-actions").appendChild(tag);
    }

    return row;
  }

  // A host-only sub-view: the room's roster with suspend/unsuspend per member,
  // rendered over the room list with a back button.
  openManage(room) {
    this.listEl.innerHTML = "";

    const header = document.createElement("div");
    header.className = "tm-manage-head";

    const back = document.createElement("button");
    back.type = "button";
    back.className = "tm-manage-back";
    back.textContent = "← Back";
    back.onclick = () => this.refresh();

    const title = document.createElement("span");
    title.className = "tm-manage-title";
    title.textContent = room.name;

    header.appendChild(back);
    header.appendChild(title);
    this.listEl.appendChild(header);

    const list = document.createElement("div");
    list.className = "tm-manage-members";
    list.textContent = "Loading members...";
    this.listEl.appendChild(list);

    this.client
      .roomMembers(room.id)
      .then((members) => this.renderManageMembers(room, list, members))
      .catch((err) => {
        list.textContent = err.message || "Could not load members.";
      });
  }

  renderManageMembers(room, list, members) {
    list.innerHTML = "";
    if (!members.length) {
      list.textContent = "No members.";
      return;
    }

    for (const member of members) {
      const row = document.createElement("div");
      row.className = "tm-manage-member";

      const info = document.createElement("div");
      info.className = "tm-manage-member-info";
      const name = document.createElement("span");
      name.className = "tm-manage-member-name";
      name.textContent = member.name;
      info.appendChild(name);

      if (member.host || member.suspended) {
        const tag = document.createElement("span");
        tag.className = member.host ? "tm-manage-tag" : "tm-manage-tag tm-manage-tag--suspended";
        tag.textContent = member.host ? "host" : "suspended";
        info.appendChild(tag);
      }

      row.appendChild(info);

      if (!member.host) {
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
            .then(() => this.openManage(room))
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
    const members = `${room.member_count} member${room.member_count === 1 ? "" : "s"}`;
    const row = this.roomRow(room.name, `${members}${room.host ? " · host" : ""}`);
    row.onclick = () => this.chatDock.openRoomById(room.id);

    const actions = row.querySelector(".tm-chats-room-actions");

    if (room.host) {
      actions.appendChild(
        this.iconButton(MANAGE_ICON, "Manage members", () => this.openManage(room))
      );
    }

    if (room.host && room.invite_url) {
      actions.appendChild(
        this.iconButton(INVITE_ICON, "Copy invite link", () => this.copyInvite(room))
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
  roomRow(name, meta) {
    const row = document.createElement("div");
    row.className = "tm-chats-room";
    row.setAttribute("role", "button");
    row.tabIndex = 0;

    const info = document.createElement("div");
    info.className = "tm-chats-room-info";

    const nameEl = document.createElement("span");
    nameEl.className = "tm-chats-room-name";
    nameEl.textContent = name;

    const metaEl = document.createElement("span");
    metaEl.className = "tm-chats-room-meta";
    metaEl.textContent = meta;

    info.appendChild(nameEl);
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
