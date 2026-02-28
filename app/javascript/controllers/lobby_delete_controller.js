import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { confirmation: String }
  static targets = ["input", "button"]

  validate() {
    const matches = this.inputTarget.value.trim().toLowerCase() === this.confirmationValue.toLowerCase()
    this.buttonTarget.disabled = !matches
  }
}
