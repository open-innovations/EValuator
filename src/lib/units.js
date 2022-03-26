const prefix = ['', 'k', 'M', 'G', 'T'];

export const prefixed = (value, unit = '') => {
  if (!value) return 0 + unit;
  const exponent = Math.floor(Math.log10(value) / 3);
  return (value / (10 ** (3 * exponent))) + prefix[exponent] + unit;
}