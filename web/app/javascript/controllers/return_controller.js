import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { orderId: String }
  static outlets = ["return-line-item"]
  static targets = ["returnReason", "returnReasonNote", "submitButton"]

  connect() {
    this.toggleSubmitDisable();
  }

  toggleSubmitDisable() {
    const hasReturnLineItems = this.returnLineItemOutlets.filter(returnLineItem => returnLineItem.returnItem).length > 0;
    this.submitButtonTarget.disabled = !hasReturnLineItems;
  }

  async submit(event) {
    event.preventDefault();

    this.submitButtonTarget.disabled = true;

    const returnLineItems = this.returnLineItemOutlets.map(returnLineItem => returnLineItem.returnItem);

    try {
      const resp = await fetch('/a/trial/returns', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          orderId: this.orderIdValue,
          returnLineItems: returnLineItems,
          returnReason: this.returnReasonTarget.value,
          returnReasonNote: this.returnReasonNoteTarget.value,
        })
      })
    } catch (err) {
      console.log(err)
    }
  }
}