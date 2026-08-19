import "./main.css";
import { Auth } from "./core/Auth.js";
import { Keys } from "./core/Keys.js";
import { Api } from "./core/Api.js";
import { Roster } from "./core/Roster.js";
import { Sweep } from "./core/Sweep.js";
import { StatusRefresh } from "./core/StatusRefresh.js";
import { Overlay } from "./ui/Overlay.js";
import { Sidebar } from "./ui/Sidebar.js";
import { MenuEntry } from "./ui/MenuEntry.js";
import { AuthScreen } from "./ui/AuthScreen.js";
import { SubscriptionScreen } from "./ui/SubscriptionScreen.js";
import { LegalScreen } from "./ui/LegalScreen.js";
import { KeysScreen } from "./ui/KeysScreen.js";
import { SetupScreen } from "./ui/SetupScreen.js";
import { OverviewScreen } from "./ui/OverviewScreen.js";

function boot() {
  const auth = new Auth();
  const keys = new Keys();
  const api = new Api(keys);
  const roster = new Roster(api);
  const sweep = new Sweep(api);
  const status = new StatusRefresh(api);

  const overlay = new Overlay(auth);
  overlay.register("auth", new AuthScreen(auth, overlay, keys, api));
  overlay.register("subscription", new SubscriptionScreen(auth, overlay));
  overlay.register("legal", new LegalScreen(overlay));
  overlay.register("keys", new KeysScreen(keys, api, overlay, auth));
  overlay.register("setup", new SetupScreen(overlay));
  overlay.register("overview", new OverviewScreen({ roster, sweep, status, api, overlay }));

  new Sidebar(overlay).init();
  new MenuEntry(overlay).init();

  console.log(`%cRecruiter %cv${__RC_VERSION__} is running.`, "font-weight: 700; color: #0070f3;", "color: inherit;");
}

if (window.self === window.top) boot();
