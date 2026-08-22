import bannerSvg from "../../assets/recruit-banner.svg?raw";
import { Dom } from "@shared/core/Dom.js";

const DISCLOSURE = [
  ["Data Storage", "Persistent until you remove your key"],
  ["Data Sharing", "Nobody (your data is private)"],
  ["Purpose of Use", "Signing in, verifying your subscription, and Recruiter's background data fetching"],
  ["Key Storage & Sharing", "Stored in the TornManager database and used in Recruiter's shared fetching pool"],
  ["Key Access Level", "Public access (required)"],
];

export class AuthScreen {
  constructor(auth, overlay, api) {
    this.auth = auth;
    this.overlay = overlay;
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
    agreeText.append("I agree to the ", this.legalLink("Privacy Policy", "recruiter-privacy-policy"), " and ", this.legalLink("Terms of Service", "recruiter-terms-of-service"), ".");
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
        await this.auth.authenticate(apiKey);
        await this.verifySubscription();
        await this.joinFetchPool(apiKey);
        this.overlay.open();
      } catch (err) {
        error.textContent = err.message;
        button.disabled = false;
        button.textContent = "Sign in";
      }
    });

    const hint = Dom.el("p", "rc-auth-hint");
    hint.innerHTML =
      'A key with <strong>Public</strong> access is all Recruiter needs, and it accepts nothing else. ' +
      '<a href="https://www.torn.com/preferences.php#tab=api" target="_blank" rel="noopener">Create one here</a>. ' +
      'Recruiter requires an active TornManager subscription.';

    wrap.append(form, hint);
    container.appendChild(wrap);
  }

  legalLink(label, anchor) {
    const link = Dom.el("a", null, label);
    link.href = `https://tornmanager.com/legal#${anchor}`;
    link.target = "_blank";
    link.rel = "noopener";
    return link;
  }
  async verifySubscription() {
    await this.auth.fetchSubscription().catch(() => null);
    if (this.auth.isSubscribed()) return;

    this.auth.clear();
    throw new Error("No active subscription. Send Xanax to Bram [2728237] — each adds 1 week — then sign in again.");
  }

  async joinFetchPool(apiKey) {
    try {
      await this.api.submitKey(apiKey);
    } catch (err) {
      if (err.status === 409) return;
      this.auth.clear();
      throw err;
    }
  }
}
