import { Dom } from "../core/Dom.js";

export class SubscriptionScreen {
  constructor(auth, overlay) {
    this.auth = auth;
    this.overlay = overlay;
    this.countdownInterval = null;
  }

  subtitle() {
    return "subscription";
  }

  render(container) {
    this.stopCountdown();

    const wrap = Dom.el("div", "rc-sub");
    wrap.appendChild(Dom.el("h2", "rc-sub-title", "Subscription"));

    const note = Dom.el("p", "rc-sub-note");
    note.textContent =
      "Recruiter is a TornManager subscriber extra. The script stays locked until your subscription is active.";
    wrap.appendChild(note);

    this.statusEl = Dom.el("div", "rc-sub-status");
    this.countdownEl = Dom.el("p", "rc-sub-countdown");
    wrap.append(this.statusEl, this.countdownEl);

    this.refreshBtn = Dom.el("button", "rc-sub-refresh", "Check for new payments");
    this.refreshBtn.onclick = () => this.load(true);
    wrap.appendChild(this.refreshBtn);

    const info = Dom.el("div", "rc-sub-info");
    info.innerHTML =
      'Send <strong>Xanax</strong> to <a href="https://www.torn.com/profiles.php?XID=2728237" target="_blank" rel="noopener">Bram [2728237]</a> to extend your subscription. ' +
      "Each Xanax adds <strong>1 week</strong>. Payments are checked automatically once a day.";
    wrap.appendChild(info);

    const actions = Dom.el("div", "rc-actions-row");
    const removeKey = Dom.el("button", "rc-btn-danger", "Remove API key");
    removeKey.addEventListener("click", () => {
      this.stopCountdown();
      this.auth.clear();
      this.overlay.open();
    });
    actions.appendChild(removeKey);
    wrap.appendChild(actions);

    container.appendChild(wrap);
    this.renderState(this.auth.subscription());
    this.load(false);
  }

  load(refresh) {
    this.refreshBtn.disabled = true;
    this.refreshBtn.textContent = refresh ? "Checking..." : "Loading...";

    this.auth
      .fetchSubscription({ refresh })
      .then((sub) => {
        if (sub.active && this.auth.isSubscribed()) {
          this.stopCountdown();
          this.overlay.open();
          return;
        }
        this.renderState(sub);
      })
      .catch((err) => {
        this.statusEl.textContent = err.message;
        this.statusEl.className = `rc-sub-status ${err.rateLimited ? "rc-sub-status--warn" : "rc-sub-status--error"}`;
        this.countdownEl.textContent = "";
      })
      .finally(() => {
        this.refreshBtn.disabled = false;
        this.refreshBtn.textContent = "Check for new payments";
      });
  }

  renderState(sub) {
    this.stopCountdown();
    if (sub?.active && sub.expires_at) {
      this.statusEl.textContent = "Active";
      this.statusEl.className = "rc-sub-status rc-sub-status--active";
      this.startCountdown(new Date(sub.expires_at));
    } else {
      this.statusEl.textContent = "Inactive";
      this.statusEl.className = "rc-sub-status rc-sub-status--inactive";
      this.countdownEl.textContent = "No active subscription.";
    }
  }

  startCountdown(expiresAt) {
    const tick = () => {
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
