import { post } from "@shared/core/ServerApi.js";

export class RecruiterApi {
  constructor(auth) {
    this.auth = auth;
  }

  matches(filters) {
    return this.post("/api/recruiter/matches", filters);
  }

  status(companyIds, { refresh = false } = {}) {
    const body = { company_ids: companyIds };
    if (refresh) body.refresh = true;
    return this.post("/api/recruiter/status", body);
  }

  submitKey(key) {
    return this.post("/api/recruiter/submit_key", { key });
  }

  revokeKey(tornId) {
    return this.post("/api/recruiter/revoke_key", { torn_id: tornId });
  }

  post(path, body) {
    const token = this.auth.getToken();
    if (!token) return Promise.reject(new Error("Not signed in"));

    return post(path, body, { token });
  }
}
