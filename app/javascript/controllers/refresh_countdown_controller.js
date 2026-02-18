import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    secondsRemaining: Number,
    buttonText: { type: String, default: "Check for New Payments" }
  }

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
        this.enableButton()
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
    this.element.value = `Available in ${this.secondsRemainingValue}s`
  }

  enableButton() {
    this.element.disabled = false
    this.element.value = this.buttonTextValue
  }
}
