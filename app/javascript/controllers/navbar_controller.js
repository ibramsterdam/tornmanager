import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.preventSameRouteClick()
  }

  preventSameRouteClick() {
    const links = this.element.querySelectorAll('.navbar-link-active')
    links.forEach(link => {
      if (link.tagName === 'A') {
        link.addEventListener('click', (e) => {
          e.preventDefault()
        })
      }
    })
  }
}