// Mock chat backend for UI development — same method signatures as the future
// ChatClient (Rails API), but stores everything in localStorage and simulates
// teammates. Swap for the real client in main.js once the API exists.
const STORAGE_KEY = "tm_mock_chat";
const FAKE_MEMBERS = [
  { torn_id: 2527957, name: "Runcor" },
  { torn_id: 3384691, name: "plop" },
];
const FAKE_REPLIES = [
  "on it",
  "he's landing in 2",
  "got him",
  "wait for the chain bonus",
  "someone cover me",
  "medding up, 30s",
  "pushing now",
  "which one first?",
];

export class MockChatClient {
  constructor(auth) {
    this.auth = auth;
  }

  me() {
    const user = this.auth.getUser();
    return { torn_id: user?.torn_id || 0, name: user?.name || "You" };
  }

  listRooms() {
    return this.respond(() => {
      const all = Object.values(this.load().rooms);
      return {
        rooms: all.map((room) => this.roomInfo(room)),
        publicRooms: all.filter((room) => room.kind === "public").map((room) => this.roomInfo(room)),
      };
    });
  }

  joinPublic(roomId) {
    return this.respond(() => {
      const store = this.load();
      const room = store.rooms[roomId];
      if (!room) throw new Error("Room not found.");
      return this.roomInfo(room);
    });
  }

  createRoom(name) {
    return this.respond(() => {
      const store = this.load();
      const me = this.me();
      const id = `room_${Object.keys(store.rooms).length + 1}_${Math.random().toString(36).slice(2, 8)}`;

      const room = {
        id,
        name,
        invite_token: Math.random().toString(36).slice(2, 18),
        host_torn_id: me.torn_id,
        members: [me, ...FAKE_MEMBERS],
        messages: [],
        next_message_id: 1,
      };

      this.pushMessage(room, { system: true, body: "Room created. Share the invite link to add people." });
      FAKE_MEMBERS.forEach((m) => this.pushMessage(room, { ...m, system: true, body: `${m.name} joined.` }));

      store.rooms[id] = room;
      this.save(store);
      this.scheduleFakeReply(id, "what's the plan?");

      return this.roomInfo(room);
    });
  }

  joinByToken(token) {
    return this.respond(() => {
      const store = this.load();
      const existing = Object.values(store.rooms).find((room) => room.invite_token === token);
      if (existing) return this.roomInfo(existing);

      // Simulate joining someone else's room: Runcor hosts it.
      const me = this.me();
      const id = `room_joined_${Math.random().toString(36).slice(2, 8)}`;
      const room = {
        id,
        name: "Hawaii squad",
        invite_token: token,
        host_torn_id: FAKE_MEMBERS[0].torn_id,
        members: [...FAKE_MEMBERS, me],
        messages: [],
        next_message_id: 1,
      };

      this.pushMessage(room, { ...FAKE_MEMBERS[0], body: "everyone board the plane" });
      this.pushMessage(room, { ...FAKE_MEMBERS[1], body: "wheels up in 5" });
      this.pushMessage(room, { system: true, body: `${me.name} joined.` });

      store.rooms[id] = room;
      this.save(store);

      return this.roomInfo(room);
    });
  }

  roomMembers(roomId) {
    return this.respond(() => {
      const room = this.load().rooms[roomId];
      if (!room) return [];
      const me = this.me();
      return room.members.map((m) => ({
        torn_id: m.torn_id,
        name: m.name,
        host: room.host_torn_id === m.torn_id,
        suspended: (room.suspended || []).includes(m.torn_id),
      }));
    });
  }

  suspend(roomId, tornId) {
    return this.respond(() => {
      const store = this.load();
      const room = store.rooms[roomId];
      if (room) {
        room.suspended = [...new Set([...(room.suspended || []), tornId])];
        this.save(store);
      }
      return true;
    });
  }

  unsuspend(roomId, tornId) {
    return this.respond(() => {
      const store = this.load();
      const room = store.rooms[roomId];
      if (room) {
        room.suspended = (room.suspended || []).filter((id) => id !== tornId);
        this.save(store);
      }
      return true;
    });
  }

  leaveRoom(roomId) {
    return this.respond(() => {
      const store = this.load();
      delete store.rooms[roomId];
      this.save(store);
      return true;
    });
  }

  fetchMessages(roomId, sinceId = 0) {
    return this.respond(() => {
      const room = this.load().rooms[roomId];
      if (!room) return [];
      return room.messages.filter((message) => message.id > sinceId);
    });
  }

  sendMessage(roomId, body) {
    return this.respond(() => {
      const store = this.load();
      const room = store.rooms[roomId];
      if (!room) throw new Error("Room no longer exists.");

      const message = this.pushMessage(room, { ...this.me(), body });
      this.save(store);

      if (Math.random() < 0.8) {
        const reply = FAKE_REPLIES[Math.floor(Math.random() * FAKE_REPLIES.length)];
        this.scheduleFakeReply(roomId, reply);
      }

      return message;
    });
  }

  // --- internals ---

  respond(fn) {
    return new Promise((resolve, reject) => {
      setTimeout(() => {
        try {
          resolve(fn());
        } catch (err) {
          reject(err);
        }
      }, 150 + Math.random() * 250);
    });
  }

  roomInfo(room) {
    const me = this.me();
    const host = room.host_torn_id === me.torn_id;
    return {
      id: room.id,
      name: room.name,
      kind: room.kind || "private",
      anonymous: !!room.anonymous,
      encrypted: !!room.encrypted,
      host,
      suspended: false,
      member_count: room.members.length,
      invite_url: host ? `https://www.torn.com/index.php#tmchat=${room.invite_token}` : null,
    };
  }

  pushMessage(room, { torn_id = 0, name = "", body, system = false }) {
    const message = {
      id: room.next_message_id++,
      torn_id,
      name,
      body,
      system,
      at: new Date().toISOString(),
    };
    room.messages.push(message);
    return message;
  }

  scheduleFakeReply(roomId, body) {
    const member = FAKE_MEMBERS[Math.floor(Math.random() * FAKE_MEMBERS.length)];
    setTimeout(() => {
      const store = this.load();
      const room = store.rooms[roomId];
      if (!room) return;
      this.pushMessage(room, { ...member, body });
      this.save(store);
    }, 1500 + Math.random() * 3000);
  }

  load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      const store = raw ? JSON.parse(raw) : null;
      return store && store.rooms ? store : { rooms: {} };
    } catch {
      return { rooms: {} };
    }
  }

  save(store) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(store));
    } catch {
      // localStorage full or unavailable
    }
  }
}
