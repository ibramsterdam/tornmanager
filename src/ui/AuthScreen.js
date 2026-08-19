import bannerSvg from "../../assets/recruit-banner.svg?raw";
import { Dom } from "../core/Dom.js";

const DISCLOSURE = [
  ["Data Storage", "Persistent until you remove your key"],
  ["Data Sharing", "Nobody (your data is private)"],
  ["Purpose of Use", "Signing in and verifying your TornManager subscription"],
  ["Key Storage & Sharing", "Stored in the TornManager database, used only for verification"],
  ["Key Access Level", "Public access (required)"],
];

export class AuthScreen {
  constructor(auth, overlay, keys, api) {
    this.auth = auth;
    this.overlay = overlay;
    this.keys = keys;
    this.api = api;
  }

  subtitle() {
    return "sign in";
  }

  render(container) {
    const wrap = Dom.el("div", "rc-auth");

    const banner = Dom.el("div", "rc-auth-banner");
    banner.innerHTML = bannerSvg;
    wrap.appendChild(banner);

    const form = Dom.el("form", "rc-auth-form");
    const row = Dom.el("div", "rc-auth-row");

    const input = Dom.el("input", "rc-auth-input");
    input.type = "text";
    input.placeholder = "Add Public Torn API key";
    input.autocomplete = "off";
    input.spellcheck = false;

    const button = Dom.el("button", "rc-auth-button", "Sign in");
    button.type = "submit";
    button.disabled = true;

    const error = Dom.el("p", "rc-auth-error");

    row.append(input, button);
    form.append(row, error);

    const tos = Dom.el("div", "rc-tos");
    tos.appendChild(Dom.el("p", "rc-tos-heading", "How your key and data are handled"));
    const grid = Dom.el("div", "rc-tos-grid");
    for (const [label, value] of DISCLOSURE) {
      const item = Dom.el("div", "rc-tos-item");
      item.append(Dom.el("span", "rc-tos-label", label), Dom.el("span", "rc-tos-value", value));
      grid.appendChild(item);
    }
    tos.appendChild(grid);

    const agree = Dom.el("label", "rc-tos-agree");
    const checkbox = Dom.el("input");
    checkbox.type = "checkbox";
    checkbox.addEventListener("change", () => {
      button.disabled = !checkbox.checked;
    });
    const agreeText = Dom.el("span");
    agreeText.append("I agree to the ", this.legalLink("Privacy Policy", "rc-privacy"), " and ", this.legalLink("Terms of Service", "rc-terms"), ".");
    agree.append(checkbox, agreeText);
    tos.appendChild(agree);
    form.appendChild(tos);

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      if (!checkbox.checked) return;

      const apiKey = input.value.trim();
      if (!apiKey) {
        error.textContent = "Please enter an API key.";
        return;
      }

      button.disabled = true;
      button.textContent = "Signing in...";
      error.textContent = "";

      try {
        await this.requirePublicAccess(apiKey);
        await this.auth.authenticate(apiKey);
        await this.auth.fetchSubscription().catch(() => null);
        await this.addToPool(apiKey);
        this.overlay.open();
      } catch (err) {
        error.textContent = err.message;
        button.disabled = false;
        button.textContent = "Sign in";
      }
    });

    const hint = Dom.el("p", "rc-auth-hint");
    hint.innerHTML =
      'A key with <strong>Public</strong> access is all this script needs, and it accepts nothing else. ' +
      '<a href="https://www.torn.com/preferences.php#tab=api" target="_blank" rel="noopener">Create one here</a>.';

    wrap.append(form, hint);
    container.appendChild(wrap);
  }

  legalLink(label, anchor) {
    const link = Dom.el("a", null, label);
    link.href = "#";
    link.addEventListener("click", (e) => {
      e.preventDefault();
      this.overlay.openLegal(anchor);
    });
    return link;
  }

  async requirePublicAccess(apiKey) {
    let access;
    try {
      const info = await this.api.call("/key/info", {}, apiKey);
      access = info.info?.access || info.access || {};
    } catch (err) {
      throw new Error(err.message || "Could not validate the key with Torn");
    }
    const type = String(access.type || "");
    if (!/public/i.test(type)) {
      throw new Error(`This key has ${type || "unknown"} access. Recruiter only accepts Public access keys.`);
    }
  }

  async addToPool(apiKey) {
    const user = this.auth.getUser();
    if (!user) return;
    const pool = this.keys.all();
    if (pool.some((k) => k.ownerId === user.torn_id || k.key === apiKey)) return;
    await this.keys.add(apiKey, this.api).catch(() => null);
  }
}
