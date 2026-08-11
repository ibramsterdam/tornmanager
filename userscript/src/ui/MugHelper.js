import { Dom } from "../core/Dom.js";
import { MugKey } from "../core/MugKey.js";
import { MugTargets } from "../core/MugTargets.js";
import { parseMoney, formatMoney } from "../core/Money.js";
import { showToast } from "../core/Clipboard.js";

const OPEN_KEY = "tm_mug_helper_open";
const POS_KEY = "tm_mug_helper_pos";
const SIZE_KEY = "tm_mug_helper_size";
const DRAG_THRESHOLD_PX = 6;
const MIN_WIDTH = 260;
const MIN_HEIGHT = 240;

// Mirrors DEV_TORN_ID in Overlay.js. The helper only mounts for the dev account
// while the Mugging tools are in development.
const DEV_TORN_ID = 2728237;

const HELPER_ICON =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="4" width="18" height="16" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/></svg>';

const NAV_LINKS = [
  { label: "Russian Roulette", url: "https://www.torn.com/page.php?sid=russianRoulette#/" },
  { label: "Poker", url: "https://www.torn.com/page.php?sid=holdem" },
  { label: "Item Market", url: "https://www.torn.com/page.php?sid=ItemMarket" },
  { label: "Bazaar", url: "https://www.torn.com/page.php?sid=bazaar" },
  { label: "Auction House", url: "https://www.torn.com/amarket.php" },
];

let zCounter = 99995;

export class MugHelper {
  constructor(auth) {
    this.auth = auth;
    this.element = null;
    this.onResize = null;
  }

  init() {
    if (this.auth?.getUser()?.torn_id !== DEV_TORN_ID) return;
    if (!this.isOpen()) return;
    Dom.ready("body", () => this.open());
  }

  isOpen() {
    return localStorage.getItem(OPEN_KEY) === "1";
  }

  setOpenState(open) {
    try {
      localStorage.setItem(OPEN_KEY, open ? "1" : "0");
    } catch {
      return;
    }
  }

  toggle() {
    if (this.element) this.close();
    else this.open();
  }

  open() {
    if (this.element) {
      this.element.style.zIndex = ++zCounter;
      return;
    }
    this.render();
    this.setOpenState(true);
  }

  close() {
    if (this.onResize) {
      window.removeEventListener("resize", this.onResize);
      this.onResize = null;
    }
    if (this.navPoll) {
      clearInterval(this.navPoll);
      this.navPoll = null;
    }
    this.clearHighlights();
    this.element?.remove();
    this.element = null;
    this.setOpenState(false);
  }

  render() {
    this.element = document.createElement("div");
    this.element.className = "tm-mh";

    const header = this.createHeader();
    this.element.appendChild(header);

    this.body = document.createElement("div");
    this.body.className = "tm-mh-body";
    this.element.appendChild(this.body);
    this.renderBody();

    this.element.addEventListener("pointerdown", () => {
      this.element.style.zIndex = ++zCounter;
    });

    this.makeDraggable(header);
    this.applySize();
    this.addResizeHandle();
    this.applyPosition();

    document.body.appendChild(this.element);

    this.onResize = () => this.clampPosition();
    window.addEventListener("resize", this.onResize);

    // Torn's Item Market is a single-page app that swaps items via pushState
    // without firing hashchange, so poll the viewed item and re-render on change.
    this.navPoll = setInterval(() => {
      if (MugTargets.currentItemId() !== this.lastItemId) this.renderBody();
    }, 700);
  }

  createHeader() {
    const header = document.createElement("div");
    header.className = "tm-mh-header";

    const title = document.createElement("span");
    title.className = "tm-mh-title";
    title.textContent = "Mug helper";
    header.appendChild(title);

    const close = document.createElement("button");
    close.type = "button";
    close.className = "tm-mh-action";
    close.title = "Close";
    close.textContent = "×";
    close.onclick = () => this.close();
    header.appendChild(close);

    return header;
  }

  renderBody() {
    this.lastItemId = MugTargets.currentItemId();
    this.body.innerHTML = "";
    this.body.appendChild(this.navEl());

    this.content = document.createElement("div");
    this.content.className = "tm-mh-content";
    this.body.appendChild(this.content);

    this.renderContent();
  }

