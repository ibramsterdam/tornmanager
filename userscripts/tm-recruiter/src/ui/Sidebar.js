import { Dom } from "@shared/core/Dom.js";

export class Sidebar {
  constructor(overlay) {
    this.overlay = overlay;
  }

  init() {
    Dom.ready("#sidebar", (sidebar) => this.onReady(sidebar));
  }

  onReady(sidebar) {
    const icons = sidebar.querySelector("ul[class^='status-icon']");
    if (!icons || document.getElementById("recruiter-icon")) return;

    const icon = document.createElement("li");
    icon.id = "recruiter-icon";
    icon.className = "recruiter-icon";
    icon.onclick = () => this.overlay.toggle();

    icons.appendChild(icon);
  }
}
