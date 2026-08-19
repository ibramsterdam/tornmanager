import { Store } from "./Store.js";

const DEFAULTS = {
  typeIds: [10],
  starMin: 8,
  starMax: 10,
  floor: 400_000,
  inactiveDays: 30,
};

export const Settings = {
  get() {
    return { ...DEFAULTS, ...Store.get("settings", {}) };
  },

  set(patch) {
    Store.set("settings", { ...this.get(), ...patch });
  },
};
