import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "skeleton"]

  submit() {
    this.contentTargets.forEach(el => el.style.display = "none")
    this.skeletonTargets.forEach(el => el.style.display = "block")
  }
}
