import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["returnButton", "keepButton", "quantity"]

  initialize() {
    this.returnItem = null;
  }

  add(event) {
    event.preventDefault();

    this.returnItem = {
      ...event.params,
      quantity: this.quantityTarget.value,
    }

    this.dispatch("add", { detail: this.returnItem });

    this.returnButtonTarget.style.display = "none";
    this.keepButtonTarget.style.display = "inline-block";
  }

  remove(event) {
    event.preventDefault()

    this.returnItem = null;

    this.dispatch("remove");

    this.returnButtonTarget.style.display = "inline-block";
    this.keepButtonTarget.style.display = "none";
  }
}