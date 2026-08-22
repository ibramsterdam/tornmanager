import { Store } from "./Store.js";

const DEFAULTS = {
  typeIds: [10],
  starMin: 8,
  starMax: 10,
};

export const STAR_RANGE = { min: 7, max: 10 };

export const Settings = {
  get() {
    const settings = { ...DEFAULTS, ...Store.get("settings", {}) };
    settings.starMin = clamp(settings.starMin, STAR_RANGE.min, STAR_RANGE.max);
    settings.starMax = clamp(settings.starMax, settings.starMin, STAR_RANGE.max);
    delete settings.floor;
    delete settings.inactiveDays;
    return settings;
  },

  set(patch) {
    Store.set("settings", { ...this.get(), ...patch });
  },
};

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, Number(value) || min));
}
