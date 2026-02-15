import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["list"]

  connect() {
    console.log("API Live Feed controller connected")
    console.log("List target:", this.listTarget)
    
    this.subscription = consumer.subscriptions.create("ApiRateMonitorChannel", {
      connected: this.connected.bind(this),
      disconnected: this.disconnected.bind(this),
      received: this.received.bind(this)
    })
  }

  disconnect() {
    console.log("API Live Feed controller disconnected")
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  connected() {
    console.log("WebSocket connected to ApiRateMonitorChannel")
  }

  disconnected() {
    console.log("WebSocket disconnected from ApiRateMonitorChannel")
  }

  received(data) {
    console.log("Received API call data:", data)
    this.addApiCallToFeed(data)
  }

  addApiCallToFeed(call) {
    if (!this.hasListTarget) {
      console.error("List target not found!")
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
    
    console.log("Adding item to feed:", item)
    this.listTarget.prepend(item)
    
    requestAnimationFrame(() => {
      item.classList.add("live-api-item-visible")
    })
    
    setTimeout(() => {
      item.classList.remove("live-api-item-visible")
      item.classList.add("live-api-item-fade-out")
      
      setTimeout(() => {
        console.log("Removing item from feed")
        item.remove()
      }, 300)
    }, 3000)
  }

  formatEndpoint(endpoint) {
    return endpoint.replace(/^v\d+\//, "")
  }
}
