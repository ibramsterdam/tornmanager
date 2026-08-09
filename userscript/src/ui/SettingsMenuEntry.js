import { Dom } from "../core/Dom.js";

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

    // A background-image span, not an inline <svg>: Torn's own sidebar code
    // walks this menu calling e.className.includes(), which throws on SVG
    // elements (their className isn't a string). Keep our DOM svg-free here.
    const link = document.createElement("a");
    link.href = "#";
    link.innerHTML = '<span class="tornmanager-menu-icon"></span><span>TornManager</span>';
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
