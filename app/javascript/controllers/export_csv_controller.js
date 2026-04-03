import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table", "totalPot", "factionCut", "assistValue"]

  export() {
    const totalPot = this.totalPotTarget.value || "0"
    const factionCut = this.factionCutTarget.value || "0"
    const assistValue = this.assistValueTarget.value || "0.75"

    const rows = []

    rows.push(["War Report Export"])
    rows.push(["Total Pot", totalPot])
    rows.push(["Faction Cut %", factionCut])
    rows.push(["Assist Value", assistValue])
    rows.push([])

    const table = this.tableTarget

    // Headers from the main thead only
    const mainThead = table.querySelector(":scope > thead")
    const headers = Array.from(mainThead.querySelectorAll("th")).map(th => th.textContent.trim())
    rows.push(headers)

    // Only the summary rows (first tr of each direct tbody child)
    const tbodies = table.querySelectorAll(":scope > tbody")
    tbodies.forEach(tbody => {
      const summaryRow = tbody.querySelector(":scope > tr:first-child")
      if (!summaryRow || summaryRow.cells.length !== headers.length) return

      const cells = Array.from(summaryRow.cells).map(cell => cell.textContent.trim().replace(/\s+/g, " "))
      rows.push(cells)
    })

    const csv = rows.map(row =>
      row.map(cell => {
        const str = String(cell)
        if (str.includes(",") || str.includes('"') || str.includes("\n")) {
          return `"${str.replace(/"/g, '""')}"`
        }
        return str
      }).join(",")
    ).join("\n")

    const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" })
    const url = URL.createObjectURL(blob)
    const link = document.createElement("a")
    link.href = url
    link.download = `war_report_${new Date().toISOString().split("T")[0]}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }
}
