import { Store } from "./Store.js";

const API_BASE = __API_BASE__;

export class Auth {
  getUser() {
    return Store.get("user");
  }

  getApiKey() {
    return this.getUser()?.api_key || null;
  }

  isAuthenticated() {
    return this.getApiKey() != null;
  }

  clear() {
    Store.remove("user");
    Store.remove("subscription");
  }

  authenticate(apiKey) {
    return this.post("/api/session", { api_key: apiKey }).then((data) => {
      Store.set("user", { ...data.user, api_key: apiKey });
      return data.user;
    });
  }

  fetchSubscription({ refresh = false } = {}) {
    const apiKey = this.getApiKey();
    if (!apiKey) return Promise.reject(new Error("Not signed in"));

    const body = { api_key: apiKey };
    if (refresh) body.refresh = true;

    return this.post("/api/subscription", body).then((data) => {
      const subscription = { ...data.subscription, checkedAt: Date.now() };
      Store.set("subscription", subscription);
      return subscription;
    });
  }

  subscription() {
    return Store.get("subscription");
  }

  isSubscribed() {
    const sub = this.subscription();
    if (!sub?.active) return false;
    return !sub.expires_at || new Date(sub.expires_at) > new Date();
  }

  post(path, body) {
    return new Promise((resolve, reject) => {
      GM.xmlHttpRequest({
        method: "POST",
        url: `${API_BASE}${path}`,
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        data: JSON.stringify(body),
        onload(response) {
          let data;
          try {
            data = JSON.parse(response.responseText);
          } catch {
            data = null;
          }
          if (response.status === 200 && data) {
            resolve(data);
          } else {
            const error = new Error(data?.error || "Request failed");
            if (response.status === 429) error.rateLimited = true;
            if (data?.suspended) error.suspended = true;
            reject(error);
          }
        },
        onerror() {
          reject(new Error("Network error. Could not reach Tornmanager."));
        },
      });
    });
  }
}
