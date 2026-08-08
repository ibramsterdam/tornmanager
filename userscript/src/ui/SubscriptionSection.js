export class SubscriptionSection {
  constructor(auth, onUpdate) {
    this.auth = auth;
    this.onUpdate = onUpdate;
    this.countdownInterval = null;
  }

  render() {
    const section = document.createElement("div");
    section.className = "tm-sub";

    const title = document.createElement("h2");
    title.className = "tm-sub-title";
    title.textContent = "Subscription";
    section.appendChild(title);

    this.statusEl = document.createElement("div");
    this.statusEl.className = "tm-sub-status";
    section.appendChild(this.statusEl);

    this.countdownEl = document.createElement("p");
    this.countdownEl.className = "tm-sub-countdown";
    section.appendChild(this.countdownEl);

    this.refreshBtn = document.createElement("button");
    this.refreshBtn.className = "tm-sub-refresh";
    this.refreshBtn.textContent = "Check for new payments";
    this.refreshBtn.onclick = () => this.load(true);
    section.appendChild(this.refreshBtn);

    const info = document.createElement("div");
    info.className = "tm-sub-info";
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
        if (err.rateLimited) {
          this.statusEl.textContent = err.message;
          this.statusEl.className = "tm-sub-status tm-sub-status--warn";
        } else {
          this.statusEl.textContent = err.message;
          this.statusEl.className = "tm-sub-status tm-sub-status--error";
        }
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
      this.statusEl.className = "tm-sub-status tm-sub-status--active";
      this.startCountdown(new Date(sub.expires_at));
    } else {
      this.statusEl.textContent = "Inactive";
      this.statusEl.className = "tm-sub-status tm-sub-status--inactive";
      this.countdownEl.textContent = "No active subscription.";
    }
  }

  startCountdown(expiresAt) {
    this.stopCountdown();

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
      parts.push(`${hours}h`);
      parts.push(`${minutes}m`);
      parts.push(`${seconds}s`);

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
