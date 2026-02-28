import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { csrf: String }
  static targets = ["backdrop", "modal", "password", "error", "submitButton"]

  #unlockUrl = null

  open(event) {
    this.#unlockUrl = event.params.url
    this.errorTarget.hidden = true
    this.errorTarget.textContent = ""
    this.passwordTarget.value = ""
    this.submitButtonTarget.disabled = false
    this.backdropTarget.hidden = false
    this.passwordTarget.focus()
  }

  close() {
    this.backdropTarget.hidden = true
    this.#unlockUrl = null
  }

  backdropClose(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  async submit(event) {
    event.preventDefault()

    const password = this.passwordTarget.value
    if (!password) return

    this.submitButtonTarget.disabled = true
    this.errorTarget.hidden = true

    try {
      const response = await fetch(this.#unlockUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfValue
        },
        body: JSON.stringify({ password })
      })

      const data = await response.json()

      if (response.ok) {
        window.location.href = data.redirect_to
      } else {
        this.errorTarget.textContent = data.error
        this.errorTarget.hidden = false
        this.passwordTarget.select()
        this.submitButtonTarget.disabled = false
      }
    } catch {
      this.errorTarget.textContent = "Something went wrong. Please try again."
      this.errorTarget.hidden = false
      this.submitButtonTarget.disabled = false
    }
  }
}
