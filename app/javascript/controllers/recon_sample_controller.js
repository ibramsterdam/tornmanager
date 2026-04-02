import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details"]

  toggle() {
    const row = this.detailsTarget
    row.style.display = row.style.display === "none" ? "table-row" : "none"
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
