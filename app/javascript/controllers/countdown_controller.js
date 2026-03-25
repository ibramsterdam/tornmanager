import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }
  static targets = ["display"]

  connect() {
    this.update()
    this.intervalId = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    if (this.intervalId) clearInterval(this.intervalId)
  }

  update() {
    const now = new Date()
    const target = new Date(this.targetValue)
    const diff = Math.max(0, Math.floor((target - now) / 1000))

    const hours = Math.floor(diff / 3600)
    const minutes = Math.floor((diff % 3600) / 60)
    const seconds = diff % 60

    const pad = (n) => String(n).padStart(2, "0")
    this.displayTarget.textContent = `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`
  }
}
