import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["returnButton", "keepButton", "quantity", "actions"]

  initialize() {
    this.elements = [];
  }

  add(event) {
    event.preventDefault();

    this.appendField("return_line_items[][fulfillment_line_item_id]", event.params.fulfillmentLineItemId);
    this.appendField("return_line_items[][quantity]", this.quantityTarget.value);

    this.returnButtonTarget.style.display = "none";
    this.keepButtonTarget.style.display = "inline-block";

    this.dispatch("add");
  }

  remove(event) {
    event.preventDefault()

    this.elements.forEach(element => element.remove());
    this.elements = [];

    this.returnButtonTarget.style.display = "inline-block";
    this.keepButtonTarget.style.display = "none";

    this.dispatch("remove");
  }

  appendField(name, value) {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;

    this.elements.push(input);
    this.actionsTarget.appendChild(input);
  }
}