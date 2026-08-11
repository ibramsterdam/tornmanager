import { MugKey } from "../core/MugKey.js";
import { TornDirect } from "../core/TornDirect.js";
import { ApiDisclosure, MUG_KEY_DISCLOSURE } from "./ApiDisclosure.js";

const CHECK_ICON =
  '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>';

export class MuggingSection {
  constructor(api) {
    this.api = api;
  }

  render() {
    this.section = document.createElement("div");
    this.section.className = "tm-mugging";

    const title = document.createElement("h2");
    title.className = "tm-mugging-title";
    title.textContent = "Mugging";
    this.section.appendChild(title);

    this.body = document.createElement("div");
    this.section.appendChild(this.body);

    if (MugKey.get()) {
      this.renderWelcome();
    } else {
      this.renderKeyForm();
    }

    return this.section;
  }

  renderKeyForm() {
    this.body.innerHTML = "";

    const card = document.createElement("div");
    card.className = "tm-mugging-connect";

    const sub = document.createElement("p");
    sub.className = "tm-mugging-connect-sub";
    sub.innerHTML =
      "The Mugging tab reads your <strong>attack mug logs</strong>, which Torn only exposes to a Full Access " +
      "key. It calls Torn directly and is stored only in this browser, never sent to TornManager.";
    card.appendChild(sub);

    this.input = document.createElement("input");
    this.input.type = "text";
    this.input.className = "tm-mugging-input";
    this.input.placeholder = "Full Access API key";
    this.input.autocomplete = "off";
    this.input.spellcheck = false;

    this.saveBtn = document.createElement("button");
    this.saveBtn.type = "submit";
    this.saveBtn.className = "tm-mugging-save";
    this.saveBtn.textContent = "Verify & save";
    this.saveBtn.disabled = true;

    this.error = document.createElement("p");
    this.error.className = "tm-mugging-error";

    this.disclosure = new ApiDisclosure(MUG_KEY_DISCLOSURE, (agreed) => {
      this.saveBtn.disabled = !agreed;
    });
    card.appendChild(this.disclosure.render());

    const form = document.createElement("form");
    form.className = "tm-mugging-form";
    form.appendChild(this.input);
    form.appendChild(this.saveBtn);
    form.appendChild(this.error);
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      this.validateAndSave();
    });
    card.appendChild(form);

    this.body.appendChild(card);
  }

  validateAndSave() {
    if (!this.disclosure.isAgreed()) return;

    this.error.textContent = "";

    const key = this.input.value.trim();
    if (!key) {
      this.error.textContent = "Enter your Full Access API key.";
      return;
    }

    this.saveBtn.disabled = true;
    this.saveBtn.textContent = "Verifying…";

    TornDirect.keyInfo(key)
      .then((data) => {
        const type = data?.info?.access?.type;
        if (type !== "Full Access") {
          this.error.textContent = `This key is ${type || "not valid"}. A Full Access key is required.`;
          this.resetSaveButton();
          return;
        }
        MugKey.set(key);
        this.renderWelcome();
      })
      .catch((err) => {
        this.error.textContent = err.message || "Could not verify the key.";
        this.resetSaveButton();
      });
  }

  resetSaveButton() {
    this.saveBtn.disabled = false;
    this.saveBtn.textContent = "Verify & save";
  }

  renderWelcome() {
    this.body.innerHTML = "";

    const card = document.createElement("div");
    card.className = "tm-mugging-welcome";

    const icon = document.createElement("span");
    icon.className = "tm-mugging-welcome-icon";
    icon.innerHTML = CHECK_ICON;
    card.appendChild(icon);

    const welcome = document.createElement("h3");
    welcome.className = "tm-mugging-welcome-title";
    welcome.textContent = "Welcome";
    card.appendChild(welcome);

    const note = document.createElement("p");
    note.className = "tm-mugging-note";
    note.textContent = "Your Full Access key is saved on this device. Mugging tools are coming soon.";
    card.appendChild(note);

    const remove = document.createElement("button");
    remove.type = "button";
    remove.className = "tm-mugging-remove";
    remove.textContent = "Remove key";
    remove.onclick = () => {
      MugKey.clear();
      this.renderKeyForm();
    };
    card.appendChild(remove);

    this.body.appendChild(card);
  }

  destroy() {}
}
