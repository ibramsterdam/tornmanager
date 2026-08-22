const STORAGE_KEY = "tm_mug_key";

const INCORRECT_KEY = 2;
const OWNER_IN_FEDERAL_JAIL = 10;
const DISABLED_BY_INACTIVITY = 13;
const PAUSED_BY_OWNER = 18;
const DEAD_KEY_CODES = new Set([INCORRECT_KEY, OWNER_IN_FEDERAL_JAIL, DISABLED_BY_INACTIVITY, PAUSED_BY_OWNER]);

export const MugKey = {
  get() {
    try {
      return localStorage.getItem(STORAGE_KEY) || null;
    } catch {
      return null;
    }
  },

  set(key) {
    try {
      localStorage.setItem(STORAGE_KEY, key);
    } catch {
      return;
    }
  },

  clear() {
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      return;
    }
  },

  invalidKeyError(err) {
    if (!DEAD_KEY_CODES.has(err?.code)) return null;
    this.clear();
    return new Error(`Torn rejected the saved key (${err.message}). It was removed. Connect a new key on the Mugging tab.`);
  },
};
