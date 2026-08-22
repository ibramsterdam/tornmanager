import { Dom } from "@shared/core/Dom.js";
import { SubscriptionSection } from "@shared/ui/SubscriptionSection.js";
import { StorageViewer } from "@shared/ui/StorageViewer.js";
import { SUBSCRIPTION_NOTE } from "./SubscriptionScreen.js";

export class SettingsScreen {
  constructor(auth, overlay) {
    this.auth = auth;
    this.overlay = overlay;
  }

  subtitle() {
    return "settings";
  }

  render(container) {
    this.section?.destroy();
    this.section = new SubscriptionSection(this.auth, {
      classPrefix: "rc",
      note: SUBSCRIPTION_NOTE,
    });
    container.appendChild(this.section.render());

    const actions = Dom.el("div", "rc-actions-row");
    const removeKey = Dom.el("button", "rc-btn-danger", "Remove API key");
    removeKey.addEventListener("click", () => {
      this.section?.destroy();
      this.auth.clear();
      this.overlay.open();
    });
    actions.appendChild(removeKey);

    const storageBtn = Dom.el("button", "rc-btn rc-btn--ghost", "View stored data");
    let viewer = null;
    storageBtn.addEventListener("click", () => {
      if (viewer) {
        viewer.remove();
        viewer = null;
        storageBtn.textContent = "View stored data";
        return;
      }
      viewer = new StorageViewer({ storagePrefix: "rc_", classPrefix: "rc" }).render();
      container.appendChild(viewer);
      storageBtn.textContent = "Hide stored data";
    });
    actions.appendChild(storageBtn);
    container.appendChild(actions);
  }
}
