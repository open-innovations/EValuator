import { writable } from 'svelte/store';
import { getMapState } from '../lib/location';

async function getAreaData(areaCode) {
  const prefix = `data/areas/${areaCode}`;
  const req = [
    fetch(`${prefix}/${areaCode}.geojson`).then(x => x.json()).catch(_ => undefined),
    fetch(`${prefix}/${areaCode}-warehouse.geojson`).then(x => x.json()).catch(_ => undefined),
    fetch(`${prefix}/${areaCode}-distribution.geojson`).then(x => x.json()).catch(_ => undefined),
  ];
  const [geojson, warehouse, distribution, ...rest] = await Promise.all(req);
  return {
    geojson,
    warehouse,
    distribution,
  };
}

function locationStore() {
  const { area, msoa } = getMapState();

  const { subscribe, set } = writable();

  async function update() {
    const areaData = await getAreaData(area);
    const feature = areaData.geojson.features.find(l => l.properties.msoa11cd === msoa);
    set({
      ...areaData,
      area: areaData,
      msoa: feature,
    });
  }

  update();
  return { subscribe };
}

export const location = locationStore();
