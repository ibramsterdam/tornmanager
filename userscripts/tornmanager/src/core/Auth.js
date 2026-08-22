const STORAGE_KEY = "tm_user";
const API_BASE = __API_BASE__;

export class Auth {
  getUser() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  getApiKey() {
    return this.getUser()?.api_key || null;
  }

  isAuthenticated() {
    const user = this.getUser();
    return user !== null && user.api_key != null;
  }

  clear() {
    localStorage.removeItem(STORAGE_KEY);
  }

  authenticate(apiKey) {
    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "POST",
        url: `${API_BASE}/api/session`,
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        data: JSON.stringify({ api_key: apiKey }),
        onload(response) {
          if (response.status === 200) {
            try {
              const data = JSON.parse(response.responseText);
              localStorage.setItem(
                STORAGE_KEY,
                JSON.stringify({ ...data.user, api_key: apiKey })
              );
              resolve(data.user);
            } catch {
              reject(new Error("Invalid response from server"));
            }
          } else {
            try {
              const data = JSON.parse(response.responseText);
              reject(new Error(data.error || "Authentication failed"));
            } catch {
              reject(new Error("Authentication failed"));
            }
          }
        },
        onerror() {
          reject(new Error("Network error. Could not reach Tornmanager."));
        },
      });
    });
  }

  fetchSubscription({ refresh = false } = {}) {
    const apiKey = this.getApiKey();
    if (!apiKey) return Promise.reject(new Error("Not authenticated"));

    const body = { api_key: apiKey };
    if (refresh) body.refresh = true;

    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "POST",
        url: `${API_BASE}/api/subscription`,
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        data: JSON.stringify(body),
        onload(response) {
          if (response.status === 200) {
            try {
              resolve(JSON.parse(response.responseText).subscription);
            } catch {
              reject(new Error("Invalid response from server"));
            }
          } else if (response.status === 429) {
            try {
              const data = JSON.parse(response.responseText);
              const err = new Error(data.error || "Too many requests");
              err.rateLimited = true;
              reject(err);
            } catch {
              const err = new Error("Too many requests. Try again later.");
              err.rateLimited = true;
              reject(err);
            }
          } else {
            try {
              const data = JSON.parse(response.responseText);
              const err = new Error(data.error || "Could not fetch subscription");
              if (data.suspended) err.suspended = true;
              reject(err);
            } catch {
              reject(new Error("Could not fetch subscription"));
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
