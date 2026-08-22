// Namespaced JSON wrapper over localStorage ("tm_user", "rc_keys", ...).
export function createStore(prefix) {
  return {
    get(key, fallback = null) {
      try {
        const raw = localStorage.getItem(prefix + key);
        return raw === null ? fallback : JSON.parse(raw);
      } catch {
        return fallback;
      }
    },

    set(key, value) {
      localStorage.setItem(prefix + key, JSON.stringify(value));
    },

    remove(key) {
      localStorage.removeItem(prefix + key);
    },
  };
}
