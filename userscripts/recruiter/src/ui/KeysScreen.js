import { Dom } from "../core/Dom.js";

const CALLS_PER_KEY_PER_MINUTE = 75;

export class KeysScreen {
  constructor(keys, api, overlay, auth) {
    this.keys = keys;
    this.api = api;
    this.overlay = overlay;
    this.auth = auth;
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
      const isSignIn = entry.key === this.auth.getApiKey();
      const owner = Dom.el("span", "rc-dim", `${entry.ownerName} [${entry.ownerId}] · ${entry.accessType}${isSignIn ? " · sign-in key" : ""}`);
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

    container.appendChild(this.subscriptionCard());
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
