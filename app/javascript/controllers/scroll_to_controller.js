import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  scroll() {
    const element = document.getElementById(this.targetValue)
    if (element) {
      element.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }
}
