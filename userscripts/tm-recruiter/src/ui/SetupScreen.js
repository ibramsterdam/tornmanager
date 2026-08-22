import { Dom } from "@shared/core/Dom.js";
import { COMPANY_TYPES } from "../core/CompanyTypes.js";
import { Settings, STAR_RANGE } from "../core/Settings.js";

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
        Settings.set({ typeIds: [...selected].sort((a, b) => a - b) });
      });
      chips.appendChild(chip);
    }
    typeCard.appendChild(chips);
    container.appendChild(typeCard);

    const rangeCard = Dom.el("div", "rc-card");
    const row = Dom.el("div", "rc-row");

    row.appendChild(
      this.stepper("Min stars", settings.starMin, STAR_RANGE.min, settings.starMax, (value) => {
        Settings.set({ starMin: value });
      })
    );
    row.appendChild(
      this.stepper("Max stars", settings.starMax, settings.starMin, STAR_RANGE.max, (value) => {
        Settings.set({ starMax: value });
      })
    );
    rangeCard.appendChild(row);
    rangeCard.appendChild(
      Dom.el(
        "div",
        "rc-hint",
        "Everything saves automatically. Company rosters and working stats are fetched and refreshed on the TornManager server daily, so changes apply the next time the overview loads."
      )
    );
    container.appendChild(rangeCard);
  }

  stepper(labelText, value, min, max, onChange) {
    const wrap = Dom.el("div", "rc-field");
    wrap.appendChild(Dom.el("div", "rc-label", labelText));

    const control = Dom.el("div", "rc-stepper");
    const minus = Dom.el("button", "rc-stepper-btn", "−");
    const display = Dom.el("span", "rc-stepper-value", String(value));
    const plus = Dom.el("button", "rc-stepper-btn", "+");

    const apply = (next) => {
      onChange(next);
      this.overlay.refresh();
    };
    minus.addEventListener("click", () => {
      if (value > min) apply(value - 1);
    });
    plus.addEventListener("click", () => {
      if (value < max) apply(value + 1);
    });
    minus.disabled = value <= min;
    plus.disabled = value >= max;

    control.append(minus, display, plus);
    wrap.appendChild(control);
    return wrap;
  }
}
