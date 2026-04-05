import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["factionCut", "assistValue", "saveBtn"]

  connect() {
    this.savedFactionCut = this.factionCutTarget.value
    this.savedAssistValue = this.assistValueTarget.value
    this.saveBtnTarget.disabled = true
  }

  checkDirty() {
    const dirty = this.factionCutTarget.value !== this.savedFactionCut ||
                  this.assistValueTarget.value !== this.savedAssistValue
    this.saveBtnTarget.disabled = !dirty
  }

  async save() {
    const btn = this.saveBtnTarget
    btn.disabled = true

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          faction_cut: parseFloat(this.factionCutTarget.value.replace(",", ".")) || 0,
          assist_value: parseFloat(this.assistValueTarget.value.replace(",", ".")) || 0
        })
      })

      if (response.ok) {
        this.savedFactionCut = this.factionCutTarget.value
        this.savedAssistValue = this.assistValueTarget.value
        window.dispatchEvent(new CustomEvent("flash:show", {
          detail: { type: "notice", message: "Payout settings saved." }
        }))
      } else {
        btn.disabled = false
        window.dispatchEvent(new CustomEvent("flash:show", {
          detail: { type: "alert", message: "Failed to save settings." }
        }))
      }
    } catch {
      btn.disabled = false
      window.dispatchEvent(new CustomEvent("flash:show", {
        detail: { type: "alert", message: "Failed to save settings." }
      }))
    }
  }
}
