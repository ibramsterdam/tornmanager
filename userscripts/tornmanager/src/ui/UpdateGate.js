import { UpdateCheck, DOWNLOAD_URL } from "../core/UpdateCheck.js";

const CHECK_INTERVAL_MS = 10 * 60 * 1000;

export class UpdateGate {
  start() {
    const begin = () => {
      this.check();
      setInterval(() => this.check(), CHECK_INTERVAL_MS);
    };

    if (document.body) {
      begin();
    } else {
      window.addEventListener("DOMContentLoaded", begin, { once: true });
    }
  }

  check() {
    UpdateCheck.status()
      .then(({ forced, latest }) => (forced ? this.engage(latest) : this.disengage()))
      .catch(() => {});
  }

  engage(latest) {
    document.documentElement.classList.add("tm-force-update");
    if (document.querySelector(".tm-force-update-bar")) return;

    const bar = document.createElement("div");
    bar.className = "tm-force-update-bar";

    const text = document.createElement("span");
    text.textContent = `TornManager needs updating to keep working. A required update (v${latest}) is out. You're on v${UpdateCheck.current}.`;

    const link = document.createElement("a");
    link.href = DOWNLOAD_URL;
    link.target = "_blank";
    link.rel = "noopener";
    link.className = "tm-force-update-link";
    link.textContent = "Update now";

    bar.appendChild(text);
    bar.appendChild(link);
    document.body.appendChild(bar);
  }

  disengage() {
    document.documentElement.classList.remove("tm-force-update");
    document.querySelector(".tm-force-update-bar")?.remove();
  }
}
