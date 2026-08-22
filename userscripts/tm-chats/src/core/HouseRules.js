const STORAGE_KEY = "tm_chat_house_rules";

export const HouseRules = {
  accepted() {
    try {
      return !!localStorage.getItem(STORAGE_KEY);
    } catch {
      return false;
    }
  },

  accept() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ accepted_at: new Date().toISOString() }));
    } catch {
      return;
    }
  },
};
