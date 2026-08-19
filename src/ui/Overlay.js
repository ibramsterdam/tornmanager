import { Dom } from "../core/Dom.js";

export class Overlay {
  constructor() {
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
    for (const [name, label] of [["overview", "Overview"], ["setup", "Setup"], ["keys", "Keys"]]) {
      const link = Dom.el("button", "rc-nav-link", label);
      link.dataset.screen = name;
      link.addEventListener("click", () => this.show(name));
      this.nav.appendChild(link);
    }

    const close = Dom.el("button", "rc-close", "×");
    close.addEventListener("click", () => this.close());

    head.append(logo, title, this.nav, close);
    this.body = Dom.el("div", "rc-body");
    this.panel.append(head, this.body);
    this.backdrop.appendChild(this.panel);
    document.body.appendChild(this.backdrop);
  }

  show(name) {
    this.mount();
    this.current = name;
    this.nav.querySelectorAll(".rc-nav-link").forEach((link) => {
      link.classList.toggle("rc-nav-link--active", link.dataset.screen === name);
    });
    const screen = this.screens[name];
    this.subtitle.textContent = screen.subtitle?.() || "";
    this.body.replaceChildren();
    screen.render(this.body);
  }

  open(name = null) {
    this.mount();
    this.backdrop.classList.add("rc-backdrop--visible");
    this.show(name || this.defaultScreen());
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
    return this.screens.keys?.hasKeys() ? "overview" : "keys";
  }

  refresh() {
    if (this.current && this.backdrop?.classList.contains("rc-backdrop--visible")) {
      this.show(this.current);
    }
  }
}
