import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  validateInput() {
    const value = this.inputTarget.value.trim()
    // Torn API keys are 16 characters
    const isValid = value.length === 16 && /^[a-zA-Z0-9]+$/.test(value)
    this.submitTarget.disabled = !isValid
  }

  async submit(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Validating..."
    
    try {
      const response = await fetch(form.action, {
        method: "PATCH",
        body: formData,
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })
      
      const data = await response.json()
      
      if (data.success) {
        this.showFlash("notice", data.message)
        this.inputTarget.value = ""
        this.submitTarget.textContent = "Update"
        this.submitTarget.disabled = true
        // Refresh just the Turbo Frame to update masked key and access level
        this.refreshApiKeyCard()
      } else {
        this.showFlash("alert", data.message)
        this.submitTarget.textContent = "Update"
        this.submitTarget.disabled = true
      }
    } catch (error) {
      console.error("error:", error)
      this.showFlash("alert", "An error occurred. Please try again.")
      this.submitTarget.textContent = "Update"
      this.submitTarget.disabled = true
    }
  }

  showFlash(type, message) {
    window.dispatchEvent(new CustomEvent("flash:show", {
      detail: { type, message }
    }))
  }

  refreshApiKeyCard() {
    const frame = document.getElementById("api_key_card")
    if (frame) {
      frame.src = "/settings/api_key_card"
      frame.reload()
    }
  }
}
