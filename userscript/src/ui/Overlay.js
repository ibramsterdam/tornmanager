import { AuthScreen } from "./AuthScreen.js";
import { SubscriptionSection } from "./SubscriptionSection.js";
import { WarSection } from "./WarSection.js";
import { ChatsSection } from "./ChatsSection.js";
import { MuggingSection } from "./MuggingSection.js";
import { StorageViewer } from "./StorageViewer.js";
import { copyText } from "../core/Clipboard.js";
import { UpdateCheck, DOWNLOAD_URL } from "../core/UpdateCheck.js";

const DEV_TORN_ID = 2728237;

const LOCK_ICON =
  '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';

const COG_ICON =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>';

export class Overlay {
  constructor(auth, api, logger, chatDock, mugHelper) {
    this.auth = auth;
    this.api = api;
    this.logger = logger;
    this.chatDock = chatDock;
    this.mugHelper = mugHelper;
    this.overlay = null;
    this.panel = null;
    this.isOpen = false;
    this.subscriptionSection = null;
    this.warSection = null;
    this.muggingSection = null;
    this.chatsSection = null;
    this.subscription = null;
    this.activeTab = "chats";
    this.updateChecked = false;
    this.latestVersion = null;
  }

  open() {
    if (this.isOpen) return;

    if (!this.overlay) {
      this.overlay = this.createOverlay();
      document.body.appendChild(this.overlay);
    }

    this.renderPanel();
    this.renderUpdateNotice();

    // Force reflow so the transition triggers
    this.overlay.offsetHeight;
    this.overlay.classList.add("tm-overlay--visible");
    this.isOpen = true;

    this.checkForUpdate();
  }

  checkForUpdate() {
    if (this.updateChecked) return;
    this.updateChecked = true;

    UpdateCheck.status()
      .then(({ latest, outdated }) => {
        if (!outdated) return;
        this.latestVersion = latest;
        this.renderUpdateNotice();
      })
      .catch(() => {});
  }

