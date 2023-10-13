import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector"]

  handleBlur(event) {
    if (event.currentTarget.value < event.currentTarget.dataset.min) {
      event.currentTarget.value = event.currentTarget.dataset.min;
    }

    if (event.currentTarget.value > event.currentTarget.dataset.max) {
      event.currentTarget.value = event.currentTarget.dataset.max;
    }
  }
}