import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "body", "arrow"]

  sort(event) {
    const th = event.currentTarget
    const column = parseInt(th.dataset.column)
    const type = th.dataset.sortType || "number"
    const currentDir = th.dataset.sortDir || "none"
    const newDir = currentDir === "asc" ? "desc" : "asc"

    this.headerTargets.forEach(h => {
      h.dataset.sortDir = "none"
    })

    this.arrowTargets.forEach(arrow => {
      arrow.classList.remove("active", "asc")
    })

    th.dataset.sortDir = newDir
    const arrow = th.querySelector(".sort-arrow")
    if (arrow) {
      arrow.classList.add("active")
      if (newDir === "asc") arrow.classList.add("asc")
    }

    const table = this.element.querySelector("table")
    const bodies = this.bodyTargets

    if (bodies.length > 1) {
      bodies.sort((a, b) => {
        const aVal = this.getCellValue(a.rows[0], column, type)
        const bVal = this.getCellValue(b.rows[0], column, type)

        if (aVal < bVal) return newDir === "asc" ? -1 : 1
        if (aVal > bVal) return newDir === "asc" ? 1 : -1
        return 0
      })

      bodies.forEach(tbody => table.appendChild(tbody))
    } else if (bodies.length === 1) {
      const rows = Array.from(bodies[0].querySelectorAll("tr"))

      rows.sort((a, b) => {
        const aVal = this.getCellValue(a, column, type)
        const bVal = this.getCellValue(b, column, type)

        if (aVal < bVal) return newDir === "asc" ? -1 : 1
        if (aVal > bVal) return newDir === "asc" ? 1 : -1
        return 0
      })

      rows.forEach(row => bodies[0].appendChild(row))
    }
  }

  getCellValue(row, column, type) {
    const cell = row && row.cells ? row.cells[column] : null
    if (!cell) return 0

    const text = cell.textContent.trim().replace(/,/g, "")

    if (type === "string") return text.toLowerCase()
    return parseFloat(text) || 0
  }
}
