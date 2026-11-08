import { Dom } from "@shared/core/Dom.js";
import { money, number } from "../core/Format.js";

export class StockScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
  }

  subtitle() {
    return "stock";
  }

  render(container) {
    container.replaceChildren(Dom.el("div", "tc-empty", "Loading stock…"));
    this.api
      .overview()
      .then((data) => {
        if (data.pending) {
          container.replaceChildren(Dom.el("div", "tc-empty", "Your company is still being read. Check the Overview in a minute."));
          return;
        }
        container.replaceChildren(this.table(data.stock));
      })
      .catch((error) => this.overlay.handleError(error, container));
  }

  table(stock) {
    const card = Dom.el("div", "tc-card");
    card.appendChild(Dom.el("div", "tc-label", "Stock"));
    if (!stock.length) {
      card.appendChild(Dom.el("div", "tc-dim", "No stock data. Torn only shares stock with a Limited key."));
      return card;
    }

    const table = Dom.el("table", "tc-tbl");
    const head = Dom.el("tr");
    for (const label of ["Item", "Price", "RRP", "Cost", "In stock", "On order", "Sold", "Days left"]) head.appendChild(Dom.el("th", null, label));
    table.appendChild(head);

    for (const item of stock) {
      const row = Dom.el("tr");
      const daysLeft = Dom.el("td", item.days_left != null && item.days_left < 2 ? "tc-bad" : null, item.days_left == null ? "–" : String(item.days_left));
      row.append(
        Dom.el("td", null, item.name),
        Dom.el("td", null, money(item.price)),
        Dom.el("td", null, money(item.rrp)),
        Dom.el("td", null, money(item.cost)),
        Dom.el("td", null, number(item.in_stock)),
        Dom.el("td", null, number(item.on_order)),
        Dom.el("td", null, `${number(item.sold_amount)} (${money(item.sold_worth)})`),
        daysLeft
      );
      table.appendChild(row);
    }
    card.appendChild(table);
    card.appendChild(Dom.el("div", "tc-hint", "Days left is stock plus orders divided by the last day's sales."));
    return card;
  }
}
