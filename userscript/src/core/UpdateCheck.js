const CURRENT = __TM_VERSION__;
const MANIFEST_URL =
  "https://raw.githubusercontent.com/ibramsterdam/tornmanager/main/userscript/package.json";
export const DOWNLOAD_URL =
  "https://github.com/ibramsterdam/tornmanager/raw/main/userscript/tornmanager.user.js";

const CACHE_KEY = "tm_version_check";
const CACHE_TTL_MS = 60 * 60 * 1000;

function isNewer(latest, current) {
  const a = latest.split(".").map(Number);
  const b = current.split(".").map(Number);
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    const diff = (a[i] || 0) - (b[i] || 0);
    if (diff !== 0) return diff > 0;
  }
  return false;
}

function cachedLatest() {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    const { latest, at } = JSON.parse(raw);
    if (!latest || Date.now() - at > CACHE_TTL_MS) return null;
    return latest;
  } catch {
    return null;
  }
}

function fetchLatest() {
  return new Promise((resolve) => {
    GM.xmlHttpRequest({
      method: "GET",
      url: `${MANIFEST_URL}?t=${Math.floor(Date.now() / CACHE_TTL_MS)}`,
      headers: { Accept: "application/json" },
      onload(response) {
        try {
          const version = JSON.parse(response.responseText).version;
          if (version) {
            localStorage.setItem(CACHE_KEY, JSON.stringify({ latest: version, at: Date.now() }));
          }
          resolve(version || null);
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

  // Resolves to the latest published version if this build is behind it,
  // otherwise null. Never rejects — a failed check simply shows no notice.
  async outdatedVersion() {
    const latest = cachedLatest() || (await fetchLatest());
    return latest && isNewer(latest, CURRENT) ? latest : null;
  },
};
