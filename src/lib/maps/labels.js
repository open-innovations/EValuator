import { tileLayer } from 'leaflet';
export const lightCarto = tileLayer('https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png', {
  attribution: '',
  zIndex: 650,
});
