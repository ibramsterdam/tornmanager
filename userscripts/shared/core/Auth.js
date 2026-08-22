import { post } from "./ServerApi.js";

// Sign-in and subscription against the tornmanager API. The Torn API key is
// sent exactly once at sign-in; everything after uses the bearer token.
export class Auth {
  constructor(store) {
    this.store = store;
  }

  getUser() {
    return this.store.get("user");
  }

  getToken() {
    return this.getUser()?.token || null;
  }

  isAuthenticated() {
    return this.getToken() != null;
  }

  clear() {
    this.store.remove("user");
    this.store.remove("subscription");
  }

  authenticate(apiKey) {
    return post("/api/session", { api_key: apiKey }).then((data) => {
      this.store.set("user", { ...data.user, token: data.token });
      return data.user;
    });
  }

  fetchSubscription({ refresh = false } = {}) {
    const token = this.getToken();
    if (!token) return Promise.reject(new Error("Not signed in"));

    const body = {};
    if (refresh) body.refresh = true;

    return post("/api/subscription", body, { token }).then((data) => {
      const subscription = { ...data.subscription, checkedAt: Date.now() };
      this.store.set("subscription", subscription);
      return subscription;
    });
  }

  subscription() {
    return this.store.get("subscription");
  }

  isSubscribed() {
    const sub = this.subscription();
    if (!sub?.active) return false;
    return !sub.expires_at || new Date(sub.expires_at) > new Date();
  }
}
