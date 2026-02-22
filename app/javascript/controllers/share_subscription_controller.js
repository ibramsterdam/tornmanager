import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "hidden", "preview", "submit"]
  static values = { memberCount: Number, maxTotal: Number }

  slide() {
    const steps = parseInt(this.sliderTarget.value)
    const members = this.memberCountValue
    const totalWeeks = steps * members
    const perMember = steps

    this.hiddenTarget.value = totalWeeks

    if (totalWeeks === 0) {
      this.previewTarget.textContent = "Drag the slider to share subscription time."
      this.submitTarget.disabled = true
      return
    }

    this.submitTarget.disabled = false
    this.previewTarget.textContent = `${totalWeeks} weeks total — ${perMember} week${perMember !== 1 ? "s" : ""} each for ${members} members.`
  }
}
