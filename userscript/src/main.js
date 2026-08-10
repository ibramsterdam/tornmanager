import "./main.css";
import { Logger } from "./core/Logger.js";
import { Auth } from "./core/Auth.js";
import { ApiClient } from "./core/ApiClient.js";
import { ChatClient } from "./core/ChatClient.js";
import { Overlay } from "./ui/Overlay.js";
import { Sidebar } from "./ui/Sidebar.js";
import { SettingsMenuEntry } from "./ui/SettingsMenuEntry.js";
import { ChatDock } from "./ui/ChatDock.js";
import { UpdateGate } from "./ui/UpdateGate.js";

import { Preferences } from "./core/Preferences.js";

const logger = new Logger();
const auth = new Auth();
const api = new ApiClient(auth);

Preferences.applyChatFontSize();

// Swap for MockChatClient (localStorage + fake teammates) to work on chat UI offline.
const chatClient = new ChatClient(auth);
const chatDock = new ChatDock(auth, chatClient, logger);
chatDock.init();

// Only skip errors that identifiably belong to a different userscript —
// anything ambiguous still gets logged so we don't miss our own failures
// on managers with other stack formats (PDA, iOS Userscripts, ...).
function fromAnotherUserscript(source) {
  if (!source) return false;
  const match = source.match(/userscript\.html\?name=([^&]+)/i);
  return !!match && !decodeURIComponent(match[1]).toLowerCase().includes("torn-manager");
}

window.addEventListener("error", (e) => {
  const msg = e.error?.message || e.message || "";
  if (msg.includes("ResizeObserver")) return;
  if (fromAnotherUserscript(e.filename) || fromAnotherUserscript(e.error?.stack)) return;
  const source = e.filename ? `${e.filename}:${e.lineno}` : "unknown source";
  logger.log(e.error || msg, `uncaught (${source})`);
});

window.addEventListener("unhandledrejection", (e) => {
  if (fromAnotherUserscript(e.reason?.stack)) return;
  logger.log(e.reason, "unhandled promise");
});

console.log(
  "%cTorn%cManager %cis running.",
  "font-size: 30px; font-weight: 600; color: #42a5f5;",
  "font-size: 30px; font-weight: 600; color: #fff;",
  "font-size: 30px;"
);

const overlay = new Overlay(auth, api, logger, chatDock);
const sidebar = new Sidebar(overlay);
sidebar.init();

const settingsMenuEntry = new SettingsMenuEntry(overlay);
settingsMenuEntry.init();

const updateGate = new UpdateGate();
updateGate.start();
