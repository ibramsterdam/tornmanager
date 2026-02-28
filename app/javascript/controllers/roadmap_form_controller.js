import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]
  static values = { editing: Boolean }

  connect() {
    if (this.editingValue && this.hasPanelTarget) {
      requestAnimationFrame(() => {
        this.open()
      })
    }
  }

  show(event) {
    event.preventDefault()
    this.open()
  }

  hide(event) {
    if (event) event.preventDefault()
    this.panelTarget.classList.remove("roadmap-form-panel--open")
    this.overlayTarget.classList.remove("roadmap-form-overlay--visible")
    document.body.style.overflow = ""

    if (this.editingValue) {
      const url = new URL(window.location)
      url.searchParams.delete("edit")
      history.replaceState(null, "", url)
    }
  }

  hideOnEscape(event) {
    if (event.key === "Escape") {
      this.hide()
    }
  }

  open() {
    this.panelTarget.classList.add("roadmap-form-panel--open")
    this.overlayTarget.classList.add("roadmap-form-overlay--visible")
    document.body.style.overflow = "hidden"

    setTimeout(() => {
      const firstInput = this.panelTarget.querySelector("input[type='text']")
      if (firstInput) firstInput.focus()
    }, 300)
  }
}
