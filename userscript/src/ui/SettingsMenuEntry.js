import { Dom } from "../core/Dom.js";

const TM_LOGO =
  '<svg viewBox="0 0 32 32" width="16" height="16"><rect width="32" height="32" rx="7" fill="#0070f3"/><text x="16" y="22" text-anchor="middle" font-family="Arial,sans-serif" font-weight="700" font-size="15" fill="#fff">TM</text></svg>';

// Adds a "TornManager" item to Torn's account dropdown (the avatar menu).
// Torn keeps this menu in the DOM and toggles it with a class, so a one-shot
// injection persists — but we re-check on click in case Torn rebuilds it.
export class SettingsMenuEntry {
  constructor(overlay) {
    this.overlay = overlay;
  }

  init() {
    Dom.ready("ul.settings-menu", (menu) => this.inject(menu));

    document.addEventListener("click", (e) => {
      if (e.target.closest(".avatar, .settings-menu")) this.injectAll();
    });
  }

  injectAll() {
    document.querySelectorAll("ul.settings-menu").forEach((menu) => this.inject(menu));
  }

  inject(menu) {
    if (menu.querySelector(".tornmanager-menu-item")) return;

    const item = document.createElement("li");
    item.className = "link tornmanager-menu-item";

    const link = document.createElement("a");
    link.href = "#";
    link.innerHTML = `${TM_LOGO}<span>TornManager</span>`;
    link.addEventListener("click", (e) => {
      e.preventDefault();
      this.overlay.open();
    });

    item.appendChild(link);

    const serverInfo = menu.querySelector(".server-info");
    if (serverInfo) {
      menu.insertBefore(item, serverInfo);
    } else {
      menu.appendChild(item);
    }
  }
}
