import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Listen for custom flash events from other controllers
    window.addEventListener("flash:show", this.handleFlashEvent.bind(this))
  }

  disconnect() {
    window.removeEventListener("flash:show", this.handleFlashEvent.bind(this))
  }

  handleFlashEvent(event) {
    const { type, message } = event.detail
    this.addFlash(type, message)
  }

  addFlash(type, message) {
    const duration = type === "alert" ? 5000 : 3000
    const iconSvg = type === "notice" 
      ? `<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M13.5 4.5L6 12L2.5 8.5" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>`
      : `<svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="8" cy="8" r="6"/>
          <path d="M8 5v3" stroke-linecap="round"/>
          <circle cx="8" cy="11" r="0.5" fill="currentColor"/>
        </svg>`

    const html = `
      <div class="flash-notification flash-notification-${type}" 
           data-controller="flash-item"
           data-flash-item-duration-value="${duration}"
           role="alert">
        <div class="flash-notification-content">
          <span class="flash-notification-icon">${iconSvg}</span>
          <span class="flash-notification-message">${this.escapeHtml(message)}</span>
        </div>
        <button class="flash-notification-close" data-action="click->flash-item#dismiss" aria-label="Dismiss">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 3l8 8M11 3l-8 8" stroke-linecap="round"/>
          </svg>
        </button>
      </div>
    `

    this.element.insertAdjacentHTML("beforeend", html)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
