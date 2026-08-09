const FONT_KEY = "tm_chat_font_px";
const DEFAULT_FONT = 12.5;

export const FONT_SIZES = [
  { label: "S", px: 11 },
  { label: "M", px: 12.5 },
  { label: "L", px: 14.5 },
  { label: "XL", px: 17 },
];

export const Preferences = {
  chatFontSize() {
    const value = parseFloat(localStorage.getItem(FONT_KEY));
    return value > 0 ? value : DEFAULT_FONT;
  },

  setChatFontSize(px) {
    try {
      localStorage.setItem(FONT_KEY, String(px));
    } catch {
      // localStorage full or unavailable
    }
    this.applyChatFontSize();
  },

  // Exposed as a CSS variable the chat box reads, so a change reflows every
  // open box (and future ones) instantly.
  applyChatFontSize() {
    document.documentElement.style.setProperty("--tm-chat-font", `${this.chatFontSize()}px`);
  },
};
