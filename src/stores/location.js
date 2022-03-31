import { writable } from 'svelte/store';
import { getMapState } from '../lib/location';

function tryToConvertToNumber(x) {
  let value = parseFloat(x);
  if (isNaN(value)) return x;
  return value;
}

function parseCsv(text) {
  const [heading, ...data] = text.split('\n').map(r => r.split(/\"{0,1},\"{0,1}/));
  return data.map(row => {
    return heading.reduce((a, k, i) => ({ ...a, [k]: tryToConvertToNumber(row[i]) }), {})
  });
}

async function getAreaData(areaCode) {
  const prefix = `data/areas/${areaCode}`;
  const req = [
    fetch(`${prefix}/${areaCode}.geojson`).then(x => x.json()).catch(_ => undefined),
    fetch(`${prefix}/${areaCode}-warehouse.geojson`).then(x => x.json()).catch(_ => undefined),
    fetch(`${prefix}/${areaCode}-distribution.geojson`).then(x => x.json()).catch(_ => undefined),
    fetch(`${prefix}/${areaCode}-parking.geojson`).then(x => x.json()).catch(_ => undefined),
    fetch(`${prefix}/${areaCode}-supermarket.geojson`).then(x => x.json()).catch(_ => undefined),
    fetch(`${prefix}/${areaCode}.csv`).then(x => x.text()).then(parseCsv).catch(_ => undefined),
  ];
  const [geojson, warehouse, distribution, parking, supermarket, layerData] = await Promise.all(req);
  return {
    geojson,
    warehouse,
    distribution,
    parking,
    supermarket,
    layerData,
  };
}

function locationStore() {
  const { area, msoa } = getMapState();

  const { subscribe, set } = writable();

  async function update() {
    const areaData = await getAreaData(area);
    const feature = areaData.geojson.features.find(l => l.properties.msoa11cd === msoa);
    const msoaData = areaData.layerData.find(l => l.MSOA === msoa);
    set({
      ...areaData,
      area: areaData,
      msoa: feature,
      msoaData,
    });
  }

  update();
  return { subscribe };
}

export const location = locationStore();
