import { post as apiPost } from "@shared/core/ServerApi.js";

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

  sendImage(roomId, imageBase64, { body = "" } = {}) {
    return this.post("/api/chat/send_image", { room_id: roomId, body, image_base64: imageBase64 }).then(
      (data) => data.message
    );
  }

  fetchImage(roomId, messageId) {
    return this.post("/api/chat/image", { room_id: roomId, message_id: messageId }).then((data) => data.data);
  }

  post(path, params = {}) {
    const token = this.auth.getToken();
    if (!token) return Promise.reject(new Error("Not authenticated"));

    return apiPost(path, params, { token });
  }
}
