import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { orderId: String }
  static outlets = ["return-line-item"]
  static targets = ["returnReason", "customerNote", "submitButton"]

  connect() {
    this.toggleSubmitDisable();
  }

  toggleSubmitDisable() {
    const hasReturnLineItems = this.returnLineItemOutlets.filter(returnLineItem => returnLineItem.elements.length > 0).length > 0;
    this.submitButtonTarget.disabled = !hasReturnLineItems;
  }
}