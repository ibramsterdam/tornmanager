import { Dom } from "@shared/core/Dom.js";
import { LineChart } from "./LineChart.js";
import { money, number, percent } from "../core/Format.js";

const RANGES = [
  [30, "30 days"],
  [90, "90 days"],
  [365, "1 year"],
];

export class ChartsScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
    this.days = 30;
  }

  subtitle() {
    return "charts";
  }

  render(container) {
    container.replaceChildren();
    container.appendChild(this.rangePicker(container));
    const charts = Dom.el("div", "tc-charts");
    charts.appendChild(Dom.el("div", "tc-empty", "Loading history…"));
    container.appendChild(charts);

    this.api
      .history(this.days)
      .then((data) => this.renderCharts(charts, data))
      .catch((error) => this.overlay.handleError(error, charts));
  }

  rangePicker(container) {
    const row = Dom.el("div", "tc-chips");
    for (const [days, label] of RANGES) {
      const chip = Dom.el("button", `tc-chip tc-chip--filter${days === this.days ? " tc-chip--on" : ""}`, label);
      chip.addEventListener("click", () => {
        this.days = days;
        this.render(container);
      });
      row.appendChild(chip);
    }
    return row;
  }

  renderCharts(charts, { dates, series }) {
    charts.replaceChildren(
      new LineChart({ title: "Income per day", dates, format: money, series: [{ label: "Income", values: series.income }] }).render(),
      new LineChart({
        title: "Income per employee against similar companies",
        dates,
        format: money,
        series: [
          { label: "You", values: series.income_per_employee },
          { label: "Median", values: series.peer_median_per_employee, dashed: true },
          { label: "Top 10%", values: series.peer_top_per_employee, dashed: true },
        ],
      }).render(),
      new LineChart({ title: "Customers per day", dates, format: number, series: [{ label: "Customers", values: series.customers }] }).render(),
      new LineChart({
        title: "Wages against income",
        dates,
        format: money,
        series: [
          { label: "Income", values: series.income },
          { label: "Wages", values: series.wages },
        ],
      }).render(),
      new LineChart({ title: "Company funds", dates, format: money, series: [{ label: "Funds", values: series.funds }] }).render(),
      new LineChart({
        title: "Popularity, efficiency and environment",
        dates,
        format: percent,
        series: [
          { label: "Popularity", values: series.popularity },
          { label: "Efficiency", values: series.efficiency },
          { label: "Environment", values: series.environment },
        ],
      }).render(),
      new LineChart({ title: "Average staff effectiveness", dates, format: number, series: [{ label: "Effectiveness", values: series.effectiveness }] }).render()
    );
  }
}