  navEl() {
    const nav = document.createElement("div");
    nav.className = "tm-mh-nav";
    for (const link of NAV_LINKS) {
      const anchor = document.createElement("a");
      anchor.className = "tm-mh-nav-link";
      anchor.href = link.url;
      anchor.textContent = link.label;
      if (this.isCurrentPage(link.url)) anchor.classList.add("tm-mh-nav-link--active");
      nav.appendChild(anchor);
    }
    return nav;
  }

  isCurrentPage(url) {
    try {
      const target = new URL(url);
      if (location.pathname !== target.pathname) return false;
      const targetSid = new URLSearchParams(target.search).get("sid");
      if (!targetSid) return true;
      const currentSid = new URLSearchParams(location.search).get("sid") || "";
      return currentSid.toLowerCase() === targetSid.toLowerCase();
    } catch {
      return false;
    }
  }

  renderContent() {
    this.content.innerHTML = "";

    if (!MugKey.get()) {
      this.content.appendChild(
        this.placeholder("Mug targets", "Connect your Full Access key on the Mugging tab to scan targets."),
      );
      return;
    }

    if (MugTargets.onBazaarDirectory()) {
      this.renderTargets();
      return;
    }

    if (MugTargets.onItemMarket()) {
      if (MugTargets.currentItemId()) {
        this.renderBuyMug();
      } else {
        this.content.appendChild(
          this.placeholder(
            "Buy & mug",
            "Open an item to load its sellers, then check which ones are worth buying from and mugging.",
          ),
        );
      }
      return;
    }

    this.content.appendChild(
      this.placeholder("Mug targets", "Open the Bazaar Directory or an Item Market item to find muggable sellers."),
    );
  }

  placeholder(title, text) {
    const wrap = document.createElement("div");
    wrap.className = "tm-mh-placeholder";
    wrap.innerHTML =
      HELPER_ICON +
      `<p class="tm-mh-placeholder-title">${title}</p>` +
      `<p class="tm-mh-placeholder-text">${text}</p>`;
    return wrap;
  }

  renderTargets() {
    const bar = document.createElement("div");
    bar.className = "tm-mh-bar";

    this.scanBtn = document.createElement("button");
    this.scanBtn.type = "button";
    this.scanBtn.className = "tm-mh-scan";
    const hasLast = !!MugTargets.lastResult()?.scanned;
    this.scanBtn.textContent = hasLast ? "Rescan" : "Scan bazaar targets";
    this.scanBtn.onclick = () => this.runScan(hasLast);
    bar.appendChild(this.scanBtn);
    this.content.appendChild(bar);

    this.targetsEl = document.createElement("div");
    this.targetsEl.className = "tm-mh-targets";
    this.content.appendChild(this.targetsEl);

    const last = MugTargets.lastResult();
    if (last?.scanned) {
      this.renderResults(last);
    } else {
      this.showTargetsMessage("Scan the page to find sellers you can mug right now.");
    }
  }

  renderBuyMug() {
    const itemId = MugTargets.currentItemId();

    const form = document.createElement("div");
    form.className = "tm-mh-buymug";

    const itemName = document.querySelector('.sellerRow___PaRgK img[alt]')?.getAttribute("alt") || "";
    const heading = document.createElement("div");
    heading.className = "tm-mh-item";
    heading.textContent = itemName ? `${itemName} (${itemId})` : `Item ${itemId}`;
    form.appendChild(heading);

    const priceField = document.createElement("label");
    priceField.className = "tm-mh-field";
    const priceLabel = document.createElement("span");
    priceLabel.className = "tm-mh-field-label";
    priceLabel.textContent = "Item market value";
    priceField.appendChild(priceLabel);

    const priceRow = document.createElement("div");
    priceRow.className = "tm-mh-field-row";
    this.priceInput = document.createElement("input");
    this.priceInput.type = "text";
    this.priceInput.className = "tm-mh-input";
    this.priceInput.placeholder = "e.g. 13.4m";
    const storedPrice = MugTargets.marketPrice(itemId);
    if (storedPrice) this.priceInput.value = formatMoney(storedPrice);
    this.priceInput.addEventListener("input", () => {
      const value = parseMoney(this.priceInput.value);
      if (Number.isFinite(value) && value > 0) MugTargets.setMarketPrice(itemId, value);
    });

    this.fetchPriceBtn = document.createElement("button");
    this.fetchPriceBtn.type = "button";
    this.fetchPriceBtn.className = "tm-mh-fetch";
    this.fetchPriceBtn.textContent = "Fetch";
    this.fetchPriceBtn.onclick = () => this.fetchPrice(itemId);

    priceRow.append(this.priceInput, this.fetchPriceBtn);
    priceField.appendChild(priceRow);

    const budgetField = document.createElement("label");
    budgetField.className = "tm-mh-field";
    const budgetLabel = document.createElement("span");
    budgetLabel.className = "tm-mh-field-label";
    budgetLabel.textContent = "Buy budget";
    budgetField.appendChild(budgetLabel);

    this.budgetInput = document.createElement("input");
    this.budgetInput.type = "text";
    this.budgetInput.className = "tm-mh-input";
    this.budgetInput.placeholder = "e.g. 500m";
    const budget = MugTargets.buyBudget();
    if (budget) this.budgetInput.value = formatMoney(budget);
    this.budgetInput.addEventListener("input", () => {
      const value = parseMoney(this.budgetInput.value);
      MugTargets.setBuyBudget(Number.isFinite(value) ? value : 0);
    });
    budgetField.appendChild(this.budgetInput);

    this.scanBtn = document.createElement("button");
    this.scanBtn.type = "button";
    this.scanBtn.className = "tm-mh-scan";
    this.scanBtn.textContent = "Check targets";
    this.scanBtn.onclick = () => this.runBuyMug();

    form.append(priceField, budgetField, this.scanBtn);
    this.content.appendChild(form);

    this.targetsEl = document.createElement("div");
    this.targetsEl.className = "tm-mh-targets";
    this.content.appendChild(this.targetsEl);

    this.showTargetsMessage("Set the market value and your budget, then check for targets.");
  }

