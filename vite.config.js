import { defineConfig } from "vite";
import monkey from "vite-plugin-monkey";
import { readFileSync } from "fs";

const pkg = JSON.parse(readFileSync("package.json", "utf-8"));
const isDev = process.env.NODE_ENV === "development";

// Distribution stays private: point this at a secret gist raw URL once one
// exists, then uncomment downloadURL/updateURL below.
const RELEASE_URL = null;

export default defineConfig({
  define: {
    __RC_VERSION__: JSON.stringify(pkg.version),
  },
  build: {
    minify: false,
  },
  plugins: [
    monkey({
      entry: "src/main.js",
      userscript: {
        name: isDev ? "Recruiter (Dev)" : "Recruiter",
        namespace: "torn-recruiter",
        version: pkg.version,
        author: "Bram [2728237]",
        icon: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='12' fill='%230070f3'/%3E%3Ctext x='32' y='43' text-anchor='middle' font-family='Arial,Helvetica,sans-serif' font-weight='900' font-size='34' fill='white'%3ER%3C/text%3E%3C/svg%3E",
        description: pkg.description,
        match: ["https://www.torn.com/*"],
        noframes: true,
        license: "All rights reserved",
        ...(RELEASE_URL && !isDev ? { downloadURL: RELEASE_URL, updateURL: RELEASE_URL } : {}),
        grant: [],
        "run-at": "document-start",
      },
      build: {
        fileName: "recruiter.user.js",
      },
    }),
  ],
});
