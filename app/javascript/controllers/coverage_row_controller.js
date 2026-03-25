import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details", "action", "result", "button"]

  toggle() {
    const row = this.detailsTarget
    row.style.display = row.style.display === "none" ? "table-row" : "none"
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  async backfill(event) {
    event.preventDefault()
    event.stopPropagation()

    const form = this.buttonTarget.closest("form")
    const url = form.action
    const token = form.querySelector("[name='authenticity_token']").value

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Scheduling..."

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          "Accept": "application/json"
        }
      })

      const data = await response.json()

      this.actionTarget.style.display = "none"
      this.resultTarget.style.display = "block"
      this.resultTarget.textContent = data.message
    } catch {
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "Backfill Now"
    }
  }
}
