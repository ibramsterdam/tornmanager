import "./main.css";
import { Logger } from "./core/Logger.js";
import { Auth } from "./core/Auth.js";
import { ApiClient } from "./core/ApiClient.js";
import { ChatClient } from "./core/ChatClient.js";
import { Overlay } from "./ui/Overlay.js";
import { Sidebar } from "./ui/Sidebar.js";
import { ChatDock } from "./ui/ChatDock.js";

const logger = new Logger();
const auth = new Auth();
const api = new ApiClient(auth);

// Swap for MockChatClient (localStorage + fake teammates) to work on chat UI offline.
const chatClient = new ChatClient(auth);
const chatDock = new ChatDock(auth, chatClient, logger);
chatDock.init();

window.addEventListener("error", (e) => {
  const msg = e.error?.message || e.message || "";
  if (msg.includes("ResizeObserver")) return;
  const source = e.filename ? `${e.filename}:${e.lineno}` : "unknown source";
  logger.log(e.error || msg, `uncaught (${source})`);
});

window.addEventListener("unhandledrejection", (e) => {
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
