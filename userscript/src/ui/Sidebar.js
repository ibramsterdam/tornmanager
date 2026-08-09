import { Dom } from "../core/Dom.js";

// Mobile layouts have no desktop sidebar to inject into — after this grace
// period we mount a floating launcher instead.
const FALLBACK_DELAY_MS = 4000;

export class Sidebar {
  constructor(overlay) {
    this.overlay = overlay;
    this.injected = false;
  }

  init() {
    Dom.ready("#sidebar", (sidebar) => this.onReady(sidebar));

    Dom.ready("body", () => {
      setTimeout(() => this.mountFallback(), FALLBACK_DELAY_MS);
    });
  }

  onReady(sidebar) {
    const icons = sidebar.querySelector("ul[class^='status-icon']");
    if (!icons || document.getElementById("tornmanager-icon")) return;

    const icon = document.createElement("li");
    icon.id = "tornmanager-icon";
    icon.className = "tornmanager-icon";
    icon.onclick = () => this.overlay.toggle();

    icons.appendChild(icon);
    this.injected = true;
    document.getElementById("tornmanager-launcher")?.remove();
  }

  mountFallback() {
    if (this.injected || document.getElementById("tornmanager-launcher")) return;

    const button = document.createElement("button");
    button.type = "button";
    button.id = "tornmanager-launcher";
    button.className = "tm-launcher";
    button.title = "TornManager";
    button.textContent = "TM";
    button.onclick = () => this.overlay.toggle();

    document.body.appendChild(button);
  }
}
