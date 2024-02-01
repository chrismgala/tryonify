// @ts-check

/**
 * @typedef {import("../generated/api").RunInput} RunInput
 * @typedef {import("../generated/api").FunctionRunResult} FunctionRunResult
 */

/**
 * @param {RunInput} input
 * @returns {FunctionRunResult}
 */
export function run({ cart, validation }) {
  const trialCount = cart.lines.reduce((acc, { quantity }) => acc + quantity, 0);
  const errors = [];
  const max = validation?.metafield?.value;

  if (!max) return { errors };

  if (trialCount > max) {
    errors.push({
      localizedMessage: `You may only have ${max} active trials.`,
      target: "cart",
    });
  }

  return {
    errors
  }
};