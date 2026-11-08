import { Dom } from "@shared/core/Dom.js";

export class NewsScreen {
  constructor(api, overlay) {
    this.api = api;
    this.overlay = overlay;
  }

  subtitle() {
    return "news";
  }

  render(container) {
    container.replaceChildren(Dom.el("div", "tc-empty", "Loading news…"));
    this.api
      .news()
      .then(({ news }) => {
        if (!news.length) {
          container.replaceChildren(Dom.el("div", "tc-empty", "No company news stored yet."));
          return;
        }
        const list = Dom.el("div", "tc-card tc-news");
        for (const entry of news) {
          const item = Dom.el("div", "tc-news-item");
          const when = new Date(entry.occurred_at).toLocaleString("en-GB", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit", timeZone: "UTC" });
          item.append(Dom.el("div", "tc-dim", `${when} TCT`), Dom.el("div", null, entry.text));
          list.appendChild(item);
        }
        container.replaceChildren(list);
      })
      .catch((error) => this.overlay.handleError(error, container));
  }
}
