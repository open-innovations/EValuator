const getParams = () => new URLSearchParams(window.location.search);
const serialseLatLng = ({lat, lng}) => [ lat, lng ].map(x => parseFloat(x.toFixed(6)));
const deserialiseLatLng = (s) => s?.split(',').map(x => parseFloat(x));

const VIEW_PARAM = 'view';
const ZOOM_PARAM = 'zoom';
const AREA_PARAM = 'area';
const MSOA_PARAM = 'msoa';

export const storeMapState = (map) => {
  const params = getParams();
  params.set(VIEW_PARAM, serialseLatLng(map.getCenter()));
  params.set(ZOOM_PARAM, map.getZoom());
  window.location.search = params;
}

export const getMapState = () => {
  const params = getParams();
  const view = deserialiseLatLng(params.get(VIEW_PARAM));
  const zoom = parseFloat(params.get(ZOOM_PARAM)) || 12;
  const area = params.get(AREA_PARAM);
  const msoa = params.get(MSOA_PARAM);
  return { view, zoom, area, msoa };
}

