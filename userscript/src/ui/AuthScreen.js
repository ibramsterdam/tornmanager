export class AuthScreen {
  constructor(auth) {
    this.auth = auth;
  }

  render(onSuccess) {
    const container = document.createElement("div");
    container.className = "tm-auth";

    const title = document.createElement("h1");
    title.className = "tm-overlay-title";
    title.textContent = "Welcome to Tornmanager";

    const subtitle = document.createElement("p");
    subtitle.className = "tm-auth-subtitle";
    subtitle.textContent = "Enter your Torn API key to get started.";

    const form = document.createElement("form");
    form.className = "tm-auth-form";

    const input = document.createElement("input");
    input.type = "text";
    input.className = "tm-auth-input";
    input.placeholder = "Torn API key";
    input.autocomplete = "off";
    input.spellcheck = false;

    const button = document.createElement("button");
    button.type = "submit";
    button.className = "tm-auth-button";
    button.textContent = "Sign in";

    const error = document.createElement("p");
    error.className = "tm-auth-error";

    form.appendChild(input);
    form.appendChild(button);
    form.appendChild(error);

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
        const user = await this.auth.authenticate(apiKey);
        onSuccess(user);
      } catch (err) {
        error.textContent = err.message;
        button.disabled = false;
        button.textContent = "Sign in";
      }
    });

    container.appendChild(title);
    container.appendChild(subtitle);
    container.appendChild(form);

    return container;
  }
}
