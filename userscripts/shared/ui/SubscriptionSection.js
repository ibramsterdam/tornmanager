import { Dom } from "../core/Dom.js";

export class SubscriptionSection {
  constructor(auth, { classPrefix, note, onUpdate } = {}) {
    this.auth = auth;
    this.prefix = classPrefix;
    this.note = note;
    this.onUpdate = onUpdate;
    this.countdownInterval = null;
  }

  render() {
    const p = this.prefix;
    const section = Dom.el("div", `${p}-sub`);
    section.appendChild(Dom.el("h2", `${p}-sub-title`, "Subscription"));
    section.appendChild(Dom.el("p", `${p}-sub-note`, this.note));

    this.statusEl = Dom.el("div", `${p}-sub-status`);
    this.countdownEl = Dom.el("p", `${p}-sub-countdown`);
    section.append(this.statusEl, this.countdownEl);

    this.refreshBtn = Dom.el("button", `${p}-sub-refresh`, "Check for new payments");
    this.refreshBtn.onclick = () => this.load(true);
    section.appendChild(this.refreshBtn);

    const info = Dom.el("div", `${p}-sub-info`);
    info.innerHTML =
      'Send <strong>Xanax</strong> to <a href="https://www.torn.com/profiles.php?XID=2728237" target="_blank" rel="noopener">Bram [2728237]</a> to extend your subscription. Each Xanax adds <strong>1 week</strong>. Payments are checked automatically once a day.';
    section.appendChild(info);

    this.load(false);

    return section;
  }

  destroy() {
    this.stopCountdown();
  }

  load(refresh) {
    this.stopCountdown();

    this.statusEl.textContent = "";
    this.countdownEl.textContent = "";
    this.refreshBtn.disabled = true;
    this.refreshBtn.textContent = refresh ? "Checking..." : "Loading...";

    this.auth
      .fetchSubscription({ refresh })
      .then((sub) => {
        this.renderSubscription(sub);
        if (this.onUpdate) this.onUpdate(sub);
      })
      .catch((err) => {
        this.statusEl.textContent = err.message;
        this.statusEl.className = `${this.prefix}-sub-status ${this.prefix}-sub-status--${err.rateLimited ? "warn" : "error"}`;
        this.countdownEl.textContent = "";
      })
      .finally(() => {
        this.refreshBtn.disabled = false;
        this.refreshBtn.textContent = "Check for new payments";
      });
  }

  renderSubscription(sub) {
    if (sub.active && sub.expires_at) {
      this.statusEl.textContent = "Active";
      this.statusEl.className = `${this.prefix}-sub-status ${this.prefix}-sub-status--active`;
      this.startCountdown(new Date(sub.expires_at));
    } else {
      this.statusEl.textContent = "Inactive";
      this.statusEl.className = `${this.prefix}-sub-status ${this.prefix}-sub-status--inactive`;
      this.countdownEl.textContent = "No active subscription.";
    }
  }

  startCountdown(expiresAt) {
    this.stopCountdown();

    const tick = () => {
      if (!this.countdownEl.isConnected) {
        this.stopCountdown();
        return;
      }

      const diff = expiresAt - Date.now();
      if (diff <= 0) {
        this.countdownEl.textContent = "Expired";
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

      this.countdownEl.textContent = parts.join(" ") + " remaining";
    };

    tick();
    this.countdownInterval = setInterval(tick, 1000);
  }

  stopCountdown() {
    if (this.countdownInterval) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }
  }
}
