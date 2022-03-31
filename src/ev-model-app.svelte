<script>
  import Leaflet from './components/leaflet/Leaflet.svelte';
  import Marker from './components/leaflet/Marker.svelte';
  import GeoJson from './components/leaflet/GeoJson.svelte'; 
  import Popup from './components/leaflet/Popup.svelte';

  import ModelPane from './components/ModelPane.svelte';
  import Attributions from './components/Attributions.svelte';
  import Location from './components/Location.svelte';
  
  import { location } from './stores/location';

  import { uk } from './lib/maps/bounds';
  import { greyscale } from './lib/maps/basemaps';
  import { lightCarto } from './lib/maps/labels';
  import * as style from './lib/maps/styles';
  import { pin } from './lib/maps/icons';
  import { site } from './stores/site';

  let bounds = uk;

  // Map state
  let map;
  let msoaOutline;

  $: if (msoaOutline) map.fitBounds(msoaOutline.getBounds());

  const mapClick = ({latlng}) => {
    latlng.lat = parseFloat(latlng.lat.toFixed(5));
    latlng.lng = parseFloat(latlng.lng.toFixed(5));
    site.setLocation(latlng);
  };

  const filter = (feature) => !(feature.geometry.type === 'Point');
</script>

<h1>Stage 2: Modelling</h1>
<p>{ $location?.msoa.properties.msoa11hclnm }</p>
<div id='map' class="screen">
  <Leaflet bind:map { bounds } baseLayer={ greyscale } labelLayer={ lightCarto } clickHandler={ mapClick }>
    <Marker latLng={ $site } icon={ pin }>
      <Popup>
        <Location></Location>
      </Popup>
    </Marker>
    <GeoJson feature={ $location?.msoa } bind:layer={ msoaOutline } style={ style.msoaFocus }></GeoJson>
    <GeoJson feature={ $location?.parking } style={ style.parking } { filter }></GeoJson>
    <GeoJson feature={ $location?.supermarket } style={ style.supermarket } { filter }></GeoJson>
    <GeoJson feature={ $location?.distribution } style={ style.distribution } { filter }></GeoJson>
    <GeoJson feature={ $location?.warehouse } style={ style.warehouse } { filter }></GeoJson>
  </Leaflet>
</div>

<ModelPane></ModelPane>

<Attributions></Attributions>