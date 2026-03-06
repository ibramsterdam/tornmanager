import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.subscription = consumer.subscriptions.create("ApiRateMonitorChannel", {
      connected: this.connected.bind(this),
      disconnected: this.disconnected.bind(this),
      received: this.received.bind(this)
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  connected() {
  }

  disconnected() {
  }

  received(data) {
    this.addApiCallToFeed(data)
  }

  addApiCallToFeed(call) {
    if (!this.hasListTarget) {
      return
    }

    const item = document.createElement("div")
    item.className = "live-api-item"
    item.dataset.id = call.id
    
    const statusClass = call.status === "success" ? "success" : "error"
    const statusIcon = call.status === "success" ? "✓" : "✗"
    
    item.innerHTML = `
      <span class="live-api-endpoint">${this.formatEndpoint(call.endpoint)}</span>
      <span class="live-api-status live-api-status-${statusClass}">${statusIcon}</span>
      <span class="live-api-time">${call.response_time}ms</span>
    `
    
    this.listTarget.prepend(item)

    const maxVisible = 3
    const items = this.listTarget.querySelectorAll(".live-api-item")
    if (items.length > maxVisible) {
      Array.from(items).slice(maxVisible).forEach(el => el.remove())
    }

    requestAnimationFrame(() => {
      item.classList.add("live-api-item-visible")
    })
    
    setTimeout(() => {
      item.classList.remove("live-api-item-visible")
      item.classList.add("live-api-item-fade-out")
      
      setTimeout(() => {
        item.remove()
      }, 300)
    }, 3000)
  }

  formatEndpoint(endpoint) {
    return endpoint.replace(/^v\d+\//, "")
  }
}
