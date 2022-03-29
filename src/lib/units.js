const prefix = ['', 'k', 'M', 'G', 'T'];

const GRAMS = 'g';
const gramsUnits = ['g', 'kg', ' tons']

const gramPrefixed = (value) => {
  if (value < 100) return value.toFixed(1) + gramsUnits[0];
  if (value < 1e5) return (value / 1000).toFixed(1) + gramsUnits[1];
  return Math.floor(value / 1e6) + gramsUnits[2];
}

export const prefixed = (value, unit = '') => {
  if (!value) return 0 + unit;
  if (unit == GRAMS) return gramPrefixed(value);
  const exponent = Math.floor(Math.log10(value) / 3);
  return (value / (10 ** (3 * exponent))) + prefix[exponent] + unit;
}