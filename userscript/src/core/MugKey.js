const STORAGE_KEY = "tm_mug_key";

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
};
