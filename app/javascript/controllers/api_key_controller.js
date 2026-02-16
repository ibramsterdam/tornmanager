import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit", "feedback"]

  connect() {
    console.log("api-key controller connected")
  }

  validateInput() {
    const value = this.inputTarget.value.trim()
    // Torn API keys are 16 characters
    const isValid = value.length === 16 && /^[a-zA-Z0-9]+$/.test(value)
    this.submitTarget.disabled = !isValid
    this.clearFeedback()
  }

  async submit(event) {
    event.preventDefault()
    console.log("submit called")
    
    const form = event.target
    const formData = new FormData(form)
    
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Validating..."
    this.clearFeedback()
    
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
      console.log("response data:", data)
      
      if (data.success) {
        this.showFeedback(data.message, "success")
        this.inputTarget.value = ""
        this.submitTarget.disabled = true
        // Reload to update the masked key and access level
        setTimeout(() => window.location.reload(), 1500)
      } else {
        this.showFeedback(data.message, "error")
        this.submitTarget.textContent = "Update"
        this.submitTarget.disabled = true
      }
    } catch (error) {
      console.error("error:", error)
      this.showFeedback("An error occurred. Please try again.", "error")
      this.submitTarget.textContent = "Update"
      this.submitTarget.disabled = true
    }
  }

  showFeedback(message, type) {
    console.log("showFeedback:", message, type)
    this.feedbackTarget.textContent = message
    this.feedbackTarget.className = "api-key-feedback"
    this.feedbackTarget.classList.add(`api-key-feedback-${type}`)
    this.feedbackTarget.style.display = "block"
  }

  clearFeedback() {
    this.feedbackTarget.textContent = ""
    this.feedbackTarget.className = "api-key-feedback"
    this.feedbackTarget.style.display = ""
  }
}
