import { post } from "@shared/core/ServerApi.js";

const OVERVIEW_TTL_MS = 60_000;

export class CompanyApi {
  constructor(auth) {
    this.auth = auth;
    this.cached = null;
  }

  overview({ fresh = false } = {}) {
    if (!fresh && this.cached && Date.now() - this.cached.at < OVERVIEW_TTL_MS) return this.cached.promise;

    const promise = this.post("/api/company/overview").catch((error) => {
      this.cached = null;
      throw error;
    });
    this.cached = { at: Date.now(), promise };
    return promise;
  }

  history(days) {
    return this.post("/api/company/history", { days });
  }

  news() {
    return this.post("/api/company/news");
  }

  refresh() {
    this.cached = null;
    return this.post("/api/company/refresh");
  }

  revokeKey() {
    this.cached = null;
    return this.post("/api/company/revoke_key");
  }

  post(path, body = {}) {
    const token = this.auth.getToken();
    if (!token) return Promise.reject(Object.assign(new Error("Not signed in"), { reauth: true }));

    return post(path, body, { token }).catch((error) => {
      if (error.status === 401) error.reauth = true;
      if (error.data?.subscription_required) error.subscriptionRequired = true;
      throw error;
    });
  }
}
