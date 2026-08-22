import chatBannerSvg from "../../../../assets/chat-banner.svg?raw";
import { ApiDisclosure, MAIN_KEY_DISCLOSURE } from "./ApiDisclosure.js";

const BANNER_URI = `data:image/svg+xml;utf8,${encodeURIComponent(chatBannerSvg)}`;

export class AuthScreen {
  constructor(auth) {
    this.auth = auth;
  }

  render(onSuccess) {
    const container = document.createElement("div");
    container.className = "tm-auth";

    const banner = document.createElement("img");
    banner.className = "tm-auth-banner";
    banner.src = BANNER_URI;
    banner.alt = "";

    const form = document.createElement("form");
    form.className = "tm-auth-form";

    const input = document.createElement("input");
    input.type = "text";
    input.className = "tm-auth-input";
    input.placeholder = "Add Public Torn API key";
    input.autocomplete = "off";
    input.spellcheck = false;

    const button = document.createElement("button");
    button.type = "submit";
    button.className = "tm-auth-button";
    button.textContent = "Sign in";
    button.disabled = true;

    const error = document.createElement("p");
    error.className = "tm-auth-error";

    const row = document.createElement("div");
    row.className = "tm-auth-row";
    row.appendChild(input);
    row.appendChild(button);

    form.appendChild(row);
    form.appendChild(error);

    const disclosure = new ApiDisclosure(MAIN_KEY_DISCLOSURE, (agreed) => {
      button.disabled = !agreed;
    });
    form.appendChild(disclosure.render());

    form.addEventListener("submit", async (e) => {
      e.preventDefault();

      if (!disclosure.isAgreed()) return;

      const apiKey = input.value.trim();
      if (!apiKey) {
        error.textContent = "Please enter an API key.";
        return;
      }

      button.disabled = true;
      button.textContent = "Signing in...";
      error.textContent = "";

      try {
        const user = await this.auth.authenticate(apiKey);
        onSuccess(user);
      } catch (err) {
        error.textContent = err.message;
        button.disabled = false;
        button.textContent = "Sign in";
      }
    });

    const hint = document.createElement("p");
    hint.className = "tm-auth-hint";
    hint.innerHTML =
      'A key with <strong>Public</strong> access is all this extension needs. ' +
      '<a href="https://www.torn.com/preferences.php#tab=api" target="_blank" rel="noopener">Create one here</a>.';

    container.appendChild(banner);
    container.appendChild(form);
    container.appendChild(hint);

    return container;
  }
}
