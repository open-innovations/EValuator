import { writable } from 'svelte/store';
import L from '../lib/vendor/leaflet';
import { loadAppState, saveAppState } from '../lib/appState';

const { lat, lng, lock } = loadAppState(['lat', 'lng', 'lock']);

export const site = (() => {
  const { subscribe, set } = writable(L.latLng(lat, lng));
  let locked = lock === 'true';

  const saveSiteLocation = ({ lat, lng } = {}) => {
    if (!locked) saveAppState({ lat, lng })
  };
  
  const setLock = (status) => {
    locked = status;
    saveAppState({ lock: status });
  }
  
  const setLocation = (({ lat, lng }) => {
    if (!locked) set(L.latLng(lat, lng))
  });
  
  subscribe(saveSiteLocation);

  return {
    subscribe,
    set,
    setLocation,
    setLock,
  }
})();
