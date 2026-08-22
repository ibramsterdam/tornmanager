import { Dom } from "@shared/core/Dom.js";

export class KeysScreen {
  constructor(api, overlay, auth) {
    this.api = api;
    this.overlay = overlay;
    this.auth = auth;
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

    container.appendChild(this.subscriptionCard());
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

  subscriptionCard() {
    this.stopCountdown();

    const card = Dom.el("div", "rc-card rc-subcard");
    card.appendChild(Dom.el("div", "rc-label", "TornManager subscription"));

    const row = Dom.el("div", "rc-subcard-row");
    const badge = Dom.el("span", "rc-badge");
    const countdown = Dom.el("span", "rc-subcard-count");
    const check = Dom.el("button", "rc-btn rc-btn--ghost", "Check for new payments");
    row.append(badge, countdown, check);
    card.appendChild(row);

    const info = Dom.el("div", "rc-hint");
    info.innerHTML =
      'Send <strong>Xanax</strong> to <a href="https://www.torn.com/profiles.php?XID=2728237" target="_blank" rel="noopener">Bram [2728237]</a> to extend it. Each Xanax adds <strong>1 week</strong>.';
    card.appendChild(info);

    const apply = (sub) => {
      this.stopCountdown();
      if (sub?.active && sub.expires_at) {
        badge.className = "rc-badge rc-badge--fresh";
        badge.textContent = "active";
        const expiresAt = new Date(sub.expires_at);
        const tick = () => {
          const diff = expiresAt - Date.now();
          if (diff <= 0) {
            countdown.textContent = "Expired";
            this.stopCountdown();
            return;
          }
          const days = Math.floor(diff / 86400000);
          const hours = Math.floor((diff % 86400000) / 3600000);
          const minutes = Math.floor((diff % 3600000) / 60000);
          const seconds = Math.floor((diff % 60000) / 1000);
          const parts = [];
          if (days > 0) parts.push(`${days}d`);
          parts.push(`${hours}h`, `${minutes}m`, `${seconds}s`);
          countdown.textContent = parts.join(" ") + " remaining";
        };
        tick();
        this.countdownInterval = setInterval(tick, 1000);
      } else {
        badge.className = "rc-badge rc-badge--stale";
        badge.textContent = "inactive";
        countdown.textContent = "No active subscription.";
      }
    };

    check.addEventListener("click", () => {
      check.disabled = true;
      check.textContent = "Checking...";
      this.auth
        .fetchSubscription({ refresh: true })
        .then((sub) => apply(sub))
        .catch((err) => {
          countdown.textContent = err.message;
        })
        .finally(() => {
          check.disabled = false;
          check.textContent = "Check for new payments";
        });
    });

    apply(this.auth.subscription());
    return card;
  }

  stopCountdown() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }
  }
}
