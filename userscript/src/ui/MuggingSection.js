import { MugKey } from "../core/MugKey.js";
import { TornDirect } from "../core/TornDirect.js";
import { MugLogs, EARLIEST_DATE } from "../core/MugLogs.js";
import { ApiDisclosure, MUG_KEY_DISCLOSURE } from "./ApiDisclosure.js";

const CALC_KEY = "tm_mug_calc";

const CARD_ICON =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="4" width="18" height="16" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/></svg>';

export class MuggingSection {
  constructor(api, mugHelper) {
    this.api = api;
    this.mugHelper = mugHelper;
  }

  render() {
    this.section = document.createElement("div");
    this.section.className = "tm-mugging";

    const title = document.createElement("h2");
    title.className = "tm-mugging-title";
    title.textContent = "Mugging";
    this.section.appendChild(title);

    this.body = document.createElement("div");
    this.section.appendChild(this.body);

    if (MugKey.get()) {
      this.renderDashboard();
    } else {
      this.renderKeyForm();
    }

    return this.section;
  }

  renderKeyForm() {
    this.body.innerHTML = "";

    const card = document.createElement("div");
    card.className = "tm-mugging-connect";

    const sub = document.createElement("p");
    sub.className = "tm-mugging-connect-sub";
    sub.innerHTML =
      "The Mugging tab reads your <strong>attack mug logs</strong>, which Torn only exposes to a Full Access " +
      "key. It calls Torn directly and is stored only in this browser, never sent to TornManager.";
    card.appendChild(sub);

    this.input = document.createElement("input");
    this.input.type = "text";
    this.input.className = "tm-mugging-input";
    this.input.placeholder = "Full Access API key";
    this.input.autocomplete = "off";
    this.input.spellcheck = false;

    this.saveBtn = document.createElement("button");
    this.saveBtn.type = "submit";
    this.saveBtn.className = "tm-mugging-save";
    this.saveBtn.textContent = "Verify & save";
    this.saveBtn.disabled = true;

    this.error = document.createElement("p");
    this.error.className = "tm-mugging-error";

    this.disclosure = new ApiDisclosure(MUG_KEY_DISCLOSURE, (agreed) => {
      this.saveBtn.disabled = !agreed;
    });
    card.appendChild(this.disclosure.render());

    const form = document.createElement("form");
    form.className = "tm-mugging-form";
    form.appendChild(this.input);
    form.appendChild(this.saveBtn);
    form.appendChild(this.error);
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      this.validateAndSave();
    });
    card.appendChild(form);

    this.body.appendChild(card);
  }

  validateAndSave() {
    if (!this.disclosure.isAgreed()) return;

    this.error.textContent = "";

    const key = this.input.value.trim();
    if (!key) {
      this.error.textContent = "Enter your Full Access API key.";
      return;
    }

    this.saveBtn.disabled = true;
    this.saveBtn.textContent = "Verifying…";

    TornDirect.keyInfo(key)
      .then((data) => {
        MugLogs.bumpApiCalls();
        const type = data?.info?.access?.type;
        if (type !== "Full Access") {
          this.error.textContent = `This key is ${type || "not valid"}. A Full Access key is required.`;
          this.resetSaveButton();
          return;
        }
        MugKey.set(key);
        this.renderDashboard();
      })
      .catch((err) => {
        this.error.textContent = err.message || "Could not verify the key.";
        this.resetSaveButton();
      });
  }

  resetSaveButton() {
    this.saveBtn.disabled = false;
    this.saveBtn.textContent = "Verify & save";
  }

  renderDashboard() {
    this.body.innerHTML = "";

    this.helperBtn = document.createElement("button");
    this.helperBtn.type = "button";
    this.helperBtn.className = "tm-mug-helper-toggle";
    this.helperBtn.onclick = () => {
      this.mugHelper?.toggle();
      this.updateHelperBtn();
    };
    this.body.appendChild(this.helperBtn);
    this.updateHelperBtn();

    const today = isoDate(new Date());
    const defaultFrom = maxDate(isoDate(new Date(Date.now() - 30 * 86400000)), EARLIEST_DATE);

    const controls = document.createElement("div");
    controls.className = "tm-mug-controls";

    const from = this.dateField("From", defaultFrom, today);
    this.fromDate = from.input;
    controls.appendChild(from.field);

    const to = this.dateField("To", today, today);
    this.toDate = to.input;
    controls.appendChild(to.field);

    this.fetchBtn = document.createElement("button");
    this.fetchBtn.type = "button";
    this.fetchBtn.className = "tm-mug-fetch";
    this.fetchBtn.textContent = "Fetch";
    this.fetchBtn.onclick = () => this.runFetch();
    controls.appendChild(this.fetchBtn);

    this.body.appendChild(controls);

    this.results = document.createElement("div");
    this.results.className = "tm-mug-results";
    this.body.appendChild(this.results);

    this.renderCalculator();

    const usage = document.createElement("div");
    usage.className = "tm-mug-usage";
    this.usageText = document.createElement("span");
    usage.appendChild(this.usageText);

    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "tm-mug-remove";
    remove.textContent = "Remove key";
    remove.onclick = () => {
      MugKey.clear();
      MugLogs.clear();
      this.renderKeyForm();
    };
    usage.appendChild(remove);
    this.body.appendChild(usage);
    this.updateUsage();

    const stored = MugLogs.stored();
    if (stored && Array.isArray(stored.logs)) {
      this.renderStats(stored);
    } else {
      this.showMessage("Pick a date range and fetch your mug logs.");
    }
  }

  dateField(label, value, max) {
    const field = document.createElement("label");
    field.className = "tm-mug-field";

    const caption = document.createElement("span");
    caption.className = "tm-mug-field-label";
    caption.textContent = label;
    field.appendChild(caption);

    const input = document.createElement("input");
    input.type = "date";
    input.className = "tm-mug-input";
    input.min = EARLIEST_DATE;
    input.max = max;
    input.value = value;
    field.appendChild(input);

    return { field, input };
  }

  async runFetch() {
    const fromValue = this.fromDate.value;
    const toValue = this.toDate.value;

    if (!fromValue || !toValue) {
      this.showMessage("Pick a start and end date.");
      return;
    }
    if (fromValue > toValue) {
      this.showMessage("The start date must be on or before the end date.");
      return;
    }

    const startTs = Math.floor(Date.parse(`${fromValue}T00:00:00Z`) / 1000);
    const nowTs = Math.floor(Date.now() / 1000);
    const endTs = Math.min(Math.floor(Date.parse(`${toValue}T23:59:59Z`) / 1000), nowTs);

    this.fetchBtn.disabled = true;
    this.fetchBtn.textContent = "Fetching…";
    this.showMessage("Fetching mug logs…");

    try {
      const logs = await MugLogs.fetch(startTs, endTs, (count) => {
        this.showMessage(`Fetching mug logs… ${formatNumber(count)} so far`);
        this.updateUsage();
      });
      const result = { startDate: fromValue, endDate: toValue, fetchedAt: Date.now(), logs };
      MugLogs.store(result);
      this.renderStats(result);
    } catch (err) {
      this.showMessage(err.message || "Could not fetch your mug logs.");
    } finally {
      this.fetchBtn.disabled = false;
      this.fetchBtn.textContent = "Fetch";
      this.updateUsage();
    }
  }

  renderStats(result) {
    const logs = Array.isArray(result.logs) ? result.logs : [];
    const stats = MugLogs.stats(logs);

    this.results.innerHTML = "";

    const caption = document.createElement("p");
    caption.className = "tm-mug-caption";
    caption.textContent = `${result.startDate} to ${result.endDate}`;
    this.results.appendChild(caption);

    if (!stats.mugs) {
      const empty = document.createElement("p");
      empty.className = "tm-mug-message";
      empty.textContent = "No mugs found in this range.";
      this.results.appendChild(empty);
      return;
    }

    const grid = document.createElement("div");
    grid.className = "tm-mug-stats";
    grid.appendChild(statCard("Mugs", formatNumber(stats.mugs)));
    grid.appendChild(statCard("Energy spent", formatNumber(stats.energy)));
    grid.appendChild(statCard("Money mugged", "$" + formatNumber(stats.money)));

    const largest = statCard("Largest mug", "$" + formatNumber(stats.largest.money));
    if (stats.largest.attackId) {
      const link = document.createElement("a");
      link.className = "tm-mug-viewlog";
      link.href = `https://www.torn.com/page.php?sid=attackLog&ID=${stats.largest.attackId}`;
      link.target = "_blank";
      link.rel = "noopener";
      link.textContent = "View attack log";
      largest.appendChild(link);
    }
    grid.appendChild(largest);

    this.results.appendChild(grid);
  }

  showMessage(text) {
    this.results.innerHTML = "";
    const msg = document.createElement("p");
    msg.className = "tm-mug-message";
    msg.textContent = text;
    this.results.appendChild(msg);
  }

  updateUsage() {
    this.usageText.textContent = `API calls used on this page: ${formatNumber(MugLogs.apiCalls())}`;
  }

  updateHelperBtn() {
    if (!this.helperBtn) return;
    const open = this.mugHelper?.isOpen();
    this.helperBtn.innerHTML = `${CARD_ICON}<span>${open ? "Close mug helper" : "Open mug helper"}</span>`;
    this.helperBtn.classList.toggle("tm-mug-helper-toggle--on", !!open);
  }

  renderCalculator() {
    const wrap = document.createElement("div");
    wrap.className = "tm-mugcalc";

    const heading = document.createElement("h3");
    heading.className = "tm-mugcalc-heading";
    heading.textContent = "Mug calculator";
    wrap.appendChild(heading);

    const intro = document.createElement("p");
    intro.className = "tm-mugcalc-intro";
    intro.textContent =
      "Set your loot bonuses and a target amount to see how much cash a victim must be holding.";
    wrap.appendChild(intro);

    const saved = this.loadCalc();

    const inputs = document.createElement("div");
    inputs.className = "tm-mugcalc-inputs";

    const update = () => this.updateCalc();

    this.meritsStepper = stepper("Masterful Looting merits", clamp(Math.floor(Number(saved.merits)) || 0, 0, 10), {
      next: (v) => Math.min(10, v + 1),
      prev: (v) => Math.max(0, v - 1),
      isMin: (v) => v <= 0,
      isMax: (v) => v >= 10,
      format: (v) => String(v),
      onChange: update,
    });

    this.plunderStepper = stepper("Plunder weapon bonus", snapPlunder(saved.plunder), {
      next: (v) => (v === 0 ? 20 : Math.min(49, v + 1)),
      prev: (v) => (v <= 20 ? 0 : v - 1),
      isMin: (v) => v <= 0,
      isMax: (v) => v >= 49,
      format: (v) => `${v}%`,
      onChange: update,
    });

    this.targetInput = calcField("Mug amount you want", "text", saved.target, {
      placeholder: "e.g. 10m",
      inputMode: "decimal",
    });
    this.targetInput.field.classList.add("tm-mugcalc-wide");
    this.targetInput.input.addEventListener("input", update);

    inputs.appendChild(this.meritsStepper.field);
    inputs.appendChild(this.plunderStepper.field);
    inputs.appendChild(this.targetInput.field);
    wrap.appendChild(inputs);

    this.calcOutput = document.createElement("div");
    this.calcOutput.className = "tm-mugcalc-output";
    wrap.appendChild(this.calcOutput);

    this.body.appendChild(wrap);
    this.updateCalc();
  }

  updateCalc() {
    const merits = this.meritsStepper.value;
    const plunder = this.plunderStepper.value;
    const target = parseMoney(this.targetInput.input.value);

    this.saveCalc({ merits, plunder, target: this.targetInput.input.value.trim() });

    const modifier = 1 + (merits * 5 + plunder) / 100;
    const minRate = 0.05 * modifier;
    const maxRate = 0.1 * modifier;

    this.calcOutput.innerHTML = "";

    const rate = document.createElement("p");
    rate.className = "tm-mugcalc-rate";
    rate.innerHTML =
      `Your mug rate: <strong>${(minRate * 100).toFixed(2)}% to ${(maxRate * 100).toFixed(2)}%</strong> ` +
      "of a victim's cash on hand.";
    this.calcOutput.appendChild(rate);

    if (!Number.isFinite(target) || target <= 0) {
      const hint = document.createElement("p");
      hint.className = "tm-mugcalc-hint";
      hint.textContent = "Enter a mug amount to see how much the target must be holding.";
      this.calcOutput.appendChild(hint);
      return;
    }

    const caption = document.createElement("p");
    caption.className = "tm-mug-caption";
    caption.textContent = `Cash the target must hold to mug ${money(target)}`;
    this.calcOutput.appendChild(caption);

    const rows = [
      { label: "Normal target", typical: target / minRate, best: target / maxRate },
      { label: "7* Clothing Store target", typical: (target / minRate) * 4, best: (target / maxRate) * 4 },
    ];

    const table = document.createElement("table");
    table.className = "tm-mugcalc-table";
    table.innerHTML = "<thead><tr><th>Target</th><th>Typical roll</th><th>Best roll</th></tr></thead>";
    const tbody = document.createElement("tbody");
    for (const row of rows) {
      const tr = document.createElement("tr");
      tr.innerHTML = `<td>${row.label}</td><td>${money(row.typical)}</td><td>${money(row.best)}</td>`;
      tbody.appendChild(tr);
    }
    table.appendChild(tbody);
    this.calcOutput.appendChild(table);

    const note = document.createElement("p");
    note.className = "tm-mugcalc-note";
    note.textContent =
      "Torn favours the low end of the range, so the typical column is what you will usually need. " +
      "A best roll near the top of your range is rare. A 7* Clothing Store cuts your mug by 75%.";
    this.calcOutput.appendChild(note);
  }

  loadCalc() {
    const defaults = { merits: 0, plunder: 0, target: "10m" };
    try {
      const raw = localStorage.getItem(CALC_KEY);
      return raw ? { ...defaults, ...JSON.parse(raw) } : defaults;
    } catch {
      return defaults;
    }
  }

  saveCalc(state) {
    try {
      localStorage.setItem(CALC_KEY, JSON.stringify(state));
    } catch {
      return;
    }
  }

  destroy() {}
}

