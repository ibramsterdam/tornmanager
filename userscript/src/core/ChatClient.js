const API_BASE = __API_BASE__;

export class ChatClient {
  constructor(auth) {
    this.auth = auth;
  }

  me() {
    const user = this.auth.getUser();
    return { torn_id: user?.torn_id || 0, name: user?.name || "You" };
  }

  listRooms() {
    return this.post("/api/chat/rooms").then((data) => ({
      rooms: data.rooms || [],
      publicRooms: data.public_rooms || [],
    }));
  }

  createRoom(name) {
    return this.post("/api/chat/create_room", { name, encrypted: true }).then((data) => data.room);
  }

  joinByToken(token) {
    return this.post("/api/chat/join", { token }).then((data) => data.room);
  }

  joinPublic(roomId) {
    return this.post("/api/chat/join_public", { room_id: roomId }).then((data) => data.room);
  }

  leaveRoom(roomId) {
    return this.post("/api/chat/leave", { room_id: roomId }).then(() => true);
  }

  roomMembers(roomId) {
    return this.post("/api/chat/room_members", { room_id: roomId }).then((data) => data.members);
  }

  suspend(roomId, tornId) {
    return this.post("/api/chat/suspend", { room_id: roomId, torn_id: tornId }).then(() => true);
  }

  unsuspend(roomId, tornId) {
    return this.post("/api/chat/unsuspend", { room_id: roomId, torn_id: tornId }).then(() => true);
  }

  fetchMessages(roomId, sinceId = 0) {
    return this.post("/api/chat/messages", { room_id: roomId, since_id: sinceId }).then((data) => data.messages);
  }

  sendMessage(roomId, body) {
    return this.post("/api/chat/send_message", { room_id: roomId, body }).then((data) => data.message);
  }

  sendImage(roomId, blob, { body = "", filename = "image.jpg" } = {}) {
    const apiKey = this.auth.getApiKey();
    if (!apiKey) return Promise.reject(new Error("Not authenticated"));

    const form = new FormData();
    form.append("api_key", apiKey);
    form.append("room_id", roomId);
    if (body) form.append("body", body);
    form.append("image", blob, filename);

    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "POST",
        url: `${API_BASE}/api/chat/send_image`,
        headers: { Accept: "application/json" },
        data: form,
        onload(response) {
          let data = null;
          try {
            data = JSON.parse(response.responseText);
          } catch {
            reject(new Error("Invalid response from server"));
            return;
          }

          if (response.status >= 200 && response.status < 300) {
            resolve(data.message);
          } else {
            const error = new Error(data.error || "Upload failed");
            error.status = response.status;
            reject(error);
          }
        },
        onerror() {
          reject(new Error("Network error. Could not reach Tornmanager."));
        },
      });
    });
  }

  fetchImageBytes(path) {
    const url = path.startsWith("http") ? path : `${API_BASE}${path}`;

    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "GET",
        url,
        responseType: "arraybuffer",
        onload(response) {
          if (response.status >= 200 && response.status < 300) {
            resolve(new Uint8Array(response.response));
          } else {
            reject(new Error("Could not load image"));
          }
        },
        onerror() {
          reject(new Error("Network error loading image"));
        },
      });
    });
  }

  post(path, params = {}) {
    const apiKey = this.auth.getApiKey();
    if (!apiKey) return Promise.reject(new Error("Not authenticated"));

    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "POST",
        url: `${API_BASE}${path}`,
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        data: JSON.stringify({ api_key: apiKey, ...params }),
        onload(response) {
          let data = null;
          try {
            data = JSON.parse(response.responseText);
          } catch {
            reject(new Error("Invalid response from server"));
            return;
          }

          if (response.status >= 200 && response.status < 300) {
            resolve(data);
          } else {
            const error = new Error(data.error || "Chat request failed");
            error.status = response.status;
            reject(error);
          }
        },
        onerror() {
          reject(new Error("Network error. Could not reach Tornmanager."));
        },
      });
    });
  }
}
