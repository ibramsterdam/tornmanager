import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { default: String }
  static targets = ["button", "panel"]

  connect() {
    const hash = window.location.hash.slice(1)
    const activeTab = hash || this.defaultValue || this.buttonTargets[0]?.dataset.tab

    if (activeTab) {
      this.activateTab(activeTab)
    }
  }

  switch(event) {
    const tab = event.currentTarget.dataset.tab
    this.activateTab(tab)
    
    history.replaceState(null, null, `#${tab}`)
  }

  activateTab(tabName) {
    this.buttonTargets.forEach(button => {
      button.classList.toggle("active", button.dataset.tab === tabName)
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("active", panel.dataset.tab === tabName)
      panel.hidden = panel.dataset.tab !== tabName
    })
  }
}
