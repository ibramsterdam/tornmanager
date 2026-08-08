const STORAGE_KEY = "tm_targets";

export class Targets {
  getAll() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      const list = raw ? JSON.parse(raw) : [];
      return Array.isArray(list) ? list : [];
    } catch {
      return [];
    }
  }

  add(id) {
    const list = this.getAll();
    if (list.includes(id)) return false;

    list.push(id);
    this.save(list);
    return true;
  }

  remove(id) {
    this.save(this.getAll().filter((entry) => entry !== id));
  }

  save(list) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
    } catch {
      // localStorage full or unavailable
    }
  }

  // Accepts a raw ID, a profile link (XID=...) or an attack link (user2ID=...).
  static parseId(value) {
    const text = String(value).trim();
    const match = text.match(/(?:XID=|user2ID=)(\d+)/i) || text.match(/^(\d+)$/);
    return match ? parseInt(match[1], 10) : null;
  }
}
