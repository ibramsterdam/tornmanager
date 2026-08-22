import "./main.css";
import { Auth } from "@shared/core/Auth.js";
import { Store } from "./core/Store.js";
import { RecruiterApi } from "./core/RecruiterApi.js";
import { Overlay } from "./ui/Overlay.js";
import { Sidebar } from "./ui/Sidebar.js";
import { MenuEntry } from "./ui/MenuEntry.js";
import { ChatOpener } from "./ui/ChatOpener.js";
import { AuthScreen } from "./ui/AuthScreen.js";
import { SubscriptionScreen } from "./ui/SubscriptionScreen.js";
import { SearchScreen } from "./ui/SearchScreen.js";
import { SettingsScreen } from "./ui/SettingsScreen.js";

const LEGACY_STORE_KEYS = ["keys", "roster", "stats", "status", "sweep_progress"];

function boot() {
  LEGACY_STORE_KEYS.forEach((key) => Store.remove(key));

  const auth = new Auth(Store);
  const api = new RecruiterApi(auth);

  const overlay = new Overlay(auth);
  overlay.register("auth", new AuthScreen(auth, overlay, api));
  overlay.register("subscription", new SubscriptionScreen(auth, overlay, api));
  overlay.register("search", new SearchScreen(api, overlay));
  overlay.register("settings", new SettingsScreen(auth, overlay, api));

  new Sidebar(overlay).init();
  new MenuEntry(overlay).init();
  new ChatOpener().init();

  console.log(`%cRecruiter %cv${__RC_VERSION__} is running.`, "font-weight: 700; color: #0070f3;", "color: inherit;");
}

if (window.self === window.top) boot();
