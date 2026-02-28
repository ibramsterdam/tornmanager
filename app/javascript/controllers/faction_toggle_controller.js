import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, row: String }

  async toggle(event) {
    const checkbox = event.target
    const row = document.getElementById(this.rowValue)
    
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      const data = await response.json()
      
      if (data.success) {
        const memberCountCell = row.querySelector(".member-count")
        if (memberCountCell) {
          memberCountCell.textContent = data.member_count
        }
      } else {
        checkbox.checked = !checkbox.checked
        alert(`Error: ${data.error}`)
      }
    } catch (error) {
      checkbox.checked = !checkbox.checked
      alert(`Failed to update: ${error.message}`)
    }
  }
}