  renderUpdateNotice() {
    if (!this.latestVersion || !this.panel) return;
    if (this.panel.querySelector(".tm-update-notice")) return;

    const notice = document.createElement("div");
    notice.className = "tm-update-notice";

    const text = document.createElement("span");
    text.textContent = `Update available. You're on v${UpdateCheck.current}, latest is v${this.latestVersion}.`;

    const link = document.createElement("a");
    link.href = DOWNLOAD_URL;
    link.target = "_blank";
    link.rel = "noopener";
    link.className = "tm-update-link";
    link.textContent = "Update now";

    notice.appendChild(text);
    notice.appendChild(link);
    this.panel.insertBefore(notice, this.panel.firstChild);
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
    if (this.muggingSection) {
      this.muggingSection.destroy();
      this.muggingSection = null;
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
    this.panel.classList.remove("tm-overlay-panel--war", "tm-overlay-panel--chats");
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

    // Chats is the landing tab, so fetch subscription state in the background
    // to unlock the Ranked War tab for subscribers without a visit to the
    // Subscription tab first.
    if (this.subscription === null) {
      this.auth
        .fetchSubscription()
        .then((sub) => this.setSubscription(sub))
        .catch(() => {});
    }

    this.renderActiveTab();
  }

  devTabsEnabled() {
    return this.auth.getUser()?.torn_id === DEV_TORN_ID;
  }

  createTabBar() {
    const tabs = document.createElement("div");
    tabs.className = "tm-tabs";

    this.chatsTab = this.createTab("Chats", "chats");
    this.warTab = null;
    this.warTabLock = null;
    this.muggingTab = null;

    tabs.appendChild(this.chatsTab);

    if (this.devTabsEnabled()) {
      this.warTab = this.createTab("Ranked War", "war");
      this.warTabLock = document.createElement("span");
      this.warTabLock.className = "tm-tab-lock";
      this.warTabLock.innerHTML = LOCK_ICON;
      this.warTab.appendChild(this.warTabLock);
      tabs.appendChild(this.warTab);

      this.muggingTab = this.createTab("Mugging", "mugging");
      tabs.appendChild(this.muggingTab);
    }

    this.settingsTab = this.createTab("", "settings");
    this.settingsTab.classList.add("tm-tab--icon");
    this.settingsTab.title = "Settings";
    this.settingsTab.innerHTML = COG_ICON;
    tabs.appendChild(this.settingsTab);

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

    if ((this.activeTab === "war" || this.activeTab === "mugging") && !this.devTabsEnabled()) {
      this.activeTab = "chats";
    }
    if (this.activeTab === "war" && !this.subscription?.active) {
      this.activeTab = "settings";
    }

    this.destroySections();
    this.updateTabState();
    this.panel.classList.toggle("tm-overlay-panel--war", this.activeTab === "war");
    this.panel.classList.toggle("tm-overlay-panel--chats", this.activeTab === "chats");
    this.tabContent.innerHTML = "";

    if (this.activeTab === "war") {
      this.renderWarTab();
    } else if (this.activeTab === "mugging") {
      this.renderMuggingTab();
    } else if (this.activeTab === "chats") {
      this.renderChatsTab();
    } else {
      this.renderSettingsTab();
    }
  }

  updateTabState() {
    this.settingsTab.classList.toggle("tm-tab--active", this.activeTab === "settings");
    this.chatsTab.classList.toggle("tm-tab--active", this.activeTab === "chats");

    if (this.warTab) {
      const locked = !this.subscription?.active;
      this.warTab.classList.toggle("tm-tab--active", this.activeTab === "war");
      this.warTab.classList.toggle("tm-tab--locked", locked);
      this.warTabLock.style.display = locked ? "" : "none";

      if (locked) {
        this.warTab.title = "Requires an active subscription";
      } else {
        this.warTab.removeAttribute("title");
      }
    }

    if (this.muggingTab) {
      this.muggingTab.classList.toggle("tm-tab--active", this.activeTab === "mugging");
    }
  }

  setSubscription(subscription) {
    this.subscription = subscription;
    if (this.warTab) this.updateTabState();
  }

  renderSettingsTab() {
    this.subscriptionSection = new SubscriptionSection(this.auth, (sub) => this.setSubscription(sub));
    this.tabContent.appendChild(this.subscriptionSection.render());

    const actions = document.createElement("div");
    actions.className = "tm-settings-actions";
    this.tabContent.appendChild(actions);

    const removeBtn = document.createElement("button");
    removeBtn.className = "tm-remove-key";
    removeBtn.textContent = "Remove API key";
    removeBtn.onclick = () => {
      this.auth.clear();
      this.subscription = null;
      this.activeTab = "chats";
      this.renderPanel();
    };
    actions.appendChild(removeBtn);

    const storageBtn = document.createElement("button");
    storageBtn.className = "tm-remove-key tm-storage-toggle";
    storageBtn.textContent = "View stored data";
    actions.appendChild(storageBtn);

    let viewer = null;
    storageBtn.onclick = () => {
      if (viewer) {
        viewer.remove();
        viewer = null;
        storageBtn.textContent = "View stored data";
        return;
      }
      viewer = new StorageViewer().render();
      this.tabContent.appendChild(viewer);
      storageBtn.textContent = "Hide stored data";
    };
  }

  renderWarTab() {
    this.warSection = new WarSection(this.api);
    this.tabContent.appendChild(this.warSection.render());
  }

  renderMuggingTab() {
    this.muggingSection = new MuggingSection(this.api, this.mugHelper);
    this.tabContent.appendChild(this.muggingSection.render());
  }

  renderChatsTab() {
    this.chatsSection = new ChatsSection(this.chatDock);
    this.tabContent.appendChild(this.chatsSection.render());
  }

  openChatMembers(room) {
    this.activeTab = "chats";
    if (this.isOpen) {
      this.renderActiveTab();
    } else {
      this.open();
    }
    this.chatsSection?.openMembers(room);
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
    privacy.href = "https://tornmanager.com/legal#userscript-privacy-policy";
    privacy.target = "_blank";
    privacy.rel = "noopener";
    privacy.className = "tm-footer-link";
    privacy.textContent = "Privacy Policy";

    const tos = document.createElement("a");
    tos.href = "https://tornmanager.com/legal#userscript-terms-of-service";
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

    const version = document.createElement("div");
    version.className = "tm-footer-version";
    version.textContent = `v${__TM_VERSION__}`;
    footer.appendChild(version);

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
      `Torn #chatRoot present: ${!!document.getElementById("chatRoot")}`,
      `GM.xmlHttpRequest available: ${typeof GM !== "undefined" && typeof GM.xmlHttpRequest === "function"}`,
      `PDA bridge available: ${typeof window.PDA_httpPost === "function"}`,
      `Signed in: ${this.auth.isAuthenticated()}`,
      `Errors logged: ${this.logger.getAll().length}`,
    ].join("\n");
  }
}
