import { Controller } from "@hotwired/stimulus"

// Shows skeleton loading state on form submission
export default class extends Controller {
  static targets = ["content", "skeleton"]

  submit() {
    // Hide real content, show skeletons
    this.contentTargets.forEach(el => el.style.display = "none")
    this.skeletonTargets.forEach(el => el.style.display = "block")
  }
}
