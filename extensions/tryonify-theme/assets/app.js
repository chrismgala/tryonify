(function () {
  const config = {
    cart: null,
    trialLineItemKeys: [],
    trialLineItemIndex: [],
    trialLineItemId: [],
  };

  const watchedEndpoints = [
    '/cart/change',
    '/cart/update',
    '/cart/add',
  ]

  document.addEventListener('DOMContentLoaded', initialize);

  async function fetchCart() {
    const resp = await fetch('/cart.js');
    return await resp.json();
  }

  function findTrialLineItems() {
    return config.cart?.items.forEach((item, index) => {
      if (item.selling_plan_allocation) {
        config.trialLineItemKeys.push(item.key);
        config.trialLineItemIndex.push(index);
        config.trialLineItemId.push(item.id);
      }
    });
  }

  function getTrialQuantity() {
    return config.cart?.items.reduce((acc, item, index) => {
      if (item.selling_plan_allocation) {
        acc = acc + item.quantity;
      }
      return acc;
    }, 0);
  }

  function disableTrialOptions(isDisabled) {
    const trialOptions = document.querySelectorAll('.tryonify-selling-plan:not(.tryonify-selling-plan--default)');

    if (trialOptions.length > 0) {
      trialOptions.forEach(option => {
        const input = option.querySelector('input.tryonify-selling-plan-option');

        if (isDisabled) {
          const defaultOption = document.querySelector('.tryonify-selling-plan--default input.tryonify-selling-plan-option');
          defaultOption.checked = true;

          option.classList.add('tryonify-selling-plan--disabled');
        } else {
          option.classList.remove('tryonify-selling-plan--disabled');
        }

        input.disabled = isDisabled;
      });
    }
  }

  async function setup() {
    config.cart = await fetchCart();
    config.trialLineItemKeys = findTrialLineItems();
    config.trialQuantity = getTrialQuantity();

    if (config.trialQuantity >= window.tryonify.maxTrialItems) {
      disableTrialOptions(true)
    } else {
      disableTrialOptions(false)
    }
  }

  function getPayload(body) {
    if (body instanceof FormData) {
      return Object.fromEntries(body.entries());
    } else {
      return JSON.parse(body);
    }
  }

  function validCartUpdate(args) {
    const [resource, options] = args;

    if (!options.body) return true;

    // Handle checkout form submit
    if (resource === '/cart') {
      return handleCheckout(options.body);
    }

    const payload = getPayload(options.body);

    if (resource.includes('/cart/change')) {
      return handleChangeEndpoint(payload);
    }

    if (resource.includes('/cart/update')) {
      return handleUpdateEndpoint(payload);
    }

    if (resource.includes('/cart/add')) {
      return handleAddEndpoint(payload);
    }

    return true
  }

  function handleChangeEndpoint(payload) {
    let item;

    // Return true if removing selling plan
    if (payload.hasOwnProperty('selling_plan') && payload.selling_plan === null) return true;

    // Using ID key
    if (payload.id) {
      if (typeof payload.id === 'string') {
        if (!config.trialLineItemKeys.includes(payload.id) && !payload.selling_plan) return true;
        item = config.cart.items.find(item => item.key === payload.id);
      } else {
        const trialIds = Object.keys(config.trialLineItemKeys).map(key => config.trialLineItemKeys[key].id);
        if (!trialIds.includes(payload.id) && !payload.selling_plan) return true;
        item = config.cart.items.find(item => item.id === payload.id);
      }
    }

    // Using line key
    if (payload.line) {
      item = config.cart.items[payload.line - 1];
    }

    if (item) {
      const quantityDifference = parseInt(payload.quantity) - parseInt(item.quantity);
      return (config.trialQuantity + quantityDifference) <= window.tryonify.maxTrialItems;
    } else {
      return true;
    }
  }

  function handleUpdateEndpoint(payload) {
    if (Array.isArray(payload.updates)) {
      const trialLineItemIndex = Object.keys(config.trialLineItemKeys).map(key => config.trialLineItemKeys[key].index);
      const updatedTrialQuantity = payload.updates.reduce((acc, value, index) => {
        if (trialLineItemIndex.includes(index)) {
          acc += parseInt(value);
        }

        return acc;
      }, 0);

      return updatedTrialQuantity <= window.tryonify.maxTrialItems;
    } else {
      const updatedTrialQuantity = Object.keys(payload.updates).reduce(key => {
        const trialKeys = Object.keys(config.trialLineItemKeys);
        const trialIds = Object.keys(config.trialLineItemKeys).map(item => item.id);
        let id = parseInt(key);

        if (id) {
          if (trialIds.includes(id)) {
            acc += parseInt(payload.updates[key]);
          }
        } else {
          if (trialKeys.includes(key)) {
            acc += parseInt(payload.updates[key]);
          }
        }

        return acc;
      }, 0);

      return updatedTrialQuantity <= window.tryonify.maxTrialItems;
    }
  }

  function handleAddEndpoint(payload) {
    let sellingPlanQuantity;

    if (payload.item) {
      sellingPlanQuantity = payload.items.reduce((acc, value) => {
        if (value.sell_plan) {
          acc += value.quantity;
        }

        return acc;
      }, 0);
    }

    if (payload.selling_plan) {
      sellingPlanQuantity = payload.quantity;
    } else {
      return true;
    }

    return (parseInt(sellingPlanQuantity) + config.trialQuantity) <= window.tryonify.maxTrialItems;
  }

  function handleCheckout(payload) {
    const trialItemIndex = Object.keys(config.trialLineItemKeys).map(key => config.trialLineItemKeys[key].index);
    let i = 0;
    let sellingPlanQuantity = 0;

    for (const entry of payload.entries()) {
      if (trialItemIndex.includes(i)) {
        sellingPlanQuantity += parseInt(entry[1]);
      }
      i++;
    }

    return sellingPlanQuantity <= window.tryonify.maxTrialItems;
  }

  function isWatchedEndpoint(endpoint) {
    return watchedEndpoints.includes(endpoint)
  }

  function showAlert() {
    const alertEl = document.querySelector('.tryonify-alert');
    alertEl.classList.add('open');

    window.setTimeout(() => {
      alertEl.classList.remove('open')
    }, 5000);
  }

  function interceptFetch() {
    const { fetch: originalFetch } = window;

    window.fetch = async (...args) => {
      let [resource, options] = args;

      if (isWatchedEndpoint(resource) && !validCartUpdate(args)) {
        showAlert();
        throw new Error(`Only ${window.tryonify.maxTrialItems} trial products allowed`);
      }

      const response = await originalFetch(resource, options);

      if (isWatchedEndpoint(resource)) {
        await setup();
      }

      return response;
    };
  }

  function interceptFormSubmit() {
    document.addEventListener('submit', (event) => {
      if (event.target.action === `https://${window.location.host}/cart`) {
        const formData = new FormData(event.target);
        if (!validCartUpdate(['/cart', { body: formData }])) {
          event.preventDefault();
          showAlert();
          throw new Error(`Only ${window.tryonify.maxTrialItems} trial products allowed`)
        }
      }
    });
  }

  async function initialize() {
    interceptFetch();
    interceptFormSubmit();

    await setup();
  }
})();