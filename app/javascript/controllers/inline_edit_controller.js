import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cell"]
  static values = { url: String }

  connect() {
    this.cellTargets.forEach(cell => {
      cell.addEventListener("dblclick", () => this.startEditing(cell))
    })
  }

  startEditing(cell) {
    if (cell.querySelector("input")) return

    const currentValue = cell.textContent.trim().replace(/,/g, "")
    const field = cell.dataset.field

    const input = document.createElement("input")
    input.type = "text"
    input.value = currentValue
    input.className = "inline-edit-input"
    input.dataset.field = field
    input.dataset.originalValue = currentValue

    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter") this.save(input, cell)
      if (e.key === "Escape") this.cancel(input, cell)
    })
    input.addEventListener("blur", () => this.save(input, cell))

    cell.textContent = ""
    cell.appendChild(input)
    input.focus()
    input.select()
  }

  async save(input, cell) {
    const newValue = input.value.replace(/,/g, "")
    const originalValue = input.dataset.originalValue
    const field = input.dataset.field

    if (newValue === originalValue) {
      this.cancel(input, cell)
      return
    }

    const token = document.querySelector('meta[name="csrf-token"]').content

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          "Accept": "application/json"
        },
        body: JSON.stringify({ spy_report: { [field]: newValue } })
      })

      if (response.ok) {
        cell.textContent = Number(newValue).toLocaleString()
        // Update total
        this.updateTotal()
      } else {
        cell.textContent = Number(originalValue).toLocaleString()
      }
    } catch {
      cell.textContent = Number(originalValue).toLocaleString()
    }
  }

  cancel(input, cell) {
    cell.textContent = Number(input.dataset.originalValue).toLocaleString()
  }

  updateTotal() {
    const fields = ["strength", "defense", "speed", "dexterity"]
    let total = 0

    fields.forEach(field => {
      const cell = this.cellTargets.find(c => c.dataset.field === field)
      if (cell) {
        total += Number(cell.textContent.replace(/,/g, ""))
      }
    })

    const totalCell = this.element.querySelector(".spy-stats-total")
    if (totalCell) {
      totalCell.textContent = total.toLocaleString()
    }
  }
}
