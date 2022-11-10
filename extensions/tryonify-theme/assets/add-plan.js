(function () {
  const embed = document.querySelector('.tryonify-embed');
  const forms = document.querySelectorAll('form[action="/cart/add"]');
  const triggers = document.querySelectorAll('.tryonify-selling-plan-option');
  const sellingPlanInputs = getSellingPlanInputs();

  document.addEventListener('DOMContentLoaded', initialize);

  if (embed) {
    insertEmbed();
  }

  function insertEmbed() {
    embed.style = 'display:block;';
    if (embed.dataset.embedTarget) {
      const target = document.querySelector(embed.dataset.embedTarget);
      if (target) target.appendChild(embed);
    } else {
      forms.forEach((form) => {
        let productButton = form.querySelector('button[type="submit"]');
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

          if (embed && productButton) form.insertBefore(embed, productButton);
        }
      });
    }
  }

  function getSellingPlanInputs() {
    const inputs = [];

    forms.forEach((form) => {
      const sellingPlanInput = form.querySelector('input[name="selling_plan"]');

      if (sellingPlanInput) {
        inputs.push(sellingPlanInput);
      } else {
        const input = createInput();
        inputs.push(form.appendChild(input));
      }
    });

    return inputs;
  }

  function createInput() {
    const queryString = window.location.search;
    const params = new URLSearchParams(queryString);
    const selectedSellingPlan = params.get('selling_plan');
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = 'selling_plan';
    input.value = selectedSellingPlan || '';

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

  function addListeners() {
    triggers.forEach((trigger) => {
      trigger.addEventListener('change', handleChange);
    });
  }

  function setInitialValue() {
    triggers.forEach((trigger) => {
      if (trigger.checked) {
        sellingPlanInputs.forEach((sellingPlanInput) => {
          sellingPlanInput.value = trigger.value;
        });
      }
    });
  }

  function initialize() {
    addListeners();
    setInitialValue();
  }
}());
