import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { secondsRemaining: Number }
  static targets = ["countdown"]

  connect() {
    if (this.hasSecondsRemainingValue && this.secondsRemainingValue > 0) {
      this.startCountdown()
    }
  }

  disconnect() {
    this.stopCountdown()
  }

  startCountdown() {
    this.updateDisplay()
    this.intervalId = setInterval(() => {
      this.secondsRemainingValue -= 1
      
      if (this.secondsRemainingValue <= 0) {
        this.stopCountdown()
        this.reloadPage()
      } else {
        this.updateDisplay()
      }
    }, 1000)
  }

  stopCountdown() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
  }

  updateDisplay() {
    const hours = Math.floor(this.secondsRemainingValue / 3600)
    const minutes = Math.floor((this.secondsRemainingValue % 3600) / 60)
    const seconds = this.secondsRemainingValue % 60

    let display = ""
    if (hours > 0) {
      display = `${hours}h ${minutes}m ${seconds}s`
    } else if (minutes > 0) {
      display = `${minutes}m ${seconds}s`
    } else {
      display = `${seconds}s`
    }

    if (this.hasCountdownTarget) {
      this.countdownTarget.textContent = display
    }
  }

  reloadPage() {
    window.location.reload()
  }
}
