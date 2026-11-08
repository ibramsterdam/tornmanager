import { Dom } from "@shared/core/Dom.js";
import { SubscriptionSection } from "@shared/ui/SubscriptionSection.js";
import { StorageViewer } from "@shared/ui/StorageViewer.js";
import { SUBSCRIPTION_NOTE, removeKeyRow } from "./SubscriptionScreen.js";

export class SettingsScreen {
  constructor(auth, overlay, api) {
    this.auth = auth;
    this.overlay = overlay;
    this.api = api;
  }

  subtitle() {
    return "settings";
  }

  render(container) {
    this.section?.destroy();
    this.section = new SubscriptionSection(this.auth, { classPrefix: "tc", note: SUBSCRIPTION_NOTE });
    container.appendChild(this.section.render());

    const actions = removeKeyRow(this);
    const storageBtn = Dom.el("button", "tc-btn tc-btn--ghost", "View stored data");
    let viewer = null;
    storageBtn.addEventListener("click", () => {
      if (viewer) {
        viewer.remove();
        viewer = null;
        storageBtn.textContent = "View stored data";
        return;
      }
      viewer = new StorageViewer({ storagePrefix: "tc_", classPrefix: "tc" }).render();
      container.appendChild(viewer);
      storageBtn.textContent = "Hide stored data";
    });
    actions.appendChild(storageBtn);
    container.appendChild(actions);

    container.appendChild(
      Dom.el("p", "tc-hint", "Removing your key deletes it from TornManager and stops the daily reads. To also delete your stored company history, message Bram [2728237].")
    );
  }
}
