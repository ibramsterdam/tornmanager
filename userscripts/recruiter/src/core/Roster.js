import { parseCsv } from "./Csv.js";
import { Store } from "./Store.js";

export class Roster {
  constructor(api) {
    this.api = api;
    this.data = Store.get("roster");
  }

  async update(settings, { onProgress } = {}) {
    onProgress?.("Downloading company snapshot…");
    const companyCsv = await this.api.call("/company/snapshot");

    onProgress?.("Downloading player snapshot…");
    const userCsv = await this.api.call("/user/snapshot");

    onProgress?.("Building roster…");
    const wantedTypes = new Set(settings.typeIds.map(String));
    const companies = {};
    for (const row of parseCsv(companyCsv)) {
      const rating = Number(row.rating || 0);
      if (!wantedTypes.has(row.type)) continue;
      if (rating < settings.starMin || rating > settings.starMax) continue;
      companies[row.id] = {
        name: row.name,
        typeId: Number(row.type),
        rating,
        hired: Number(row.employees_hired || 0),
      };
    }

    const players = [];
    for (const row of parseCsv(userCsv)) {
      const company = companies[row.company];
      if (!company) continue;
      players.push({
        id: Number(row.id),
        name: row.name,
        level: Number(row.level || 0),
        companyId: Number(row.company),
        director: row.job === "Director",
      });
    }

    this.data = { companies, players, fetchedAt: Date.now() };
    Store.set("roster", this.data);
    return this.data;
  }
}
