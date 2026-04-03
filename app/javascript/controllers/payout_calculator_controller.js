import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["totalPot", "factionCut", "assistValue", "factionCutAmount", "payoutPot", "payoutCell"]

  connect() {
    this.calculate()
  }

  calculate() {
    const totalPot = this.parseNumber(this.totalPotTarget.value)
    const factionCutPct = parseFloat(this.factionCutTarget.value) || 0
    const assistValue = parseFloat(this.assistValueTarget.value) || 0.75

    const factionCutAmount = Math.round(totalPot * (factionCutPct / 100))
    const payoutPot = totalPot - factionCutAmount

    this.factionCutAmountTarget.textContent = this.formatNumber(factionCutAmount)
    this.payoutPotTarget.textContent = this.formatNumber(payoutPot)

    // Calculate weighted score for each member
    let totalWeightedScore = 0
    const memberScores = []

    this.payoutCellTargets.forEach(cell => {
      const hits = parseFloat(cell.dataset.hits) || 0
      const assists = parseFloat(cell.dataset.assists) || 0
      const respect = parseFloat(cell.dataset.respect) || 0

      // Weighted: full hits by respect, assists at assist value
      const weightedScore = respect + (assists * assistValue)
      totalWeightedScore += weightedScore
      memberScores.push({ cell, weightedScore })
    })

    memberScores.forEach(({ cell, weightedScore }) => {
      if (totalWeightedScore > 0 && payoutPot > 0) {
        const share = weightedScore / totalWeightedScore
        const payout = Math.round(payoutPot * share)
        cell.textContent = this.formatNumber(payout)
      } else {
        cell.textContent = "—"
      }
    })
  }

  parseNumber(str) {
    return parseInt((str || "0").replace(/,/g, "")) || 0
  }

  formatNumber(num) {
    return num.toLocaleString()
  }
}
