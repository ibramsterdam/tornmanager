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
import { KeysScreen } from "./ui/KeysScreen.js";
import { SetupScreen } from "./ui/SetupScreen.js";
import { OverviewScreen } from "./ui/OverviewScreen.js";

const LEGACY_STORE_KEYS = ["keys", "roster", "stats", "status", "sweep_progress"];

function boot() {
  LEGACY_STORE_KEYS.forEach((key) => Store.remove(key));

  const auth = new Auth(Store);
  const api = new RecruiterApi(auth);

  const overlay = new Overlay(auth);
  overlay.register("auth", new AuthScreen(auth, overlay));
  overlay.register("subscription", new SubscriptionScreen(auth, overlay));
  overlay.register("keys", new KeysScreen(api, overlay, auth));
  overlay.register("setup", new SetupScreen(overlay));
  overlay.register("overview", new OverviewScreen(api, overlay));

  new Sidebar(overlay).init();
  new MenuEntry(overlay).init();
  new ChatOpener().init();

  console.log(`%cRecruiter %cv${__RC_VERSION__} is running.`, "font-weight: 700; color: #0070f3;", "color: inherit;");
}

if (window.self === window.top) boot();
