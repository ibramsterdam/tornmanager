import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.updateButtonState()
  }

  toggle() {
    this.updateButtonState()
  }

  updateButtonState() {
    this.submitTarget.disabled = !this.checkboxTarget.checked
  }
}
