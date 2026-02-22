import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.checkOverflow()
    this.listTarget.addEventListener("scroll", this.onScroll.bind(this))
  }

  disconnect() {
    this.listTarget.removeEventListener("scroll", this.onScroll.bind(this))
  }

  checkOverflow() {
    const el = this.listTarget
    if (el.scrollHeight > el.clientHeight) {
      this.element.classList.add("has-overflow")
    }
  }

  onScroll() {
    const el = this.listTarget
    const atBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 10
    this.element.classList.toggle("scrolled-bottom", atBottom)
  }
}
