import { copyText } from "../core/Clipboard.js";

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
      .then((rooms) => this.renderList(rooms))
      .catch(() => {
        this.listEl.innerHTML = "";
        const error = document.createElement("p");
        error.className = "tm-chats-empty";
        error.textContent = "Could not load your rooms.";
        this.listEl.appendChild(error);
      });
  }

  renderList(rooms) {
    this.listEl.innerHTML = "";

    if (!rooms.length) {
      const empty = document.createElement("p");
      empty.className = "tm-chats-empty";
      empty.textContent = "No rooms yet. Create one, or join via an invite link.";
      this.listEl.appendChild(empty);
      return;
    }

    for (const room of rooms) {
      this.listEl.appendChild(this.renderRoom(room));
    }
  }

  renderRoom(room) {
    const row = document.createElement("div");
    row.className = "tm-chats-room";

    const info = document.createElement("div");
    info.className = "tm-chats-room-info";

    const name = document.createElement("span");
    name.className = "tm-chats-room-name";
    name.textContent = room.name;

    const meta = document.createElement("span");
    meta.className = "tm-chats-room-meta";
    meta.textContent = `${room.member_count} member${room.member_count === 1 ? "" : "s"}${room.host ? " · host" : ""}`;

    info.appendChild(name);
    info.appendChild(meta);

    const actions = document.createElement("div");
    actions.className = "tm-chats-room-actions";

    const open = document.createElement("button");
    open.type = "button";
    open.className = "tm-chats-btn tm-chats-btn--primary";
    open.textContent = "Open";
    open.onclick = () => this.chatDock.openRoomById(room.id);
    actions.appendChild(open);

    if (room.host && room.invite_url) {
      const invite = document.createElement("button");
      invite.type = "button";
      invite.className = "tm-chats-btn";
      invite.textContent = "Invite";
      invite.onclick = () => copyText(room.invite_url, "Invite link copied");
      actions.appendChild(invite);
    }

    const leave = document.createElement("button");
    leave.type = "button";
    leave.className = "tm-chats-btn tm-chats-btn--danger";
    leave.textContent = "Leave";
    leave.onclick = () => {
      this.client.leaveRoom(room.id).then(() => {
        this.chatDock.refresh();
        this.refresh();
      });
    };
    actions.appendChild(leave);

    row.appendChild(info);
    row.appendChild(actions);
    return row;
  }
}
