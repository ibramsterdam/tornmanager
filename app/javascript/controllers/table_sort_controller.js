import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { column: { type: String, default: "" }, direction: { type: String, default: "asc" } }

  sort(event) {
    const column = event.currentTarget.dataset.sortColumn
    const type = event.currentTarget.dataset.sortType || "string"

    if (this.columnValue === column) {
      this.directionValue = this.directionValue === "asc" ? "desc" : "asc"
    } else {
      this.columnValue = column
      this.directionValue = "asc"
    }

    this.sortTable(column, type, this.directionValue)
    this.updateIndicators()
  }

  sortTable(column, type, direction) {
    const tbody = this.element.querySelector("tbody")
    const rows = Array.from(tbody.querySelectorAll("tr"))

    rows.sort((a, b) => {
      const aCell = a.querySelector(`[data-sort-key="${column}"]`)
      const bCell = b.querySelector(`[data-sort-key="${column}"]`)
      const aVal = this.parseValue(aCell, type)
      const bVal = this.parseValue(bCell, type)

      if (aVal === Infinity && bVal === Infinity) return 0
      if (aVal === Infinity) return 1
      if (bVal === Infinity) return -1

      let result
      if (typeof aVal === "string") {
        result = aVal.localeCompare(bVal)
      } else {
        result = aVal - bVal
      }

      return direction === "desc" ? -result : result
    })

    rows.forEach(row => tbody.appendChild(row))
  }

  parseValue(cell, type) {
    if (!cell) return type === "string" ? "" : 0

    const raw = cell.dataset.sortValue
    if (raw === "Infinity") return Infinity

    switch (type) {
      case "number":
        return parseFloat(raw) || 0
      case "boolean":
        return raw === "true" ? 1 : 0
      default:
        return raw || ""
    }
  }

  updateIndicators() {
    this.element.querySelectorAll("[data-sort-column]").forEach(header => {
      const arrow = header.querySelector(".sort-arrow")
      if (!arrow) return

      arrow.classList.remove("active", "asc")

      if (header.dataset.sortColumn === this.columnValue) {
        arrow.classList.add("active")
        if (this.directionValue === "asc") arrow.classList.add("asc")
      }
    })
  }
}
