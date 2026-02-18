import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async remove(event) {
    event.preventDefault()
    
    const form = event.target.closest("form")
    if (!form) return

    try {
      const response = await fetch(form.action, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      const data = await response.json()

      if (data.success) {
        this.element.remove()
        this.showFlash("notice", data.message)
      } else {
        this.showFlash("alert", data.message || "Something went wrong")
      }
    } catch (error) {
      console.error("Backfill error:", error)
      this.showFlash("alert", "Failed to schedule backfill jobs")
    }
  }

  showFlash(type, message) {
    window.dispatchEvent(new CustomEvent("flash:show", {
      detail: { type, message }
    }))
  }
}
