const CURRENT = __TM_VERSION__;
const MANIFEST_URL =
  "https://raw.githubusercontent.com/ibramsterdam/tornmanager/main/userscripts/tm-chats/package.json";
export const DOWNLOAD_URL =
  "https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tm-chats.user.js";

const CACHE_KEY = "tm_version_check";
const CACHE_TTL_MS = 10 * 60 * 1000;

function isNewer(a, b) {
  const x = String(a).split(".").map(Number);
  const y = String(b).split(".").map(Number);
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    const diff = (x[i] || 0) - (y[i] || 0);
    if (diff !== 0) return diff > 0;
  }
  return false;
}

function cachedManifest() {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const { manifest, at } = JSON.parse(raw);
    if (!manifest || Date.now() - at > CACHE_TTL_MS) return null;
    return manifest;
  } catch {
    return null;
  }
}

function fetchManifest() {
  return new Promise((resolve) => {
    GM.xmlHttpRequest({
      method: "GET",
      url: `${MANIFEST_URL}?t=${Math.floor(Date.now() / CACHE_TTL_MS)}`,
      headers: { Accept: "application/json" },
      onload(response) {
        try {
          const parsed = JSON.parse(response.responseText);
          const manifest = { version: parsed.version, minSupportedVersion: parsed.minSupportedVersion || "0.0.0" };
          if (manifest.version) {
            localStorage.setItem(CACHE_KEY, JSON.stringify({ manifest, at: Date.now() }));
          }
          resolve(manifest.version ? manifest : null);
        } catch {
          resolve(null);
        }
      },
      onerror() {
        resolve(null);
      },
    });
  });
}

export const UpdateCheck = {
  current: CURRENT,

  // Resolves to { latest, outdated, forced }. `outdated` means a newer version
  // exists; `forced` means this build is below the minimum supported version
  // and should be hard-gated. Never rejects — a failed check reports neither.
  async status() {
    const manifest = cachedManifest() || (await fetchManifest());
    if (!manifest || !manifest.version) {
      return { latest: null, outdated: false, forced: false };
    }
    return {
      latest: manifest.version,
      outdated: isNewer(manifest.version, CURRENT),
      forced: isNewer(manifest.minSupportedVersion, CURRENT),
    };
  },
};
