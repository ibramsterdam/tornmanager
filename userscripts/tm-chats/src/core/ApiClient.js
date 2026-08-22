import { post } from "@shared/core/ServerApi.js";

export class ApiClient {
  constructor(auth) {
    this.auth = auth;
  }

  fetchCurrentWar() {
    const token = this.auth.getToken();
    if (!token) return Promise.reject(new Error("Not authenticated"));

    return post("/api/current_war", {}, { token });
  }
}
