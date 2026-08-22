import { Dom } from "@shared/core/Dom.js";
import { SubscriptionSection } from "@shared/ui/SubscriptionSection.js";

export const SUBSCRIPTION_NOTE =
  "Recruiter requires an active TornManager subscription. The script stays locked until your subscription is active.";

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
      classPrefix: "rc",
      note: SUBSCRIPTION_NOTE,
      onUpdate: (sub) => {
        if (sub.active && this.auth.isSubscribed()) this.overlay.open();
      },
    });
    container.appendChild(this.section.render());

    const actions = Dom.el("div", "rc-actions-row");
    const removeKey = Dom.el("button", "rc-btn-danger", "Remove API key");
    removeKey.addEventListener("click", async () => {
      this.section?.destroy();
      const tornId = this.auth.getUser()?.torn_id;
      if (tornId) await this.api.revokeKey(tornId).catch(() => null);
      this.auth.clear();
      this.overlay.open();
    });
    actions.appendChild(removeKey);
    container.appendChild(actions);
  }
}