  async fetchPrice(itemId) {
    this.fetchPriceBtn.disabled = true;
    const label = this.fetchPriceBtn.textContent;
    this.fetchPriceBtn.textContent = "...";

    // Trash the stored value up front so a failed fetch can't leave stale data behind.
    MugTargets.clearMarketPrice(itemId);
    this.priceInput.value = "";

    try {
      const value = await MugTargets.fetchMarketValue(itemId);
      MugTargets.setMarketPrice(itemId, value);
      this.priceInput.value = formatMoney(value);
      showToast(`Fetched Torn's market value: ${formatMoney(value)}`);
      // Any listed targets were computed against the old value.
      if (this.targetsEl?.querySelector(".tm-mh-target, .tm-mh-summary")) {
        this.showTargetsMessage("Market value updated. Check targets again.");
      }
    } catch (err) {
      this.showTargetsMessage(err.message || "Could not fetch the market value.");
    } finally {
      this.fetchPriceBtn.disabled = false;
      this.fetchPriceBtn.textContent = label;
    }
  }

  async runBuyMug(force = false) {
    let marketValue = parseMoney(this.priceInput.value);
    const budget = parseMoney(this.budgetInput.value);

    if (!Number.isFinite(budget) || budget <= 0) {
      this.showTargetsMessage("Set your buy budget first.");
      return;
    }

    // An empty market value is no reason to bother the user — fetch it and go.
    if (!Number.isFinite(marketValue) || marketValue <= 0) {
      const itemId = MugTargets.currentItemId();
      this.scanBtn.disabled = true;
      this.scanBtn.textContent = "Fetching value…";
      try {
        marketValue = await MugTargets.fetchMarketValue(itemId);
        MugTargets.setMarketPrice(itemId, marketValue);
        this.priceInput.value = formatMoney(marketValue);
      } catch (err) {
        this.showTargetsMessage(err.message || "Could not fetch the market value.");
        return;
      } finally {
        this.scanBtn.disabled = false;
        this.scanBtn.textContent = "Check targets";
      }
    }

    const sellers = MugTargets.collectSellers();
    if (!sellers.length) {
      this.showTargetsMessage("No named sellers found on this page.");
      return;
    }

    const mugRate = mugRateFromSettings();
    const scannedAt = Date.now();

    this.scanBtn.disabled = true;
    this.scanBtn.textContent = "Scanning…";

    this.targetsEl.innerHTML = "";
    const bar = document.createElement("div");
    bar.className = "tm-mh-progress";
    const fill = document.createElement("div");
    fill.className = "tm-mh-progress-fill";
    bar.appendChild(fill);
    const progressLabel = document.createElement("p");
    progressLabel.className = "tm-mh-progress-label";
    progressLabel.textContent = `Checking 0 / ${sellers.length}...`;
    const list = document.createElement("div");
    list.className = "tm-mh-list";
    this.targetsEl.append(bar, progressLabel, list);

    let found = 0;
    try {
      await MugTargets.scanSellers(sellers, {
        marketValue,
        budget,
        mugRate,
        force,
        onProgress: (done, total) => {
          fill.style.width = `${Math.round((done / total) * 100)}%`;
          progressLabel.textContent = `Checking ${done} / ${total}...`;
        },
        onTarget: (target) => {
          found += 1;
          this.insertByProfit(list, this.targetRow(target), target.profit);
        },
      });

      bar.remove();
      progressLabel.remove();
      this.targetsEl.insertBefore(
        this.makeSummary((count) => `${count} profitable of ${sellers.length} sellers, ${ago(scannedAt)}`, found),
        list,
      );
      if (!found) {
        list.appendChild(message("No profitable targets here. Try a bigger budget or a different item."));
      }
    } catch (err) {
      this.showTargetsMessage(err.message || "Could not check targets.");
    } finally {
      // Like the bazaar Rescan: later runs bypass the profile cache so
      // hospital timers and cash statuses are checked fresh.
      this.scanBtn.disabled = false;
      this.scanBtn.onclick = () => this.runBuyMug(true);
      this.scanBtn.textContent = "Recheck targets";
    }
  }

