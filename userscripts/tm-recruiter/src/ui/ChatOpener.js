import { Dom } from "@shared/core/Dom.js";

export class ChatOpener {
  static chatUrl(playerId) {
    return `https://www.torn.com/profiles.php?XID=${playerId}#rc-chat`;
  }

  init() {
    if (!location.pathname.startsWith("/profiles.php")) return;
    if (!location.hash.includes("rc-chat")) return;

    Dom.ready(".profile-button-initiateChat", (button) => {
      history.replaceState(null, "", location.href.replace("#rc-chat", ""));
      // Torn binds the handler after rendering the button, give it a moment.
      setTimeout(() => button.click(), 600);
    });
  }
}
