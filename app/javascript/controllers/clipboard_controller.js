import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      this.showFlash("notice", "Copied to clipboard!")
    }).catch(() => {
      this.showFlash("alert", "Failed to copy to clipboard")
    })
  }

  showFlash(type, message) {
    window.dispatchEvent(new CustomEvent("flash:show", {
      detail: { type, message }
    }))
  }
}
