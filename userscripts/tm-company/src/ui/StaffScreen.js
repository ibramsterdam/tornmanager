import { Dom } from "@shared/core/Dom.js";
import { money, short } from "../core/Format.js";

const FLAGS = {
  addicted: ["Addicted", "bad"],
  inactive: ["Inactive", "bad"],
  low_effectiveness: ["Low effectiveness", "bad"],
  below_requirement: ["Below requirement", "warn"],
  costs_more_than_value: ["Costs more than value", "warn"],
  settling_in: ["Settling in", "info"],
};

const STATS = [
  ["manual_labor", "MAN"],
  ["intelligence", "INT"],
  ["endurance", "END"],
];

const EFFECTIVENESS_PARTS = [
  ["working_stats", "Working stats"],
  ["settled_in", "Settled in"],
  ["book", "Book"],
  ["merits", "Merits"],
  ["director_education", "Director education"],
  ["management", "Management"],
  ["wrong_gender", "Wrong gender"],
  ["addiction", "Addiction"],
  ["inactivity", "Inactivity"],
];

export class StaffScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
  }

  subtitle() {
    return "staff";
  }

  render(container) {
    container.replaceChildren(Dom.el("div", "tc-empty", "Loading staff…"));
    this.api
      .overview()
      .then((data) => {
        if (data.pending) {
          container.replaceChildren(Dom.el("div", "tc-empty", "Your company is still being read. Check the Overview in a minute."));
          return;
        }
        container.replaceChildren(this.balance(data.balance), this.employees(data.employees));
      })
      .catch((error) => this.overlay.handleError(error, container));
  }

  balance(balance) {
    const card = Dom.el("div", "tc-card");
    card.appendChild(Dom.el("div", "tc-label", "Staff per position"));
    const list = Dom.el("div", "tc-positions");
    for (const position of balance.positions) {
      const item = Dom.el("div", `tc-position${position.count === 0 ? " tc-position--empty" : ""}`);
      item.append(Dom.el("span", "tc-position-count", String(position.count)), Dom.el("span", null, position.name));
      if (position.ability) item.appendChild(Dom.el("span", "tc-dim", position.ability));
      list.appendChild(item);
    }
    card.appendChild(list);
    if (balance.missing_abilities.length) {
      card.appendChild(Dom.el("div", "tc-hint", `Nobody fills these special roles: ${balance.missing_abilities.join(", ")}.`));
    }
    return card;
  }

  employees(employees) {
    const card = Dom.el("div", "tc-card");
    card.appendChild(Dom.el("div", "tc-label", `Employees (${employees.length})`));
    const sorted = [...employees].sort((a, b) => b.flags.length - a.flags.length || (a.effectiveness?.total ?? 0) - (b.effectiveness?.total ?? 0));
    for (const employee of sorted) card.appendChild(this.employee(employee));
    return card;
  }

  employee(employee) {
    const row = Dom.el("details", "tc-emp");
    const summary = Dom.el("summary", "tc-emp-summary");

    const who = Dom.el("div", "tc-emp-who");
    const link = Dom.el("a", "tc-name", employee.name);
    link.href = `https://www.torn.com/profiles.php?XID=${employee.id}`;
    link.target = "_blank";
    link.rel = "noopener";
    who.append(link, Dom.el("div", "tc-dim", `${employee.position} · ${employee.days_in_company ?? "?"} days · ${employee.last_action || ""}`));

    const flags = Dom.el("div", "tc-flags");
    for (const flag of employee.flags) {
      const [label, tone] = FLAGS[flag] || [flag, "info"];
      flags.appendChild(Dom.el("span", `tc-flag tc-flag--${tone}`, label));
    }

    const numbers = Dom.el("div", "tc-emp-numbers");
    const total = employee.effectiveness?.total;
    numbers.append(Dom.el("div", "tc-emp-eff", total == null ? "–" : `${total}%`), Dom.el("div", "tc-dim", employee.wage == null ? "" : `${money(employee.wage)}/day`));

    summary.append(who, flags, numbers);
    row.appendChild(summary);
    row.appendChild(this.details(employee));
    return row;
  }

  details(employee) {
    const body = Dom.el("div", "tc-emp-details");

    const stats = Dom.el("div", "tc-emp-stats");
    for (const [key, label] of STATS) {
      const required = employee.required?.[key] || 0;
      const value = employee.stats?.[key];
      const cell = Dom.el("div", `tc-emp-stat${required && value != null && value < required ? " tc-emp-stat--low" : ""}`);
      cell.append(Dom.el("div", "tc-kpi-label", label), Dom.el("div", null, value == null ? "–" : short(value)), Dom.el("div", "tc-dim", required ? `needs ${short(required)}` : "not needed"));
      stats.appendChild(cell);
    }
    body.appendChild(stats);

    if (employee.effectiveness && Object.keys(employee.effectiveness).length) {
      const parts = Dom.el("div", "tc-emp-parts");
      for (const [key, label] of EFFECTIVENESS_PARTS) {
        const value = employee.effectiveness[key];
        if (!value) continue;
        parts.appendChild(Dom.el("span", `tc-chip${value < 0 ? " tc-chip--bad" : ""}`, `${label} ${value > 0 ? "+" : ""}${value}`));
      }
      body.appendChild(parts);
    }

    if (employee.status && employee.status !== "Okay") body.appendChild(Dom.el("div", "tc-dim", employee.status));
    if (employee.value != null) body.appendChild(Dom.el("div", "tc-dim", `Value ${money(employee.value)}/day, wage ${money(employee.wage)}/day`));
    return body;
  }
}
