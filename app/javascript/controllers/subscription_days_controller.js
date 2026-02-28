import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "input", "button", "expiresAt"]
  static values = { url: String }

  edit(event) {
    event.preventDefault()
    
    if (this.buttonTarget.textContent === "Edit") {
      this.displayTarget.style.display = "none"
      this.inputTarget.style.display = "inline-block"
      this.buttonTarget.textContent = "Save"
      this.inputTarget.focus()
      this.inputTarget.select()
    } else {
      this.save()
    }
  }

  keypress(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.save()
    }
  }

  async save() {
    const days = parseInt(this.inputTarget.value)
    
    if (isNaN(days) || days < 0) {
      alert("Please enter a valid number of days (0 or greater)")
      return
    }

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Saving..."

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ days })
      })

      const data = await response.json()

      if (data.success) {
        this.displayTarget.textContent = `${data.days} days`
        this.inputTarget.value = data.days
        this.expiresAtTarget.textContent = data.new_expires_at
        this.displayTarget.style.display = "inline"
        this.inputTarget.style.display = "none"
        this.buttonTarget.textContent = "Edit"
      } else {
        alert(`Error: ${data.error}`)
      }
    } catch (error) {
      alert(`Error updating subscription: ${error}`)
    } finally {
      this.buttonTarget.disabled = false
    }
  }
}
