import { writable } from 'svelte/store';
import L from '../lib/vendor/leaflet';
import { loadAppState, saveAppState } from '../lib/appState';

const { lat, lng, lock } = loadAppState(['lat', 'lng', 'lock']);

export const site = (() => {
  const { subscribe, set } = writable(L.latLng(lat, lng));
  let locked = lock === 'true';

  const saveSiteLocation = ({ lat, lng } = {}) => {
    if (!locked) saveAppState({ lat, lng });
  };
  
  const setLock = (status) => {
    locked = status;
    saveAppState({ lock: status });
  }

  const clear = () => {
    set(undefined);
    saveAppState({ lat: undefined, lng: undefined });
    setLock(false);
  }
  
  const setLocation = (({ lat, lng }) => {
    if (!locked) set(L.latLng(lat, lng));
    setLock(true);
  });
  
  subscribe(saveSiteLocation);

  return {
    clear,
    setLocation,
    setLock,
    subscribe,
  }
})();
