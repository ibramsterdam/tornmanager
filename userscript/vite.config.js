import { defineConfig } from "vite";
import monkey from "vite-plugin-monkey";
import { readFileSync } from "fs";

const pkg = JSON.parse(readFileSync("package.json", "utf-8"));
const isDev = process.env.NODE_ENV === "development";

const API_BASE = isDev ? "http://localhost:3000" : "https://tornmanager.com";

// Public install + auto-update link: the built script committed in this repo.
const RELEASE_URL = "https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tornmanager.user.js";

export default defineConfig({
  define: {
    __API_BASE__: JSON.stringify(API_BASE),
    __TM_VERSION__: JSON.stringify(pkg.version),
  },
  build: {
    minify: false,
  },
  plugins: [
    monkey({
      entry: "src/main.js",
      userscript: {
        name: isDev ? "Torn Manager (Dev)" : "Torn Manager",
        namespace: "tornmanager",
        version: pkg.version,
        author: "Bram [2728237]",
        icon: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%230070f3'/%3E%3Ctext x='32' y='43' text-anchor='middle' font-family='Arial,Helvetica,sans-serif' font-weight='900' font-size='30' fill='white'%3ETM%3C/text%3E%3C/svg%3E",
        description: pkg.description,
        match: ["https://www.torn.com/*"],
        license: "All rights reserved",
        ...(isDev ? {} : { downloadURL: RELEASE_URL, updateURL: RELEASE_URL }),
        grant: ["GM.xmlHttpRequest", "GM.notification"],
        connect: [
          "torn.com",
          "api.torn.com",
          "tornmanager.com",
          ...(isDev ? ["localhost"] : []),
        ],
        "run-at": "document-start",
      },
      build: {
        fileName: "tornmanager.user.js",
      },
    }),
  ],
});
