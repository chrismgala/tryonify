// @ts-check

/**
 * @typedef {import("../generated/api").RunInput} RunInput
 * @typedef {import("../generated/api").FunctionRunResult} FunctionRunResult
 */

/**
 * @param {RunInput} input
 * @returns {FunctionRunResult}
 */
export function run({ cart, shop, validation }) {
  const errors = [];
  const sellingPlans = shop?.metafield?.value;
  const max = validation?.metafield?.value;

  if (!sellingPlans || !max) return { errors };

  const sellingPlanArray = JSON.parse(sellingPlans);
  const trialCount = cart.lines.reduce((acc, { quantity, sellingPlanAllocation }) => {
    if (sellingPlanAllocation?.sellingPlan?.id) {
      if (sellingPlanArray.includes(sellingPlanAllocation.sellingPlan?.id)) acc += quantity;
    }
    return acc;
  }, 0);

  console.log(sellingPlanArray);

  if (trialCount > parseInt(max)) {
    errors.push({
      localizedMessage: `You may only have ${max} active trials.`,
      target: "cart",
    });
  }

  return {
    errors
  }
};