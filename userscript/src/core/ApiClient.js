const API_BASE = __API_BASE__;

export class ApiClient {
  constructor(auth) {
    this.auth = auth;
  }

  fetchCurrentWar() {
    const apiKey = this.auth.getApiKey();
    if (!apiKey) return Promise.reject(new Error("Not authenticated"));

    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "POST",
        url: `${API_BASE}/api/current_war`,
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        data: JSON.stringify({ api_key: apiKey }),
        onload(response) {
          if (response.status === 200) {
            try {
              resolve(JSON.parse(response.responseText));
            } catch {
              reject(new Error("Invalid response from server"));
            }
          } else {
            try {
              const data = JSON.parse(response.responseText);
              reject(new Error(data.error || "Could not fetch war data"));
            } catch {
              reject(new Error("Could not fetch war data"));
            }
          }
        },
        onerror() {
          reject(new Error("Network error. Could not reach Tornmanager."));
        },
      });
    });
  }
}
