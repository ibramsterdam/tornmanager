import bannerSvg from "../../assets/company-banner.svg?raw";
import { Dom } from "@shared/core/Dom.js";

const DISCLOSURE = [
  ["Data Storage", "Your key and a daily copy of your company data, until you remove your key"],
  ["Data Sharing", "Nobody (your data is private)"],
  ["Purpose of Use", "Signing in, verifying your subscription, and your daily company history and advice"],
  ["Key Storage & Sharing", "Stored encrypted on TornManager. Only used to read your own company. Never shared"],
  ["Key Access Level", "Limited access (required)"],
];

const KEY_URL = "https://www.torn.com/preferences.php#tab=api?&step=addNewKey&title=TM%20Company&type=3";

export class AuthScreen {
  constructor(auth, overlay) {
    this.auth = auth;
    this.overlay = overlay;
  }

  subtitle() {
    return "sign in";
  }

  render(container) {
    const wrap = Dom.el("div", "tc-auth");

    const banner = Dom.el("div", "tc-auth-banner");
    banner.innerHTML = bannerSvg;
    wrap.appendChild(banner);

    const form = Dom.el("form", "tc-auth-form");
    const row = Dom.el("div", "tc-auth-row");

    const input = Dom.el("input", "tc-auth-input");
    input.type = "text";
    input.placeholder = "Add Limited Torn API key";
    input.autocomplete = "off";
    input.spellcheck = false;

    const button = Dom.el("button", "tc-auth-button", "Sign in");
    button.type = "submit";
    button.disabled = true;

    const error = Dom.el("p", "tc-auth-error");

    row.append(input, button);
    form.append(row, error);
    form.appendChild(this.disclosure(button));

    form.addEventListener("submit", async (e) => {
      e.preventDefault();
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
        this.overlay.open();
      } catch (err) {
        error.textContent = err.message;
        button.disabled = false;
        button.textContent = "Sign in";
      }
    });

    const hint = Dom.el("p", "tc-auth-hint");
    hint.append(
      "Only company directors can sign in, with a key that has ",
      Dom.el("strong", null, "Limited"),
      " access. Torn only shares wages, stock and employee effectiveness with Limited keys. "
    );
    const create = Dom.el("a", null, "Create one here");
    create.href = KEY_URL;
    create.target = "_blank";
    create.rel = "noopener";
    hint.append(create, ". TM Company requires an active TornManager subscription.");

    wrap.append(form, hint);
    container.appendChild(wrap);
  }

  disclosure(button) {
    const tos = Dom.el("div", "tc-tos");
    tos.appendChild(Dom.el("p", "tc-tos-heading", "How your key and data are handled"));
    const grid = Dom.el("div", "tc-tos-grid");
    for (const [label, value] of DISCLOSURE) {
      const item = Dom.el("div", "tc-tos-item");
      item.append(Dom.el("span", "tc-tos-label", label), Dom.el("span", "tc-tos-value", value));
      grid.appendChild(item);
    }
    tos.appendChild(grid);

    const agree = Dom.el("label", "tc-tos-agree");
    const checkbox = Dom.el("input");
    checkbox.type = "checkbox";
    checkbox.addEventListener("change", () => {
      button.disabled = !checkbox.checked;
    });
    const text = Dom.el("span");
    text.append("I agree to the ", legalLink("Privacy Policy", "company-privacy-policy"), " and ", legalLink("Terms of Service", "company-terms-of-service"), ".");
    agree.append(checkbox, text);
    tos.appendChild(agree);
    return tos;
  }

  async verifySubscription() {
    await this.auth.fetchSubscription().catch(() => null);
    if (this.auth.isSubscribed()) return;

    this.auth.clear();
    throw new Error("No active subscription. Send Xanax to Bram [2728237], each adds 1 week, then sign in again.");
  }
}

function legalLink(label, anchor) {
  const link = Dom.el("a", null, label);
  link.href = `https://tornmanager.com/legal#${anchor}`;
  link.target = "_blank";
  link.rel = "noopener";
  return link;
}
