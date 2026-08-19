import { Dom } from "../core/Dom.js";

const CALLS_PER_KEY_PER_MINUTE = 75;

export class KeysScreen {
  constructor(keys, api, overlay) {
    this.keys = keys;
    this.api = api;
    this.overlay = overlay;
  }

  hasKeys() {
    return this.keys.active().length > 0;
  }

  subtitle() {
    return "api keys";
  }

  render(container) {
    const addCard = Dom.el("div", "rc-card");
    const label = Dom.el("div", "rc-label", "Add a key (public access is enough)");
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
        const entry = await this.keys.add(input.value, this.api);
        feedback.textContent = `Added ${entry.ownerName} [${entry.ownerId}] · ${entry.accessType}`;
        feedback.classList.add("rc-feedback--ok");
        input.value = "";
        this.overlay.refresh();
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

    const list = Dom.el("div", "rc-list");
    for (const entry of this.keys.all()) {
      const item = Dom.el("div", "rc-list-row");
      const badge = Dom.el("span", `rc-badge ${entry.valid ? "rc-badge--fresh" : "rc-badge--stale"}`, entry.valid ? "valid" : "invalid");
      const masked = Dom.el("span", "rc-mono", `${entry.key.slice(0, 4)}…${entry.key.slice(-4)}`);
      const owner = Dom.el("span", "rc-dim", `${entry.ownerName} [${entry.ownerId}] · ${entry.accessType}`);
      const usage = Dom.el("span", "rc-dim", `${entry.callsToday.toLocaleString()} calls today`);
      const remove = Dom.el("button", "rc-act", "✕");
      remove.addEventListener("click", () => {
        this.keys.remove(entry.key);
        this.overlay.refresh();
      });
      item.append(badge, masked, owner, usage, remove);
      list.appendChild(item);
    }
    container.appendChild(list);

    const count = this.keys.active().length;
    const budget = count * CALLS_PER_KEY_PER_MINUTE;
    const summary = Dom.el(
      "div",
      "rc-scope",
      count
        ? `${count} key${count === 1 ? "" : "s"}, ${count} player${count === 1 ? "" : "s"} · budget ~${budget} calls/min (${CALLS_PER_KEY_PER_MINUTE} per key, headroom kept)`
        : "No keys yet. Every key must come from a different player, Torn's 100/min limit is per player."
    );
    container.appendChild(summary);
  }
}
