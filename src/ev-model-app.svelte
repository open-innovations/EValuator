<script>
  import Leaflet from './components/leaflet/Leaflet.svelte';
  import Marker from './components/leaflet/Marker.svelte';
  import GeoJson from './components/leaflet/GeoJson.svelte'; 

  import ModelPane from './components/ModelPane.svelte';
  
  import { location } from './stores/location';

  import L from './lib/vendor/leaflet';

  import { uk } from './lib/maps/bounds';
  import { greyscale } from './lib/maps/basemaps';
  import { lightCarto } from './lib/maps/labels';
  import * as style from './lib/maps/styles';
  import { pin } from './lib/maps/icons';
  import { saveAppState, loadAppState } from './lib/appState';

  let bounds = uk;

  // Map state
  let map;
  let msoaOutline;

  $: if (msoaOutline) map.fitBounds(msoaOutline.getBounds());

  const mapClick = e => {
    site = e.latlng;
    site.lat = parseFloat(site.lat.toFixed(5));
    site.lng = parseFloat(site.lng.toFixed(5));
  };

  let site = undefined;
  function initSite() {
    const { lat, lng } = loadAppState(['lat', 'lng']);
    return L.latLng(lat, lng);
  }
  site = initSite();

  const saveSiteLocation = ({ lat, lng } = {}) => saveAppState({ lat, lng });
  $: saveSiteLocation(site);
</script>

<h1>EValuator - EV Bulk Charging Planner Model</h1>
<p>{ $location?.msoa.properties.msoa11hclnm }</p>
<section id='map' class="screen">
  <Leaflet bind:map { bounds } baseLayer={ greyscale } labelLayer={ lightCarto } clickHandler={ mapClick }>
    <Marker bind:latLng={ site } icon={ pin }></Marker>
    <GeoJson feature={ $location?.msoa } bind:layer={ msoaOutline } style={ style.msoaFocus }></GeoJson>
    <GeoJson feature={ $location?.warehouse } style={ style.distribution }></GeoJson>
    <GeoJson feature={ $location?.distribution } style={ style.distribution }></GeoJson>
  </Leaflet>
</section>

<ModelPane></ModelPane>
