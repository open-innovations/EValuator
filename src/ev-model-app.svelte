<script>
  import Leaflet from './components/leaflet/Leaflet.svelte';
  import Marker from './components/leaflet/Marker.svelte';
  import GeoJson from './components/leaflet/GeoJson.svelte'; 

  import ModelPane from './components/ModelPane.svelte';
  
  import { location } from './stores/location';

  import { uk } from './lib/maps/bounds';
  import { greyscale } from './lib/maps/basemaps';
  import { lightCarto } from './lib/maps/labels';
  import * as style from './lib/maps/styles';
  import { pin } from './lib/maps/icons';

  let bounds = uk;

  // Map state
  let map;
  let msoaOutline;

  $: if (msoaOutline) map.fitBounds(msoaOutline.getBounds());

  const mapClick = e => site = e.latlng;

  let site = undefined;
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
