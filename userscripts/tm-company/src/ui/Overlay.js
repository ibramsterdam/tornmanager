import { Dom } from "@shared/core/Dom.js";

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

    this.backdrop = Dom.el("div", "tc-backdrop");
    this.backdrop.addEventListener("click", (e) => {
      if (e.target === this.backdrop) this.close();
    });

    this.panel = Dom.el("div", "tc-panel");

    const head = Dom.el("div", "tc-head");
    const logo = Dom.el("span", "tc-logo", "C");
    const title = Dom.el("div", "tc-head-text");
    title.append(Dom.el("div", "tc-head-title", "Company"), (this.subtitle = Dom.el("div", "tc-head-sub", "")));

    this.nav = Dom.el("div", "tc-nav");
    for (const [name, label] of [["overview", "Overview"], ["charts", "Charts"], ["staff", "Staff"], ["stock", "Stock"], ["news", "News"]]) {
      const link = Dom.el("button", "tc-nav-link", label);
      link.dataset.screen = name;
      link.addEventListener("click", () => this.show(name));
      this.nav.appendChild(link);
    }
    const gear = Dom.el("button", "tc-nav-link tc-nav-link--icon");
    gear.dataset.screen = "settings";
    gear.title = "Settings";
    gear.innerHTML = COG_ICON;
    gear.addEventListener("click", () => this.show("settings"));
    this.nav.appendChild(gear);

    const close = Dom.el("button", "tc-close", "×");
    close.addEventListener("click", () => this.close());

    head.append(logo, title, this.nav, close);
    this.body = Dom.el("div", "tc-body");
    this.footer = Dom.el("div", "tc-footer");
    this.panel.append(head, this.body, this.footer);
    this.backdrop.appendChild(this.panel);
    document.body.appendChild(this.backdrop);
  }

  renderFooter() {
    this.footer.replaceChildren();
    const links = Dom.el("div", "tc-footer-links");

    const user = this.auth.getUser();
    if (user) {
      const profile = Dom.el("a", "tc-footer-user", `${user.name} [${user.torn_id}]`);
      profile.href = `https://www.torn.com/profiles.php?XID=${user.torn_id}`;
      profile.target = "_blank";
      profile.rel = "noopener";
      links.append(profile, Dom.el("span", null, "·"));
    }

    const privacy = Dom.el("a", "tc-footer-link", "Privacy Policy");
    privacy.href = "https://tornmanager.com/legal#company-privacy-policy";
    privacy.target = "_blank";
    privacy.rel = "noopener";
    const terms = Dom.el("a", "tc-footer-link", "Terms of Service");
    terms.href = "https://tornmanager.com/legal#company-terms-of-service";
    terms.target = "_blank";
    terms.rel = "noopener";
    const debug = Dom.el("button", "tc-footer-link", "Copy debug info");
    debug.addEventListener("click", () => this.copyDebugInfo(debug));

    links.append(privacy, Dom.el("span", null, "·"), terms, Dom.el("span", null, "·"), debug);
    this.footer.appendChild(links);
    this.footer.appendChild(Dom.el("div", "tc-footer-version", `v${__TC_VERSION__}`));
  }

  copyDebugInfo(button) {
    const info = {
      version: __TC_VERSION__,
      generatedAt: new Date().toISOString(),
      user: this.auth.getUser() ? { name: this.auth.getUser().name, tornId: this.auth.getUser().torn_id } : null,
      subscribed: this.auth.isSubscribed(),
      company: this.auth.company(),
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
    this.nav.querySelectorAll(".tc-nav-link").forEach((link) => {
      link.classList.toggle("tc-nav-link--active", link.dataset.screen === name);
    });
    const screen = this.screens[name];
    this.subtitle.textContent = screen.subtitle?.() || "";
    this.body.replaceChildren();
    screen.render(this.body);
    this.renderFooter();
  }

  open(name = null) {
    this.mount();
    this.backdrop.classList.add("tc-backdrop--visible");
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
    this.backdrop?.classList.remove("tc-backdrop--visible");
  }

  toggle() {
    this.mount();
    if (this.backdrop.classList.contains("tc-backdrop--visible")) {
      this.close();
    } else {
      this.open();
    }
  }

  defaultScreen() {
    return "overview";
  }

  handleError(error, container) {
    if (error.reauth) {
      this.auth.clear();
      this.show("auth");
      return;
    }
    if (error.subscriptionRequired) {
      this.auth.store.set("subscription", { active: false, checkedAt: Date.now() });
      this.show(this.current);
      return;
    }
    container.replaceChildren(Dom.el("div", "tc-empty", error.message));
  }

  refresh() {
    if (this.current && this.backdrop?.classList.contains("tc-backdrop--visible")) {
      this.show(this.current);
    }
  }
}
