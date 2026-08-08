import { AuthScreen } from "./AuthScreen.js";
import { SubscriptionSection } from "./SubscriptionSection.js";
import { WarSection } from "./WarSection.js";

export class Overlay {
  constructor(auth, api, logger) {
    this.auth = auth;
    this.api = api;
    this.logger = logger;
    this.overlay = null;
    this.panel = null;
    this.isOpen = false;
    this.subscriptionSection = null;
  }

  open() {
    if (this.isOpen) return;

    if (!this.overlay) {
      this.overlay = this.createOverlay();
      document.body.appendChild(this.overlay);
    }

    this.renderPanel();

    // Force reflow so the transition triggers
    this.overlay.offsetHeight;
    this.overlay.classList.add("tm-overlay--visible");
    this.isOpen = true;
  }

  close() {
    if (!this.overlay || !this.isOpen) return;

    if (this.subscriptionSection) {
      this.subscriptionSection.destroy();
      this.subscriptionSection = null;
    }

    this.overlay.classList.remove("tm-overlay--visible");
    this.isOpen = false;
  }

  toggle() {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  createOverlay() {
    const backdrop = document.createElement("div");
    backdrop.id = "tm-overlay-backdrop";
    backdrop.className = "tm-overlay-backdrop";

    this.panel = document.createElement("div");
    this.panel.className = "tm-overlay-panel";

    backdrop.appendChild(this.panel);

    backdrop.addEventListener("click", (e) => {
      if (e.target === backdrop) this.close();
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && this.isOpen) this.close();
    });

    return backdrop;
  }

  renderPanel() {
    this.panel.innerHTML = "";

    const closeBtn = document.createElement("button");
    closeBtn.className = "tm-overlay-close";
    closeBtn.textContent = "\u00d7";
    closeBtn.onclick = () => this.close();
    this.panel.appendChild(closeBtn);

    if (this.auth.isAuthenticated()) {
      this.renderAuthenticatedPanel();
    } else {
      this.renderUnauthenticatedPanel();
    }

    this.panel.appendChild(this.createFooter());
  }

  renderAuthenticatedPanel() {
    const user = this.auth.getUser();

    const title = document.createElement("h1");
    title.className = "tm-overlay-title";
    title.textContent = `Welcome, ${user.name}`;
    this.panel.appendChild(title);

    this.subscriptionSection = new SubscriptionSection(this.auth);
    this.panel.appendChild(this.subscriptionSection.render());

    const warSection = new WarSection(this.api);
    this.panel.appendChild(warSection.render());

    const removeBtn = document.createElement("button");
    removeBtn.className = "tm-remove-key";
    removeBtn.textContent = "Remove API key";
    removeBtn.onclick = () => {
      if (this.subscriptionSection) {
        this.subscriptionSection.destroy();
        this.subscriptionSection = null;
      }
      this.auth.clear();
      this.renderPanel();
    };
    this.panel.appendChild(removeBtn);
  }

  renderUnauthenticatedPanel() {
    const authScreen = new AuthScreen(this.auth);
    this.panel.appendChild(authScreen.render(() => this.renderPanel()));
  }

  createFooter() {
    const footer = document.createElement("footer");
    footer.className = "tm-footer";

    const links = document.createElement("div");
    links.className = "tm-footer-row";

    const profile = document.createElement("a");
    profile.href = "https://www.torn.com/profiles.php?XID=2728237";
    profile.target = "_blank";
    profile.rel = "noopener";
    profile.className = "tm-footer-link";
    profile.textContent = "Bram [2728237]";

    const privacy = document.createElement("a");
    privacy.href = "https://tornmanager.com/legal#privacy-policy";
    privacy.target = "_blank";
    privacy.rel = "noopener";
    privacy.className = "tm-footer-link";
    privacy.textContent = "Privacy Policy";

    const tos = document.createElement("a");
    tos.href = "https://tornmanager.com/legal#terms-of-service";
    tos.target = "_blank";
    tos.rel = "noopener";
    tos.className = "tm-footer-link";
    tos.textContent = "Terms of Service";

    const divider = document.createElement("span");
    divider.className = "tm-footer-divider";
    divider.textContent = "\u00b7";

    links.appendChild(profile);
    links.appendChild(divider.cloneNode(true));
    links.appendChild(privacy);
    links.appendChild(divider.cloneNode(true));
    links.appendChild(tos);

    footer.appendChild(links);

    const errors = this.logger.getAll();
    if (errors.length > 0) {
      const errorRow = document.createElement("div");
      errorRow.className = "tm-footer-row";

      const copyBtn = document.createElement("button");
      copyBtn.className = "tm-footer-copy-log";
      copyBtn.textContent = `Copy error log (${errors.length})`;
      copyBtn.onclick = async () => {
        try {
          await navigator.clipboard.writeText(this.logger.format());
          copyBtn.textContent = "Copied!";
          setTimeout(() => {
            copyBtn.textContent = `Copy error log (${this.logger.getAll().length})`;
          }, 2000);
        } catch {
          const ta = document.createElement("textarea");
          ta.value = this.logger.format();
          ta.style.position = "fixed";
          ta.style.opacity = "0";
          document.body.appendChild(ta);
          ta.select();
          document.execCommand("copy");
          document.body.removeChild(ta);
          copyBtn.textContent = "Copied!";
          setTimeout(() => {
            copyBtn.textContent = `Copy error log (${this.logger.getAll().length})`;
          }, 2000);
        }
      };

      const clearBtn = document.createElement("button");
      clearBtn.className = "tm-footer-clear-log";
      clearBtn.textContent = "Clear";
      clearBtn.onclick = () => {
        this.logger.clear();
        errorRow.remove();
      };

      errorRow.appendChild(copyBtn);
      errorRow.appendChild(clearBtn);
      footer.appendChild(errorRow);
    }

    return footer;
  }
}
