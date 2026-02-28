import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = {
    ourScore: Number,
    theirScore: Number
  }

  static targets = ["ourScore", "theirScore"]

  connect() {
    this.subscription = consumer.subscriptions.create("WarChannel", {
      received: (data) => this.onReceived(data)
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
      this.subscription = null
    }
  }

  onReceived(data) {
    if (data.our_score !== undefined && this.hasOurScoreTarget) {
      this.ourScoreTarget.textContent = data.our_score
    }
    if (data.their_score !== undefined && this.hasTheirScoreTarget) {
      this.theirScoreTarget.textContent = data.their_score
    }
  }
}
