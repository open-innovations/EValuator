import { prefixed } from './units';

[
  [100, '100'],
  [2000, '2k'],
  [5420000, '5.42M'],
  [6e9, '6G'],
  [5.6e12, '5.6T'],
].forEach(([input, output]) => it(`should return ${output} with the value if value is ${input}`, () => {
  expect(prefixed(input)).toBe(output);
})
)

it('should apply a unit if provided', () => {
  expect(prefixed(100, 'W')).toBe('100W');
  expect(prefixed(10000, 'W')).toBe('10kW');
})
