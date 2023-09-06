(function () {
  const embed = document.querySelector('.tryonify-embed');
  const forms = document.querySelectorAll('form[action*="/cart/add"]:not(.installment)');
  let triggers;
  let addToCartButtons

  const sellingPlanInputs = getSellingPlanInputs();

  document.addEventListener('DOMContentLoaded', initialize);

  function insertEmbed() {
    if (embed.dataset.embedTarget) {
      const targets = document.querySelectorAll(embed.dataset.embedTarget);

      if (targets.length === 1) {
        targets.forEach(target => {
          let clonedEmbed = embed.cloneNode(true);
          clonedEmbed.style = 'display:block;';
          target.appendChild(clonedEmbed);
        });
      } else if (targets.length > 1) {
        targets.forEach(target => {
          const form = target.closest('form[action="/cart/add"]:not(.installment)');

          if (!form) return;

          let clonedEmbed = embed.cloneNode(true);
          clonedEmbed.style = 'display:block;';
          target.appendChild(clonedEmbed);
        });
      }
    } else {
      forms.forEach((form) => {
        let productButton = form.querySelector('input[type="submit"],button[type="submit"]');
        let retry = 3;
        let isParent = false;

        if (productButton) {
          while (!isParent && retry > 0) {
            const parentEl = productButton.parentElement;

            if (parentEl === form) {
              isParent = true;
            } else {
              productButton = parentEl;
              retry -= 1;
            }
          }
          const clonedEmbed = embed.cloneNode(true);
          clonedEmbed.style = 'display:block;';
          if (clonedEmbed && productButton) form.insertBefore(clonedEmbed, productButton);
        }
      });
      embed.remove();
    }
  }

  function getSellingPlanInputs() {
    const inputs = [];

    forms.forEach((form) => {
      const sellingPlanInput = form.querySelector('input[name="selling_plan"]');
      const idInput = form.querySelector('[name="id"]');

      if (!idInput) return;

      const value = idInput.nodeName === 'SELECT' ? idInput.options[idInput.selectedIndex].value : idInput.value;

      if (sellingPlanInput) {
        sellingPlanInput.dataset.variantId = value;
        inputs.push(sellingPlanInput);
      } else {
        const input = createInput();
        input.dataset.variantId = value;
        inputs.push(form.appendChild(input));
      }
    });

    return inputs;
  }

  async function handleVariantChange(e) {
    const price = document.querySelector('.tryonify-buy-now-price');

    const response = await fetch(window.location.origin + window.location.pathname + '.json')

    if (response.ok) {
      const json = await response.json();
      const variant = json?.product?.variants.find(variant => variant.id === parseInt(e.target.value));

      if (variant && price) {
        price.innerHTML = new Intl.NumberFormat('default', { style: 'currency', currency: window.Shopify.currency.active }).format(variant.price);
      }
    }
  }

  function createInput() {
    const queryString = window.location.search;
    const params = new URLSearchParams(queryString);
    const selectedSellingPlan = params.get('selling_plan');
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'selling_plan';
    input.value = selectedSellingPlan || '';
    input.classList.add('tryonify-selling-plan-input');

    return input;
  }

  function handleChange(e) {
    const checkbox = e.target;
    if (checkbox.checked) {
      sellingPlanInputs.forEach((sellingPlanInput) => {
        sellingPlanInput.value = checkbox.value;
      });
    } else {
      sellingPlanInputs.forEach((sellingPlanInput) => {
        sellingPlanInput.value = '';
      });
    }
  }

  function handleAddToCart(e) {
    e.preventDefault();

    let form = e.target.closest('form');

    if (!form) {
      form = document.querySelector('form[action~="/cart/add"]:not(.installment)');
    }

    if (form) {
      const sellingPlan = form.querySelector('input[name="selling_plan"]');
      const idInput = form.querySelector('[name="id"]');

      if (!sellingPlan || !idInput) return;
      sellingPlan.value = e.currentTarget.dataset.sellingPlanId;

      const submitButton = form.querySelector('[type="submit"]');

      if (submitButton) {
        submitButton.click();
      } else {
        form.submit();
      }

      // Clear selling plan input if button is clicked
      if (e.currentTarget.nodeName === 'BUTTON') {
        window.setTimeout(() => sellingPlan.value = '', 1000);
      }
    }
  }

  function initialize() {
    if (embed) {
      insertEmbed();
    }

    triggers = document.querySelectorAll('.tryonify-selling-plan-option');
    addToCartButtons = document.querySelectorAll('.tryonify-add-to-cart');

    forms.forEach((form) => {
      const idInput = form.querySelector('[name="id"]');
      if (!idInput) return;
      idInput.addEventListener('change', handleVariantChange)
    })

    triggers.forEach((trigger) => {
      trigger.addEventListener('change', handleChange);

      if (trigger.checked) {
        handleChange({ target: trigger });
      }
    });

    if (addToCartButtons.length > 0) {
      addToCartButtons.forEach(button => {
        button.addEventListener('click', handleAddToCart);
      });
    }
  }
}());
