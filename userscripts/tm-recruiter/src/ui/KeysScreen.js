import { Dom } from "@shared/core/Dom.js";

export class KeysScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
  }

  subtitle() {
    return "key pool";
  }

  render(container) {
    const consent = Dom.el(
      "div",
      "rc-scope",
      "The shared pool holds the sign-in keys of Recruiter subscribers, stored on the TornManager server and " +
        "used for background fetching from the official Torn API. Every call carries the comment tmrecruiter, " +
        "so any owner can audit usage in their own Torn key log. Revoking a key stops all use of it."
    );
    container.appendChild(consent);

    this.listEl = Dom.el("div", "rc-list");
    container.appendChild(this.listEl);
    this.loadKeys();
  }

  async loadKeys() {
    if (!this.listEl) return;
    this.listEl.replaceChildren(Dom.el("div", "rc-dim", "Loading…"));
    try {
      const data = await this.api.listKeys();
      this.renderList(data.keys || []);
    } catch (error) {
      this.listEl.replaceChildren(Dom.el("div", "rc-feedback rc-feedback--error", error.message));
    }
  }

  renderList(keys) {
    if (!keys.length) {
      this.listEl.replaceChildren(Dom.el("div", "rc-dim", "No keys in your pool. Signing in again adds your key back."));
      return;
    }

    const rows = keys.map((key) => {
      const item = Dom.el("div", "rc-list-row");
      const badge = Dom.el("span", "rc-badge rc-badge--fresh", key.mine ? "your key" : "contributed");
      const owner = Dom.el("span", "rc-dim", `${key.owner_name} [${key.owner_torn_id}] · ${key.access_type}`);
      const added = Dom.el("span", "rc-dim", `added ${new Date(key.added_at).toLocaleDateString()}`);
      const remove = Dom.el("button", "rc-act", "✕");
      remove.title = "Revoke this key from the pool";
      remove.addEventListener("click", async () => {
        remove.disabled = true;
        try {
          await this.api.revokeKey(key.owner_torn_id);
          this.loadKeys();
        } catch {
          remove.disabled = false;
        }
      });
      item.append(badge, owner, added, remove);
      return item;
    });
    this.listEl.replaceChildren(...rows);
  }
}
