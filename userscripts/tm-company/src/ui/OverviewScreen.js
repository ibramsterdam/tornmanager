import { Dom } from "@shared/core/Dom.js";
import { money, number, percent, ago } from "../core/Format.js";

const PENDING_POLL_MS = 10_000;
const PENDING_MAX_POLLS = 18;

export class OverviewScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
    this.polls = 0;
  }

  subtitle() {
    return "overview";
  }

  render(container) {
    clearTimeout(this.pollTimer);
    container.replaceChildren(Dom.el("div", "tc-empty", "Loading your company…"));

    this.api
      .overview()
      .then((data) => {
        if (data.pending) return this.renderPending(container);
        this.polls = 0;
        this.renderReport(container, data);
      })
      .catch((error) => this.overlay.handleError(error, container));
  }

  renderPending(container) {
    if (this.polls >= PENDING_MAX_POLLS) {
      container.replaceChildren(Dom.el("div", "tc-empty", "Your company could not be loaded yet. Try again in a few minutes."));
      return;
    }
    this.polls += 1;
    container.replaceChildren(
      Dom.el("div", "tc-empty", "Reading your company from Torn for the first time. This takes about a minute…")
    );
    this.pollTimer = setTimeout(() => {
      if (this.overlay.current !== "overview") return;
      this.api.overview({ fresh: true }).then(() => this.render(container)).catch((error) => this.overlay.handleError(error, container));
    }, PENDING_POLL_MS);
  }

  renderReport(container, data) {
    const { company, benchmark, advice } = data;
    container.replaceChildren();

    container.appendChild(this.header(container, company));
    container.appendChild(this.kpis(company));
    if (benchmark) container.appendChild(this.rank(company, benchmark));
    container.appendChild(this.status(company));
    container.appendChild(this.advice(advice));
  }

  header(container, company) {
    const head = Dom.el("div", "tc-co-head");
    const title = Dom.el("div", "tc-co-title");
    const name = Dom.el("a", "tc-co-name", company.name);
    name.href = `https://www.torn.com/joblist.php#/p=corpinfo&ID=${company.id}`;
    name.target = "_blank";
    name.rel = "noopener";
    title.append(name, Dom.el("div", "tc-dim", `${company.type_name} · ${"★".repeat(company.rating || 0)} · updated ${ago(company.captured_at)}`));

    const refresh = Dom.el("button", "tc-btn tc-btn--ghost tc-btn--sm", "Refresh");
    refresh.addEventListener("click", () => this.refresh(container, refresh));

    head.append(title, refresh);
    return head;
  }

  refresh(container, button) {
    button.disabled = true;
    button.textContent = "Refreshing…";
    this.api
      .refresh()
      .then((result) => {
        if (!result.queued) {
          button.textContent = "Up to date";
          return;
        }
        setTimeout(() => {
          if (this.overlay.current === "overview") this.render(container);
        }, 20_000);
      })
      .catch((error) => this.overlay.handleError(error, container));
  }

  kpis(company) {
    const grid = Dom.el("div", "tc-kpis");
    const items = [
      ["Income / day", money(company.income_daily), `${money(company.income_weekly)} this week`],
      ["Profit / day", money(company.profit_daily), company.profit_daily == null ? "needs wage data" : "income minus wages and ads"],
      ["Customers / day", number(company.customers_daily), `${number(company.customers_weekly)} this week`],
      ["Wages / day", money(company.wages_daily), company.advertising_daily ? `${money(company.advertising_daily)} ads` : "no advertising"],
      ["Staff", `${number(company.hired)} / ${number(company.capacity)}`, company.capacity > company.hired ? `${company.capacity - company.hired} empty` : "full"],
      ["Funds", money(company.funds), "company bank"],
    ];
    for (const [label, value, sub] of items) {
      const kpi = Dom.el("div", "tc-kpi");
      kpi.append(Dom.el("div", "tc-kpi-label", label), Dom.el("div", "tc-kpi-value", value), Dom.el("div", "tc-kpi-sub", sub));
      if (label === "Profit / day" && company.profit_daily < 0) kpi.classList.add("tc-kpi--bad");
      grid.appendChild(kpi);
    }
    return grid;
  }

  rank(company, benchmark) {
    const card = Dom.el("div", "tc-card tc-rank");
    card.appendChild(Dom.el("div", "tc-label", `Among ${benchmark.peers} ${company.rating}★ ${company.type_name} companies`));

    const row = Dom.el("div", "tc-rank-row");
    row.append(
      stat("Rank by income", benchmark.rank ? `${benchmark.rank} of ${benchmark.peers}` : "–"),
      stat("You, per employee", money(benchmark.income_per_employee)),
      stat("Median", money(benchmark.median_per_employee)),
      stat("Top 10%", money(benchmark.top_per_employee))
    );
    card.appendChild(row);

    const max = Math.max(benchmark.income_per_employee || 0, benchmark.top_per_employee || 0, 1);
    const bar = Dom.el("div", "tc-meter");
    const fill = Dom.el("div", "tc-meter-fill");
    fill.style.width = `${Math.min(100, ((benchmark.income_per_employee || 0) / max) * 100)}%`;
    const median = Dom.el("div", "tc-meter-mark");
    median.style.left = `${Math.min(100, ((benchmark.median_per_employee || 0) / max) * 100)}%`;
    median.title = "Median";
    bar.append(fill, median);
    card.appendChild(bar);
    return card;
  }

  status(company) {
    const row = Dom.el("div", "tc-chips tc-status");
    const items = [
      ["Popularity", percent(company.popularity)],
      ["Efficiency", percent(company.efficiency)],
      ["Environment", percent(company.environment)],
      ["Trains", company.trains == null ? "–" : `${company.trains} / 20`],
    ];
    for (const [label, value] of items) {
      const chip = Dom.el("span", "tc-chip");
      chip.append(Dom.el("span", "tc-dim", `${label} `), Dom.el("strong", null, value));
      row.appendChild(chip);
    }
    return row;
  }

  advice(items) {
    const card = Dom.el("div", "tc-card");
    card.appendChild(Dom.el("div", "tc-label", "Advice"));
    if (!items.length) {
      card.appendChild(Dom.el("div", "tc-dim", "Nothing to fix right now."));
      return card;
    }
    const list = Dom.el("div", "tc-advice");
    for (const item of items) {
      const entry = Dom.el("div", `tc-advice-item tc-advice-item--${item.level}`);
      entry.append(Dom.el("div", "tc-advice-title", item.title), Dom.el("div", "tc-advice-detail", item.detail));
      list.appendChild(entry);
    }
    card.appendChild(list);
    return card;
  }
}

function stat(label, value) {
  const node = Dom.el("div", "tc-rank-stat");
  node.append(Dom.el("div", "tc-kpi-label", label), Dom.el("div", "tc-rank-value", value));
  return node;
}
