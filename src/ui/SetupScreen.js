import { Dom } from "../core/Dom.js";
import { COMPANY_TYPES } from "../core/CompanyTypes.js";
import { Settings } from "../core/Settings.js";

export class SetupScreen {
  constructor(overlay) {
    this.overlay = overlay;
  }

  subtitle() {
    return "setup";
  }

  render(container) {
    const settings = Settings.get();
    const selected = new Set(settings.typeIds);

    const typeCard = Dom.el("div", "rc-card");
    typeCard.appendChild(Dom.el("div", "rc-label", "Company types to track"));
    const chips = Dom.el("div", "rc-chips");
    for (const type of COMPANY_TYPES) {
      const chip = Dom.el("button", "rc-chip", type.name);
      if (selected.has(type.id)) chip.classList.add("rc-chip--on");
      chip.addEventListener("click", () => {
        if (selected.has(type.id)) {
          selected.delete(type.id);
          chip.classList.remove("rc-chip--on");
        } else {
          selected.add(type.id);
          chip.classList.add("rc-chip--on");
        }
      });
      chips.appendChild(chip);
    }
    typeCard.appendChild(chips);
    container.appendChild(typeCard);

    const rangeCard = Dom.el("div", "rc-card");
    const row = Dom.el("div", "rc-row");

    const starMin = numberField("Min stars", settings.starMin, 0, 10);
    const starMax = numberField("Max stars", settings.starMax, 0, 10);
    const floor = numberField("Working stats floor", settings.floor, 0);
    const inactive = numberField("Ignore inactive over (days)", settings.inactiveDays, 1);

    row.append(starMin.wrap, starMax.wrap, floor.wrap, inactive.wrap);
    rangeCard.appendChild(row);
    rangeCard.appendChild(
      Dom.el(
        "div",
        "rc-hint",
        "The floor decides how deep the working stats sweep goes. 400,000 stops around rank 50,000 (≈500 calls, ~7 min per key). 100,000 sweeps several times deeper and can take an hour on a single key."
      )
    );
    container.appendChild(rangeCard);

    const save = Dom.el("button", "rc-btn", "Save");
    const note = Dom.el("span", "rc-dim", " Changes apply after the next roster update.");
    const footer = Dom.el("div", "rc-footer-row");
    save.addEventListener("click", () => {
      Settings.set({
        typeIds: [...selected].sort((a, b) => a - b),
        starMin: clamp(starMin.input.value, 0, 10),
        starMax: clamp(starMax.input.value, 0, 10),
        floor: Math.max(0, Number(floor.input.value) || 0),
        inactiveDays: Math.max(1, Number(inactive.input.value) || 30),
      });
      this.overlay.show("overview");
    });
    footer.append(save, note);
    container.appendChild(footer);
  }
}

function numberField(labelText, value, min, max) {
  const wrap = Dom.el("div", "rc-field");
  const label = Dom.el("div", "rc-label", labelText);
  const input = Dom.el("input", "rc-input");
  input.type = "number";
  input.value = value;
  if (min !== undefined) input.min = min;
  if (max !== undefined) input.max = max;
  wrap.append(label, input);
  return { wrap, input };
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, Number(value) || min));
}
