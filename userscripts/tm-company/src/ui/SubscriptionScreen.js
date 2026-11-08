import { Dom } from "@shared/core/Dom.js";
import { SubscriptionSection } from "@shared/ui/SubscriptionSection.js";

export const SUBSCRIPTION_NOTE =
  "TM Company requires an active TornManager subscription. The script stays locked until your subscription is active.";

export class SubscriptionScreen {
  constructor(auth, overlay, api) {
    this.auth = auth;
    this.overlay = overlay;
    this.api = api;
  }

  subtitle() {
    return "subscription";
  }

  render(container) {
    this.section?.destroy();
    this.section = new SubscriptionSection(this.auth, {
      classPrefix: "tc",
      note: SUBSCRIPTION_NOTE,
      onUpdate: (sub) => {
        if (sub.active && this.auth.isSubscribed()) this.overlay.open();
      },
    });
    container.appendChild(this.section.render());
    container.appendChild(removeKeyRow(this));
  }
}

export function removeKeyRow(screen) {
  const actions = Dom.el("div", "tc-actions-row");
  const removeKey = Dom.el("button", "tc-btn-danger", "Remove API key");
  removeKey.addEventListener("click", async () => {
    screen.section?.destroy();
    await screen.api.revokeKey().catch(() => null);
    screen.auth.clear();
    screen.overlay.open();
  });
  actions.appendChild(removeKey);
  return actions;
}
