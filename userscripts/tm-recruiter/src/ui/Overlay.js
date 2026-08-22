import { Dom } from "@shared/core/Dom.js";
import { Store } from "../core/Store.js";

const COG_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>';

const SUBSCRIPTION_RECHECK_MS = 6 * 3_600_000;

export class Overlay {
  constructor(auth) {
    this.auth = auth;
    this.screens = {};
    this.current = null;
    this.backdrop = null;
    this.panel = null;
    this.body = null;
  }

  register(name, screen) {
    this.screens[name] = screen;
  }

  mount() {
    if (this.backdrop) return;

    this.backdrop = Dom.el("div", "rc-backdrop");
    this.backdrop.addEventListener("click", (e) => {
      if (e.target === this.backdrop) this.close();
    });

    this.panel = Dom.el("div", "rc-panel");

    const head = Dom.el("div", "rc-head");
    const logo = Dom.el("span", "rc-logo", "R");
    const title = Dom.el("div", "rc-head-text");
    title.append(Dom.el("div", "rc-head-title", "Recruiter"), (this.subtitle = Dom.el("div", "rc-head-sub", "")));

    this.nav = Dom.el("div", "rc-nav");
    for (const [name, label] of [["search", "Search"]]) {
      const link = Dom.el("button", "rc-nav-link", label);
      link.dataset.screen = name;
      link.addEventListener("click", () => this.show(name));
      this.nav.appendChild(link);
    }
    const gear = Dom.el("button", "rc-nav-link rc-nav-link--icon");
    gear.dataset.screen = "settings";
    gear.title = "Settings";
    gear.innerHTML = COG_ICON;
    gear.addEventListener("click", () => this.show("settings"));
    this.nav.appendChild(gear);

    const close = Dom.el("button", "rc-close", "×");
    close.addEventListener("click", () => this.close());

    head.append(logo, title, this.nav, close);
    this.body = Dom.el("div", "rc-body");
    this.footer = Dom.el("div", "rc-footer");
    this.panel.append(head, this.body, this.footer);
    this.backdrop.appendChild(this.panel);
    document.body.appendChild(this.backdrop);
  }

  renderFooter() {
    this.footer.replaceChildren();
    const links = Dom.el("div", "rc-footer-links");

    const user = this.auth.getUser();
    if (user) {
      const profile = Dom.el("a", "rc-footer-user", `${user.name} [${user.torn_id}]`);
      profile.href = `https://www.torn.com/profiles.php?XID=${user.torn_id}`;
      profile.target = "_blank";
      profile.rel = "noopener";
      links.append(profile, Dom.el("span", null, "·"));
    }

    const privacy = Dom.el("a", "rc-footer-link", "Privacy Policy");
    privacy.href = "https://tornmanager.com/legal#recruiter-privacy-policy";
    privacy.target = "_blank";
    privacy.rel = "noopener";
    const terms = Dom.el("a", "rc-footer-link", "Terms of Service");
    terms.href = "https://tornmanager.com/legal#recruiter-terms-of-service";
    terms.target = "_blank";
    terms.rel = "noopener";
    const debug = Dom.el("button", "rc-footer-link", "Copy debug info");
    debug.addEventListener("click", () => this.copyDebugInfo(debug));

    links.append(privacy, Dom.el("span", null, "·"), terms, Dom.el("span", null, "·"), debug);
    this.footer.appendChild(links);
    this.footer.appendChild(Dom.el("div", "rc-footer-version", `v${__RC_VERSION__}`));
  }

  copyDebugInfo(button) {
    const info = {
      version: __RC_VERSION__,
      generatedAt: new Date().toISOString(),
      user: this.auth.getUser() ? { name: this.auth.getUser().name, tornId: this.auth.getUser().torn_id } : null,
      subscribed: this.auth.isSubscribed(),
      settings: Store.get("settings"),
      userAgent: navigator.userAgent,
    };
    navigator.clipboard
      .writeText(JSON.stringify(info, null, 2))
      .then(() => (button.textContent = "Copied!"))
      .catch(() => (button.textContent = "Copy failed"))
      .finally(() => setTimeout(() => (button.textContent = "Copy debug info"), 2000));
  }

  gateScreen() {
    if (!this.auth.isAuthenticated()) return "auth";
    if (!this.auth.isSubscribed()) return "subscription";
    return null;
  }

  show(name) {
    this.mount();
    const gate = this.gateScreen();
    if (gate) name = gate;

    this.current = name;
    this.nav.style.display = gate ? "none" : "flex";
    this.nav.querySelectorAll(".rc-nav-link").forEach((link) => {
      link.classList.toggle("rc-nav-link--active", link.dataset.screen === name);
    });
    const screen = this.screens[name];
    this.subtitle.textContent = screen.subtitle?.() || "";
    this.body.replaceChildren();
    screen.render(this.body);
    this.renderFooter();
  }

  open(name = null) {
    this.mount();
    this.backdrop.classList.add("rc-backdrop--visible");
    this.show(name || this.defaultScreen());
    this.recheckSubscription();
  }

  recheckSubscription() {
    if (this.gateScreen()) return;
    const checkedAt = this.auth.subscription()?.checkedAt || 0;
    if (Date.now() - checkedAt < SUBSCRIPTION_RECHECK_MS) return;
    this.auth
      .fetchSubscription()
      .then(() => {
        if (this.gateScreen()) this.open();
      })
      .catch(() => null);
  }

  close() {
    this.backdrop?.classList.remove("rc-backdrop--visible");
  }

  toggle() {
    this.mount();
    if (this.backdrop.classList.contains("rc-backdrop--visible")) {
      this.close();
    } else {
      this.open();
    }
  }

  defaultScreen() {
    return "search";
  }

  refresh() {
    if (this.current && this.backdrop?.classList.contains("rc-backdrop--visible")) {
      this.show(this.current);
    }
  }
}
