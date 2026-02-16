import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 3000 } }

  connect() {
    // Animate in
    requestAnimationFrame(() => {
      this.element.classList.add("flash-notification-visible")
    })
    
    // Auto-dismiss after duration
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, this.durationValue)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    this.element.classList.add("flash-notification-fade-out")
    this.element.classList.remove("flash-notification-visible")
    
    this.element.addEventListener("animationend", () => {
      this.element.remove()
    }, { once: true })
  }
}
