// End-to-end encryption for private rooms. The AES-GCM key lives only in the
// invite link and each member's localStorage — it is never sent to the server,
// so stored messages are ciphertext the server cannot read.
const KEYS_STORAGE = "tm_chat_keys";

function toBase64Url(bytes) {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function fromBase64Url(str) {
  const padded = str.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((str.length + 3) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

export const ChatCrypto = {
  // A fresh 256-bit key as a URL-safe string for the invite link.
  generateKey() {
    const bytes = new Uint8Array(32);
    crypto.getRandomValues(bytes);
    return toBase64Url(bytes);
  },

  importKey(keyB64) {
    return crypto.subtle.importKey("raw", fromBase64Url(keyB64), "AES-GCM", false, ["encrypt", "decrypt"]);
  },

  async encrypt(keyB64, plaintext) {
    const key = await this.importKey(keyB64);
    const iv = new Uint8Array(12);
    crypto.getRandomValues(iv);
    const ciphertext = await crypto.subtle.encrypt(
      { name: "AES-GCM", iv },
      key,
      new TextEncoder().encode(plaintext)
    );

    const packed = new Uint8Array(iv.length + ciphertext.byteLength);
    packed.set(iv, 0);
    packed.set(new Uint8Array(ciphertext), iv.length);
    return toBase64Url(packed);
  },

  async decrypt(keyB64, payload) {
    const key = await this.importKey(keyB64);
    const packed = fromBase64Url(payload);
    const iv = packed.slice(0, 12);
    const ciphertext = packed.slice(12);
    const plaintext = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, ciphertext);
    return new TextDecoder().decode(plaintext);
  },

  async encryptBytes(keyB64, bytes) {
    const key = await this.importKey(keyB64);
    const iv = new Uint8Array(12);
    crypto.getRandomValues(iv);
    const ciphertext = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, bytes);

    const packed = new Uint8Array(iv.length + ciphertext.byteLength);
    packed.set(iv, 0);
    packed.set(new Uint8Array(ciphertext), iv.length);
    return packed;
  },

  async decryptBytes(keyB64, packed) {
    const key = await this.importKey(keyB64);
    const iv = packed.slice(0, 12);
    const ciphertext = packed.slice(12);
    const plaintext = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, ciphertext);
    return new Uint8Array(plaintext);
  },

  // --- per-room key storage ---

  getKey(roomId) {
    return this.allKeys()[roomId] || null;
  },

  setKey(roomId, keyB64) {
    if (!keyB64) return;
    const keys = this.allKeys();
    keys[roomId] = keyB64;
    try {
      localStorage.setItem(KEYS_STORAGE, JSON.stringify(keys));
    } catch {
      // localStorage full or unavailable
    }
  },

  allKeys() {
    try {
      const raw = localStorage.getItem(KEYS_STORAGE);
      const keys = raw ? JSON.parse(raw) : {};
      return typeof keys === "object" && keys !== null ? keys : {};
    } catch {
      return {};
    }
  },
};
