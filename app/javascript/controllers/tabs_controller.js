import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { default: String }
  static targets = ["button", "panel"]

  connect() {
    // Check URL hash for active tab
    const hash = window.location.hash.slice(1)
    const activeTab = hash || this.defaultValue || this.buttonTargets[0]?.dataset.tab

    if (activeTab) {
      this.activateTab(activeTab)
    }
  }

  switch(event) {
    const tab = event.currentTarget.dataset.tab
    this.activateTab(tab)
    
    // Update URL hash without scrolling
    history.replaceState(null, null, `#${tab}`)
  }

  activateTab(tabName) {
    // Update buttons
    this.buttonTargets.forEach(button => {
      button.classList.toggle("active", button.dataset.tab === tabName)
    })

    // Update panels
    this.panelTargets.forEach(panel => {
      panel.classList.toggle("active", panel.dataset.tab === tabName)
      panel.hidden = panel.dataset.tab !== tabName
    })
  }
}
