import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["truncated", "full"]

  toggle() {
    this.truncatedTarget.classList.toggle("hidden")
    this.fullTarget.classList.toggle("hidden")
  }
}
