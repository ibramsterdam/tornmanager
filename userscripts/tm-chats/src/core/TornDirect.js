const BASE_V2 = "https://api.torn.com/v2";
const BASE_V1 = "https://api.torn.com";

export const TornDirect = {
  keyInfo(key) {
    return this.get("/key/info", key);
  },

  get(path, key) {
    return this.request(`${BASE_V2}${path}`, key);
  },

  getV1(path, key) {
    return this.request(`${BASE_V1}${path}`, key);
  },

  request(url, key) {
    const separator = url.includes("?") ? "&" : "?";
    const fullUrl = `${url}${separator}key=${encodeURIComponent(key)}&comment=tmanager`;

    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "GET",
        url: fullUrl,
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
            const err = new Error(data.error.error || "Torn API error.");
            err.code = data.error.code;
            reject(err);
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
