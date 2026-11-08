import { Auth } from "@shared/core/Auth.js";
import { post } from "@shared/core/ServerApi.js";

export class CompanyAuth extends Auth {
  authenticate(apiKey) {
    return post("/api/company/session", { api_key: apiKey }).then((data) => {
      this.store.set("user", { ...data.user, token: data.token });
      this.store.set("company", data.company);
      return data;
    });
  }

  company() {
    return this.store.get("company");
  }

  clear() {
    super.clear();
    this.store.remove("company");
  }
}