const MINUS_ICON = '<svg viewBox="0 0 24 24" fill="none"><line x1="5" y1="12" x2="19" y2="12"/></svg>';
const PLUS_ICON =
  '<svg viewBox="0 0 24 24" fill="none"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>';

function stepper(label, initial, opts) {
  let value = initial;

  const field = document.createElement("div");
  field.className = "tm-mug-field";

  const caption = document.createElement("span");
  caption.className = "tm-mug-field-label";
  caption.textContent = label;
  field.appendChild(caption);

  const row = document.createElement("div");
  row.className = "tm-mug-stepper";

  const minus = document.createElement("button");
  minus.type = "button";
  minus.className = "tm-mug-step";
  minus.innerHTML = MINUS_ICON;
  minus.setAttribute("aria-label", `Decrease ${label}`);

  const display = document.createElement("span");
  display.className = "tm-mug-step-value";

  const plus = document.createElement("button");
  plus.type = "button";
  plus.className = "tm-mug-step";
  plus.innerHTML = PLUS_ICON;
  plus.setAttribute("aria-label", `Increase ${label}`);

  const paint = () => {
    display.textContent = opts.format(value);
    minus.disabled = opts.isMin(value);
    plus.disabled = opts.isMax(value);
  };

  minus.onclick = () => {
    value = opts.prev(value);
    paint();
    opts.onChange();
  };
  plus.onclick = () => {
    value = opts.next(value);
    paint();
    opts.onChange();
  };

  row.appendChild(minus);
  row.appendChild(display);
  row.appendChild(plus);
  field.appendChild(row);
  paint();

  return {
    field,
    get value() {
      return value;
    },
  };
}

