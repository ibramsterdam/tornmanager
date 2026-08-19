import { Dom } from "../core/Dom.js";
import { COMPANY_TYPES } from "../core/CompanyTypes.js";
import { Settings, STAR_RANGE, INACTIVE_RANGE } from "../core/Settings.js";

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
    row.appendChild(this.floorField(settings.floor));
    row.appendChild(
      this.stepper("Ignore inactive over (days)", settings.inactiveDays, INACTIVE_RANGE.min, INACTIVE_RANGE.max, (value) => {
        Settings.set({ inactiveDays: value });
      })
    );

    rangeCard.appendChild(row);
    rangeCard.appendChild(
      Dom.el(
        "div",
        "rc-hint",
        "Everything saves automatically. The floor decides how deep the working stats sweep goes: 400,000 stops around rank 50,000 (≈500 calls, ~7 min per key), 100,000 sweeps several times deeper and can take an hour on a single key."
      )
    );
    container.appendChild(rangeCard);

    container.appendChild(Dom.el("div", "rc-hint", "Company type and star changes apply after the next roster update."));
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

  floorField(floor) {
    const wrap = Dom.el("div", "rc-field");
    wrap.appendChild(Dom.el("div", "rc-label", "Working stats floor"));

    const input = Dom.el("input", "rc-input");
    input.type = "number";
    input.min = 0;
    input.value = floor;

    const save = () => {
      const value = Math.max(0, Number(input.value) || 0);
      if (value !== Settings.get().floor) {
        Settings.set({ floor: value });
        this.overlay.refresh();
      }
    };
    input.addEventListener("blur", save);
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") input.blur();
    });

    wrap.appendChild(input);
    return wrap;
  }
}
