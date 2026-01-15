import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect(){
    document.removeEventListener("keydown", this.handleKeydown)
  }

  handleKeydown = (e) => {
    if (this.#shouldIgnore(e)) return;

    if (["INPUT", "TEXTAREA"].includes(document.activeElement.tagName)) return;
    if (e.key === "p" && window.location.pathname !== "/") window.location.href = "/";
    if (e.key === "f" && window.location.pathname !== "/faction") window.location.href = "/faction";
    if (e.key === "r" && window.location.pathname !== "/ranked-war") window.location.href = "/ranked-war";
  }

  #shouldIgnore(event) {
    return event.defaultPrevented || event.target.closest("input, textarea, trix-editor")
  }
}
