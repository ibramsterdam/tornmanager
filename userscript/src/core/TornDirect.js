const BASE = "https://api.torn.com/v2";

export const TornDirect = {
  keyInfo(key) {
    return this.get("/key/info", key);
  },

  get(path, key) {
    const separator = path.includes("?") ? "&" : "?";
    const url = `${BASE}${path}${separator}key=${encodeURIComponent(key)}`;

    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "GET",
        url,
        headers: { Accept: "application/json" },
        onload(response) {
          let data = null;
          try {
            data = JSON.parse(response.responseText);
          } catch {
            reject(new Error("Invalid response from Torn."));
            return;
          }

          if (data && data.error) {
            reject(new Error(data.error.error || "Torn API error."));
            return;
          }

          resolve(data);
        },
        onerror() {
          reject(new Error("Network error contacting Torn."));
        },
      });
    });
  },
};
