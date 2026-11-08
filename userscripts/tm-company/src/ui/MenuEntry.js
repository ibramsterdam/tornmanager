import { Dom } from "@shared/core/Dom.js";

export class MenuEntry {
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
    if (menu.querySelector(".company-menu-item")) return;

    const item = document.createElement("li");
    item.className = "link company-menu-item";

    const link = document.createElement("a");
    link.href = window.location.href;
    link.innerHTML = '<span class="company-menu-icon"></span><span>Company</span>';
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
