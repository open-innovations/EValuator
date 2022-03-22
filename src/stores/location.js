import { writable } from 'svelte/store';
import { getMapState } from '../lib/location';

async function getAreaData(areaCode) {
  const prefix = `/data/areas/${areaCode}`; 
  const req = [
    fetch(`${prefix}/${areaCode}.geojson`).then(x => x.json()).catch(_ => ({})),
  ];
  const [ geojson ] = await Promise.all(req);
  return {
    geojson,
  };
}

function locationStore() {
  const { area, msoa } = getMapState();

  const { subscribe, set } = writable();

  async function update() {
    const areaData = await getAreaData(area);
    const feature = areaData.geojson.features.find(l => l.properties.msoa11cd === msoa);
    set({
      area: areaData,
      msoa: feature,
    });  
  }

  update();
  return { subscribe };
}

export const location = locationStore();
