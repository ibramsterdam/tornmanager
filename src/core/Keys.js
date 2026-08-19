import { Store } from "./Store.js";

export class Keys {
  constructor() {
    this.list = Store.get("keys", []);
    this.cursor = 0;
  }

  save() {
    Store.set("keys", this.list);
  }

  all() {
    return this.list;
  }

  active() {
    return this.list.filter((k) => k.valid).map((k) => k.key);
  }

  next() {
    const pool = this.active();
    if (!pool.length) return null;
    this.cursor = (this.cursor + 1) % pool.length;
    return pool[this.cursor];
  }

  async add(key, api) {
    key = key.trim();
    if (!key) throw new Error("Paste a key first");
    if (this.list.some((k) => k.key === key)) throw new Error("That key is already in the pool");

    const basic = await api.call("/user/basic", {}, key);
    const owner = basic.basic || basic.profile || basic;
    if (!owner?.id) throw new Error("Could not resolve the key's owner");

    const duplicate = this.list.find((k) => k.ownerId === owner.id);
    if (duplicate) {
      throw new Error(`Also owned by ${owner.name} [${owner.id}], same player as an existing key. Extra keys from one player share the same 100/min limit.`);
    }

    let accessType = "Unknown";
    try {
      const info = await api.call("/key/info", {}, key);
      accessType = info.info?.access?.type || info.access?.type || "Unknown";
    } catch {
      accessType = "Public";
    }

    const entry = {
      key,
      ownerId: owner.id,
      ownerName: owner.name,
      accessType,
      valid: true,
      addedAt: Date.now(),
      callsToday: 0,
      dayStamp: todayStamp(),
    };
    this.list.push(entry);
    this.save();
    return entry;
  }

  remove(key) {
    this.list = this.list.filter((k) => k.key !== key);
    this.save();
  }

  markInvalid(key) {
    const entry = this.list.find((k) => k.key === key);
    if (entry) {
      entry.valid = false;
      this.save();
    }
  }

  recordCall(key) {
    const entry = this.list.find((k) => k.key === key);
    if (!entry) return;
    const stamp = todayStamp();
    if (entry.dayStamp !== stamp) {
      entry.dayStamp = stamp;
      entry.callsToday = 0;
    }
    entry.callsToday += 1;
    this.save();
  }
}

function todayStamp() {
  return new Date().toISOString().slice(0, 10);
}
