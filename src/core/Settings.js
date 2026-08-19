import { Store } from "./Store.js";

const DEFAULTS = {
  typeIds: [10],
  starMin: 8,
  starMax: 10,
  floor: 100_000,
  inactiveDays: 7,
};

export const STAR_RANGE = { min: 1, max: 10 };
export const INACTIVE_RANGE = { min: 1, max: 14 };

export const Settings = {
  get() {
    const settings = { ...DEFAULTS, ...Store.get("settings", {}) };
    settings.starMin = clamp(settings.starMin, STAR_RANGE.min, STAR_RANGE.max);
    settings.starMax = clamp(settings.starMax, settings.starMin, STAR_RANGE.max);
    settings.floor = Math.max(0, Number(settings.floor) || DEFAULTS.floor);
    settings.inactiveDays = clamp(settings.inactiveDays, INACTIVE_RANGE.min, INACTIVE_RANGE.max);
    return settings;
  },

  set(patch) {
    Store.set("settings", { ...this.get(), ...patch });
  },
};

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, Number(value) || min));
}