function snapPlunder(raw) {
  const n = Math.floor(Number(raw)) || 0;
  if (n <= 0) return 0;
  if (n < 20) return 20;
  return Math.min(49, n);
}

function calcField(label, type, value, attrs) {
  const field = document.createElement("label");
  field.className = "tm-mug-field";

  const caption = document.createElement("span");
  caption.className = "tm-mug-field-label";
  caption.textContent = label;
  field.appendChild(caption);

  const input = document.createElement("input");
  input.type = type;
  input.className = "tm-mug-input";
  input.value = value;
  if (attrs) Object.assign(input, attrs);
  field.appendChild(input);

  return { field, input };
}

function parseMoney(str) {
  const s = String(str || "")
    .trim()
    .toLowerCase()
    .replace(/[$,\s]/g, "");
  const match = /^([0-9]*\.?[0-9]+)([kmb])?$/.exec(s);
  if (!match) return NaN;

  let n = parseFloat(match[1]);
  if (match[2] === "k") n *= 1e3;
  else if (match[2] === "m") n *= 1e6;
  else if (match[2] === "b") n *= 1e9;
  return n;
}

function money(n) {
  if (!Number.isFinite(n) || n <= 0) return "$0";
  if (n >= 1e9) return "$" + trimZeros(n / 1e9) + "b";
  if (n >= 1e6) return "$" + trimZeros(n / 1e6) + "m";
  if (n >= 1e3) return "$" + trimZeros(n / 1e3) + "k";
  return "$" + Math.round(n).toLocaleString("en-US");
}

function trimZeros(x) {
  return x.toFixed(2).replace(/\.?0+$/, "");
}

function clamp(n, lo, hi) {
  return Math.min(hi, Math.max(lo, n));
}

function statCard(label, value) {
  const card = document.createElement("div");
  card.className = "tm-mug-stat";

  const val = document.createElement("span");
  val.className = "tm-mug-stat-value";
  val.textContent = value;
  card.appendChild(val);

  const lbl = document.createElement("span");
  lbl.className = "tm-mug-stat-label";
  lbl.textContent = label;
  card.appendChild(lbl);

  return card;
}

function formatNumber(n) {
  return n.toLocaleString("en-US");
}

function isoDate(date) {
  return date.toISOString().slice(0, 10);
}

function maxDate(a, b) {
  return a > b ? a : b;
}