  async runScan(force) {
    const ids = MugTargets.collectUserIds();
    if (!ids.length) {
      this.showTargetsMessage("No bazaar users found on this page.");
      return;
    }

    this.scanBtn.disabled = true;
    this.scanBtn.textContent = "Scanning…";

    this.targetsEl.innerHTML = "";
    const bar = document.createElement("div");
    bar.className = "tm-mh-progress";
    const fill = document.createElement("div");
    fill.className = "tm-mh-progress-fill";
    bar.appendChild(fill);

    const label = document.createElement("p");
    label.className = "tm-mh-progress-label";
    label.textContent = `Checking 0 / ${ids.length}...`;

    const list = document.createElement("div");
    list.className = "tm-mh-list";

    this.targetsEl.append(bar, label, list);

    try {
      const result = await MugTargets.scan(ids, {
        force,
        onProgress: (done, total) => {
          fill.style.width = `${Math.round((done / total) * 100)}%`;
          label.textContent = `Checking ${done} / ${total}...`;
        },
        onTarget: (target) => list.appendChild(this.targetRow(target)),
      });

      bar.remove();
      label.remove();
      if (result.truncated) this.targetsEl.insertBefore(this.truncatedNote(result), list);
      this.targetsEl.insertBefore(this.summaryEl(result), this.targetsEl.firstChild);
      if (!result.targets.length) {
        list.appendChild(message("No muggable targets right now. The rest are hospitalized or in clothing stores."));
      }
    } catch (err) {
      this.showTargetsMessage(err.message || "Could not scan targets.");
    } finally {
      this.scanBtn.disabled = false;
      this.scanBtn.onclick = () => this.runScan(true);
      this.scanBtn.textContent = "Rescan";
    }
  }

  renderResults(result) {
    this.targetsEl.innerHTML = "";
    this.targetsEl.appendChild(this.summaryEl(result));
    if (result.truncated) this.targetsEl.appendChild(this.truncatedNote(result));

    if (!result.targets.length) {
      this.targetsEl.appendChild(
        message("No muggable targets right now. The rest are hospitalized or in clothing stores."),
      );
      return;
    }

    const list = document.createElement("div");
    list.className = "tm-mh-list";
    for (const target of result.targets) list.appendChild(this.targetRow(target));
    this.targetsEl.appendChild(list);
  }

