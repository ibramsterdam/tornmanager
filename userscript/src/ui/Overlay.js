import { AuthScreen } from "./AuthScreen.js";
import { SubscriptionSection } from "./SubscriptionSection.js";
import { WarSection } from "./WarSection.js";
import { ChatsSection } from "./ChatsSection.js";
import { copyText } from "../core/Clipboard.js";

const LOCK_ICON =
  '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';

export class Overlay {
  constructor(auth, api, logger, chatDock) {
    this.auth = auth;
    this.api = api;
    this.logger = logger;
    this.chatDock = chatDock;
    this.overlay = null;
    this.panel = null;
    this.isOpen = false;
    this.subscriptionSection = null;
    this.warSection = null;
    this.chatsSection = null;
    this.subscription = null;
    this.activeTab = "subscription";
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

    this.destroySections();
    this.overlay.classList.remove("tm-overlay--visible");
    this.isOpen = false;
  }

  destroySections() {
    if (this.subscriptionSection) {
      this.subscriptionSection.destroy();
      this.subscriptionSection = null;
    }
    if (this.warSection) {
      this.warSection.destroy();
      this.warSection = null;
    }
    if (this.chatsSection) {
      this.chatsSection.destroy();
      this.chatsSection = null;
    }
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
    this.destroySections();
    this.panel.classList.remove("tm-overlay-panel--war");
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
    title.className = "tm-overlay-title tm-overlay-title--left";
    title.textContent = `Welcome, ${user.name}`;
    this.panel.appendChild(title);

    this.panel.appendChild(this.createTabBar());

    this.tabContent = document.createElement("div");
    this.tabContent.className = "tm-tab-content";
    this.panel.appendChild(this.tabContent);

    this.renderActiveTab();
  }

  createTabBar() {
    const tabs = document.createElement("div");
    tabs.className = "tm-tabs";

    this.subscriptionTab = this.createTab("Subscription", "subscription");
    this.warTab = this.createTab("Ranked War", "war");

    this.warTabLock = document.createElement("span");
    this.warTabLock.className = "tm-tab-lock";
    this.warTabLock.innerHTML = LOCK_ICON;
    this.warTab.appendChild(this.warTabLock);

    this.chatsTab = this.createTab("Chats", "chats");

    tabs.appendChild(this.subscriptionTab);
    tabs.appendChild(this.warTab);
    tabs.appendChild(this.chatsTab);

    return tabs;
  }

  createTab(label, name) {
    const tab = document.createElement("button");
    tab.className = "tm-tab";
    tab.textContent = label;
    tab.onclick = () => this.selectTab(name);
    return tab;
  }

  selectTab(name) {
    if (this.activeTab === name) return;
    this.activeTab = name;
    this.renderActiveTab();
  }

  renderActiveTab() {
    if (!this.tabContent) return;

    if (this.activeTab === "war" && !this.subscription?.active) {
      this.activeTab = "subscription";
    }

    this.destroySections();
    this.updateTabState();
    this.panel.classList.toggle("tm-overlay-panel--war", this.activeTab === "war");
    this.tabContent.innerHTML = "";

    if (this.activeTab === "war") {
      this.renderWarTab();
    } else if (this.activeTab === "chats") {
      this.renderChatsTab();
    } else {
      this.renderSubscriptionTab();
    }
  }

  updateTabState() {
    const locked = !this.subscription?.active;
    this.subscriptionTab.classList.toggle("tm-tab--active", this.activeTab === "subscription");
    this.warTab.classList.toggle("tm-tab--active", this.activeTab === "war");
    this.chatsTab.classList.toggle("tm-tab--active", this.activeTab === "chats");
    this.warTab.disabled = locked;
    this.warTabLock.style.display = locked ? "" : "none";

    if (locked) {
      this.warTab.title = "Requires an active subscription";
    } else {
      this.warTab.removeAttribute("title");
    }
  }

  setSubscription(subscription) {
    this.subscription = subscription;
    if (this.warTab) this.updateTabState();
  }

  renderSubscriptionTab() {
    this.subscriptionSection = new SubscriptionSection(this.auth, (sub) => this.setSubscription(sub));
    this.tabContent.appendChild(this.subscriptionSection.render());

    const removeBtn = document.createElement("button");
    removeBtn.className = "tm-remove-key";
    removeBtn.textContent = "Remove API key";
    removeBtn.onclick = () => {
      this.auth.clear();
      this.subscription = null;
      this.activeTab = "subscription";
      this.renderPanel();
    };
    this.tabContent.appendChild(removeBtn);
  }

  renderWarTab() {
    this.warSection = new WarSection(this.api);
    this.tabContent.appendChild(this.warSection.render());
  }

  renderChatsTab() {
    this.chatsSection = new ChatsSection(this.chatDock);
    this.tabContent.appendChild(this.chatsSection.render());
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
    links.appendChild(divider.cloneNode(true));

    const debug = document.createElement("button");
    debug.type = "button";
    debug.className = "tm-footer-link tm-footer-link--button";
    debug.textContent = "Copy debug info";
    debug.onclick = () => copyText(this.debugInfo(), "Debug info copied");
    links.appendChild(debug);

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

  // Environment snapshot for support reports — everything the icon/chat
  // mounting and API transport depend on, small enough to paste anywhere.
  debugInfo() {
    return [
      `TornManager v${__TM_VERSION__}`,
      `URL: ${window.location.href}`,
      `Viewport: ${window.innerWidth}x${window.innerHeight}`,
      `UA: ${navigator.userAgent}`,
      `Body classes: ${document.body?.className || "-"}`,
      `#sidebar present: ${!!document.getElementById("sidebar")}`,
      `Status-icons list present: ${!!document.querySelector("#sidebar ul[class^='status-icon']")}`,
      `TM sidebar icon mounted: ${!!document.getElementById("tornmanager-icon")}`,
      `TM fallback launcher mounted: ${!!document.getElementById("tornmanager-launcher")}`,
      `Torn #chatRoot present: ${!!document.getElementById("chatRoot")}`,
      `GM.xmlHttpRequest available: ${typeof GM !== "undefined" && typeof GM.xmlHttpRequest === "function"}`,
      `PDA bridge available: ${typeof window.PDA_httpPost === "function"}`,
      `Signed in: ${this.auth.isAuthenticated()}`,
      `Errors logged: ${this.logger.getAll().length}`,
    ].join("\n");
  }
}
