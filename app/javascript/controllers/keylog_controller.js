import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit", "checkbox"]

  connect() {
    this.updateButtonState()
  }

  checkInput() {
    this.updateButtonState()
  }

  updateButtonState() {
    const hasValue = this.inputTarget.value.trim().length > 0
    const allCheckboxesChecked = this.checkboxTargets.every(checkbox => checkbox.checked)
    this.submitTarget.disabled = !(hasValue && allCheckboxesChecked)
  }
}
