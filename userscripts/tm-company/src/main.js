import "./main.css";
import { CompanyAuth } from "./core/CompanyAuth.js";
import { CompanyApi } from "./core/CompanyApi.js";
import { Store } from "./core/Store.js";
import { Overlay } from "./ui/Overlay.js";
import { Sidebar } from "./ui/Sidebar.js";
import { MenuEntry } from "./ui/MenuEntry.js";
import { AuthScreen } from "./ui/AuthScreen.js";
import { SubscriptionScreen } from "./ui/SubscriptionScreen.js";
import { SettingsScreen } from "./ui/SettingsScreen.js";
import { OverviewScreen } from "./ui/OverviewScreen.js";
import { ChartsScreen } from "./ui/ChartsScreen.js";
import { StaffScreen } from "./ui/StaffScreen.js";
import { StockScreen } from "./ui/StockScreen.js";
import { NewsScreen } from "./ui/NewsScreen.js";

function boot() {
  const auth = new CompanyAuth(Store);
  const api = new CompanyApi(auth);

  const overlay = new Overlay(auth);
  overlay.register("auth", new AuthScreen(auth, overlay));
  overlay.register("subscription", new SubscriptionScreen(auth, overlay, api));
  overlay.register("settings", new SettingsScreen(auth, overlay, api));
  overlay.register("overview", new OverviewScreen(api, overlay));
  overlay.register("charts", new ChartsScreen(api, overlay));
  overlay.register("staff", new StaffScreen(api, overlay));
  overlay.register("stock", new StockScreen(api, overlay));
  overlay.register("news", new NewsScreen(api, overlay));

  new Sidebar(overlay).init();
  new MenuEntry(overlay).init();

  console.log(`%cCompany %cv${__TC_VERSION__} is running.`, "font-weight: 700; color: #10b981;", "color: inherit;");
}

if (window.self === window.top) boot();
