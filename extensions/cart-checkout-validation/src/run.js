// @ts-check

/**
 * @typedef {import("../generated/api").RunInput} RunInput
 * @typedef {import("../generated/api").FunctionRunResult} FunctionRunResult
 */

/**
 * @param {RunInput} input
 * @returns {FunctionRunResult}
 */
export function run({ cart, shop }) {
  const errors = [];
  const sellingPlans = shop?.sellingPlans?.value;
  const max = shop?.maxTrialItems?.value;

  if (!sellingPlans || !max) return { errors };

  const sellingPlanArray = JSON.parse(sellingPlans);
  const trialCount = cart.lines.reduce((acc, { quantity, sellingPlanAllocation }) => {
    if (sellingPlanAllocation?.sellingPlan?.id) {
      if (sellingPlanArray.includes(sellingPlanAllocation.sellingPlan?.id)) acc += quantity;
    }
    return acc;
  }, 0);

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