  targetRow(target) {
    const item = document.createElement("div");
    item.className = "tm-mh-target";

    const info = document.createElement("div");
    info.className = "tm-mh-target-info";

    if (target.profit != null) {
      const top = document.createElement("div");
      top.className = "tm-mh-target-top";

      const name = document.createElement("span");
      name.className = "tm-mh-target-name";
      name.textContent = target.name;

      const profit = document.createElement("span");
      profit.className = "tm-mh-target-profit";
      profit.title = "Estimated net profit: mug + resale at market value − what you pay";
      profit.textContent = `est profit +${formatMoney(target.profit)}`;

      top.append(name, profit);
      info.appendChild(top);

      const sub = document.createElement("span");
      sub.className = "tm-mh-target-sub";
      sub.title = "The mug estimate only counts the cash you hand the seller — anything they already hold is extra.";
      sub.textContent = `Buy ${target.qty} at ${formatMoney(target.price)} · est mug ${formatMoney(target.estMug)}`;
      info.appendChild(sub);

      const attack = document.createElement("a");
      attack.className = "tm-mh-target-link";
      attack.href = `https://www.torn.com/loader.php?sid=attack&user2ID=${target.id}`;
      attack.target = "_blank";
      attack.rel = "noopener";
      attack.textContent = "Attack";
      info.appendChild(attack);
    } else {
      const name = document.createElement("span");
      name.className = "tm-mh-target-name";
      name.textContent = target.name;
      info.appendChild(name);

      const link = document.createElement("a");
      link.className = "tm-mh-target-link";
      link.href = `https://www.torn.com/bazaar.php?userId=${target.id}#/`;
      link.target = "_blank";
      link.rel = "noopener";
      link.textContent = "Open bazaar";
      info.appendChild(link);
    }

    item.appendChild(info);

    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "tm-mh-target-remove";
    remove.title = "Remove from this list";
    remove.textContent = "×";
    remove.onclick = () => {
      this.highlightSeller(target.id, false);
      item.remove();
      this.updateSummary();
    };
    item.appendChild(remove);

    item.addEventListener("mouseenter", () => this.highlightSeller(target.id, true));
    item.addEventListener("mouseleave", () => this.highlightSeller(target.id, false));

    return item;
  }

  // Targets stream in as the scan walks the page, so place each row where it
  // belongs instead of appending — the list stays sorted by profit throughout.
  insertByProfit(list, row, profit) {
    row.dataset.profit = profit;
    for (const existing of list.children) {
      if (Number(existing.dataset.profit) < profit) {
        list.insertBefore(row, existing);
        return;
      }
    }
    list.appendChild(row);
  }

  highlightSeller(id, on) {
    const row = this.findSellerRow(id);
    row?.classList.toggle("tm-mh-seller-highlight", on);
  }

  findSellerRow(id) {
    const target = String(id);
    for (const anchor of document.querySelectorAll('a[href*="userId="], a[href*="XID="]')) {
      const match = /(?:userId|XID)=(\d+)/.exec(anchor.getAttribute("href") || "");
      if (match && match[1] === target) return anchor.closest("li") || anchor;
    }
    return null;
  }

  clearHighlights() {
    for (const el of document.querySelectorAll(".tm-mh-seller-highlight")) {
      el.classList.remove("tm-mh-seller-highlight");
    }
  }

  summaryEl(result) {
    return this.makeSummary(
      (count) => `${count} muggable of ${result.scanned} checked, ${ago(result.at)}`,
      result.targets.length,
    );
  }

  makeSummary(template, initialCount) {
    this.summaryTemplate = template;
    const summary = document.createElement("p");
    summary.className = "tm-mh-summary";
    summary.textContent = template(initialCount);
    this.summaryElement = summary;
    return summary;
  }

  updateSummary() {
    if (!this.summaryElement || !this.summaryTemplate) return;

    const count = this.targetsEl.querySelectorAll(".tm-mh-target").length;
    this.summaryElement.textContent = this.summaryTemplate(count);

    if (count === 0 && !this.targetsEl.querySelector(".tm-mh-msg")) {
      const list = this.targetsEl.querySelector(".tm-mh-list") || this.targetsEl;
      list.appendChild(message("Nothing left in the list. Rescan to check again."));
    }
  }

  truncatedNote(result) {
    const note = document.createElement("p");
    note.className = "tm-mh-note";
    note.textContent = `Only the first ${result.scanned} of ${result.found} sellers were checked.`;
    return note;
  }

  showTargetsMessage(text) {
    this.targetsEl.innerHTML = "";
    this.targetsEl.appendChild(message(text));
  }

  applyPosition() {
    const saved = this.savedPosition();
    if (saved && typeof saved.left === "number" && typeof saved.top === "number") {
      this.moveTo(saved.left, saved.top);
      return;
    }
    this.element.style.right = "18px";
    this.element.style.bottom = "90px";
  }

