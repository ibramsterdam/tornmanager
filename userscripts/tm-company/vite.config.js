import { defineConfig } from "vite";
import monkey from "vite-plugin-monkey";
import { readFileSync } from "fs";
import { fileURLToPath, URL } from "node:url";

const pkg = JSON.parse(readFileSync("package.json", "utf-8"));
const isDev = process.env.NODE_ENV === "development";

const API_BASE = isDev ? "http://localhost:3000" : "https://tornmanager.com";

const RELEASE_URL = "https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-company.user.js";

export default defineConfig({
  resolve: {
    alias: { "@shared": fileURLToPath(new URL("../shared", import.meta.url)) },
  },
  define: {
    __TC_VERSION__: JSON.stringify(pkg.version),
    __API_BASE__: JSON.stringify(API_BASE),
  },
  build: {
    minify: false,
  },
  plugins: [
    monkey({
      entry: "src/main.js",
      userscript: {
        name: isDev ? "Torn Manager Company (Dev)" : "Torn Manager Company",
        namespace: "torn-company",
        version: pkg.version,
        author: "Bram [2728237]",
        icon: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%2310b981'/%3E%3Ctext x='32' y='43' text-anchor='middle' font-family='Arial,Helvetica,sans-serif' font-weight='900' font-size='34' fill='white'%3EC%3C/text%3E%3C/svg%3E",
        description: pkg.description,
        match: ["https://www.torn.com/*"],
        noframes: true,
        license: "All rights reserved",
        ...(RELEASE_URL && !isDev ? { downloadURL: RELEASE_URL, updateURL: RELEASE_URL } : {}),
        grant: ["GM.xmlHttpRequest"],
        connect: ["tornmanager.com", ...(isDev ? ["localhost"] : [])],
        "run-at": "document-start",
      },
      build: {
        fileName: "tm-company.user.js",
      },
    }),
  ],
});
