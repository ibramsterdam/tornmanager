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
    const addCard = Dom.el("div", "rc-card");
    const label = Dom.el("div", "rc-label", "Add a key to the shared pool (Public access only)");
    const row = Dom.el("div", "rc-row");
    const input = Dom.el("input", "rc-input");
    input.type = "text";
    input.placeholder = "paste key…";
    const button = Dom.el("button", "rc-btn", "Add & validate");
    const feedback = Dom.el("div", "rc-feedback");

    button.addEventListener("click", async () => {
      button.disabled = true;
      button.textContent = "Validating…";
      feedback.textContent = "";
      feedback.className = "rc-feedback";
      try {
        const data = await this.api.submitKey(input.value.trim());
        feedback.textContent = `Added ${data.key.owner_name} [${data.key.owner_torn_id}] · ${data.key.access_type}`;
        feedback.classList.add("rc-feedback--ok");
        input.value = "";
        this.loadKeys();
      } catch (error) {
        feedback.textContent = error.message;
        feedback.classList.add("rc-feedback--error");
      } finally {
        button.disabled = false;
        button.textContent = "Add & validate";
      }
    });

    row.append(input, button);
    addCard.append(label, row, feedback);
    container.appendChild(addCard);

    const consent = Dom.el(
      "div",
      "rc-scope",
      "Pool keys are stored on the TornManager server and used for background fetching from the official Torn API. " +
        "Every call carries the comment tmrecruiter, so any owner can audit usage in their own Torn key log. " +
        "Only add keys their owners handed you willingly. Revoking a key stops all use of it."
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
      this.listEl.replaceChildren(Dom.el("div", "rc-dim", "No keys in your pool yet. More keys from different players means faster server-side fetching for everyone."));
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
