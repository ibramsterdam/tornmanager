import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    this.headings = this.linkTargets.map((link) => {
      const id = link.getAttribute("href").slice(1)
      return document.getElementById(id)
    }).filter(Boolean)

    this.onScroll = this.highlight.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })

    this.highlight()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  highlight() {
    const scrollY = window.scrollY
    const offset = 100
    let activeId = null

    for (const heading of this.headings) {
      if (heading.getBoundingClientRect().top + window.scrollY - offset <= scrollY) {
        activeId = heading.id
      }
    }

    if (!activeId && this.headings.length > 0) {
      activeId = this.headings[0].id
    }

    for (const link of this.linkTargets) {
      const id = link.getAttribute("href").slice(1)
      const isActive = id === activeId
      link.classList.toggle("active", isActive)
      if (isActive) {
        link.scrollIntoView({ block: "nearest", behavior: "smooth" })
      }
    }
  }
}
