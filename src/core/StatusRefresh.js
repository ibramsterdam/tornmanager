import { Store } from "./Store.js";

export class StatusRefresh {
  constructor(api) {
    this.api = api;
    this.data = Store.get("status", { byId: {}, fetchedAt: null });
  }

  async refresh(companyIds, { onProgress, shouldStop } = {}) {
    const tasks = companyIds.map((id) => ({ path: `/company/${id}/employees` }));
    const results = await this.api.runBatch(tasks, { onProgress, shouldStop });

    const byId = this.data.byId || {};
    for (const result of results) {
      if (!result || result instanceof Error) continue;
      for (const employee of result.employees || []) {
        const action = employee.last_action || {};
        byId[employee.id] = {
          status: action.status || "Offline",
          relative: action.relative || "",
          timestamp: action.timestamp || null,
          position: typeof employee.position === "object" ? employee.position?.name : employee.position,
          days: employee.days_in_company ?? null,
        };
      }
    }

    this.data = { byId, fetchedAt: Date.now() };
    Store.set("status", this.data);
    return this.data;
  }
}