  makeDraggable(header) {
    let start = null;
    let dragging = false;

    header.addEventListener("pointerdown", (e) => {
      if (e.target.closest(".tm-mh-action")) return;
      const rect = this.element.getBoundingClientRect();
      start = { x: e.clientX, y: e.clientY, left: rect.left, top: rect.top };
      dragging = false;
      header.setPointerCapture(e.pointerId);
    });

    header.addEventListener("pointermove", (e) => {
      if (!start) return;
      const dx = e.clientX - start.x;
      const dy = e.clientY - start.y;
      if (!dragging && Math.hypot(dx, dy) < DRAG_THRESHOLD_PX) return;
      dragging = true;
      this.moveTo(start.left + dx, start.top + dy);
    });

    const finish = () => {
      if (!start) return;
      if (dragging) this.savePosition();
      start = null;
    };

    header.addEventListener("pointerup", finish);
    header.addEventListener("pointercancel", () => {
      start = null;
    });
  }

  moveTo(left, top) {
    const rect = this.element.getBoundingClientRect();
    const width = rect.width || 300;
    const height = rect.height || 340;
    this.element.style.left = `${Math.min(Math.max(left, 4), window.innerWidth - width - 4)}px`;
    this.element.style.top = `${Math.min(Math.max(top, 4), window.innerHeight - height - 4)}px`;
    this.element.style.right = "auto";
    this.element.style.bottom = "auto";
  }

  clampPosition() {
    const rect = this.element.getBoundingClientRect();
    if (rect.left < 0 || rect.top < 0 || rect.right > window.innerWidth || rect.bottom > window.innerHeight) {
      this.moveTo(rect.left, rect.top);
    }
  }

  savePosition() {
    const rect = this.element.getBoundingClientRect();
    try {
      localStorage.setItem(POS_KEY, JSON.stringify({ left: Math.round(rect.left), top: Math.round(rect.top) }));
    } catch {
      return;
    }
  }

  savedPosition() {
    try {
      const raw = localStorage.getItem(POS_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  applySize() {
    const saved = this.savedSize();
    if (saved && saved.w && saved.h) {
      this.element.style.width = `${saved.w}px`;
      this.element.style.height = `${saved.h}px`;
    }
  }

  addResizeHandle() {
    const handle = document.createElement("div");
    handle.className = "tm-mh-resize";
    this.element.appendChild(handle);

    let start = null;

    handle.addEventListener("pointerdown", (e) => {
      e.preventDefault();
      const rect = this.element.getBoundingClientRect();
      this.moveTo(rect.left, rect.top);
      start = { x: e.clientX, y: e.clientY, w: rect.width, h: rect.height, left: rect.left, top: rect.top };
      handle.setPointerCapture(e.pointerId);
      this.element.style.zIndex = ++zCounter;
    });

    handle.addEventListener("pointermove", (e) => {
      if (!start) return;
      const maxW = window.innerWidth - start.left - 8;
      const maxH = window.innerHeight - start.top - 8;
      const width = Math.min(Math.max(start.w + (e.clientX - start.x), MIN_WIDTH), maxW);
      const height = Math.min(Math.max(start.h + (e.clientY - start.y), MIN_HEIGHT), maxH);
      this.element.style.width = `${width}px`;
      this.element.style.height = `${height}px`;
    });

    const finish = () => {
      if (!start) return;
      start = null;
      this.saveSize();
    };

    handle.addEventListener("pointerup", finish);
    handle.addEventListener("pointercancel", finish);
  }

  saveSize() {
    try {
      localStorage.setItem(
        SIZE_KEY,
        JSON.stringify({ w: Math.round(this.element.offsetWidth), h: Math.round(this.element.offsetHeight) }),
      );
    } catch {
      return;
    }
  }

  savedSize() {
    try {
      const raw = localStorage.getItem(SIZE_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }
}

function message(text) {
  const el = document.createElement("p");
  el.className = "tm-mh-msg";
  el.textContent = text;
  return el;
}

function ago(ts) {
  const mins = Math.floor((Date.now() - ts) / 60000);
  if (mins <= 0) return "just now";
  if (mins === 1) return "1 minute ago";
  if (mins < 60) return `${mins} minutes ago`;
  const hours = Math.floor(mins / 60);
  return hours === 1 ? "1 hour ago" : `${hours} hours ago`;
}

function mugRateFromSettings() {
  let merits = 0;
  let plunder = 0;
  try {
    const raw = localStorage.getItem("tm_mug_calc");
    if (raw) {
      const calc = JSON.parse(raw);
      merits = Math.min(10, Math.max(0, Math.floor(Number(calc.merits)) || 0));
      plunder = Math.max(0, Number(calc.plunder) || 0);
    }
  } catch {
    merits = 0;
  }
  const modifier = 1 + (merits * 5 + plunder) / 100;
  return 0.05 * modifier;
}
