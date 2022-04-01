import L from 'leaflet';

export const lightCarto = L.tileLayer('https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png', {
  attribution: '',
  zIndex: 650,
});
