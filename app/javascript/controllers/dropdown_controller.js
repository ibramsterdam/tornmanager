import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "arrow"]

  connect() {
    this.boundClose = this.close.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    
    if (this.menuTarget.classList.contains("navbar-dropdown-open")) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("navbar-dropdown-open")
    this.arrowTarget.classList.add("navbar-user-arrow-open")
    document.addEventListener("click", this.boundClose)
  }

  close() {
    this.menuTarget.classList.remove("navbar-dropdown-open")
    this.arrowTarget.classList.remove("navbar-user-arrow-open")
    document.removeEventListener("click", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }
}
