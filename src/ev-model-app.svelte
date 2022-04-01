<script>
  import Leaflet from './components/leaflet/Leaflet.svelte';
  import Marker from './components/leaflet/Marker.svelte';
  import GeoJson from './components/leaflet/GeoJson.svelte'; 
  import Popup from './components/leaflet/Popup.svelte';
  import Control from './components/leaflet/Control.svelte';
  import ChargepointLayer from './components/ChargepointLayer.svelte';

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

  import './leaflet.css';

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

  const layerName = (key) => {
    const n = key.replace(/^\w/, c => c.toUpperCase())
    const l = style[key]();
    return `<svg viewBox="-2 -2 14 14" class="key-code" stroke="${l.color}" fill="${ l.color }">
      <rect width=10 height=10></rect>
    </svg> ${ n }`;
  }
</script>

<h1>Stage 2: Modelling</h1>
{#await Promise.resolve(location.loading) }
  <p>
    Please wait while we load the data for MSOA { location.params.msoa }.
  </p>
{:then} 
  <p>{ $location?.msoa.properties.msoa11hclnm }</p>
  <div id='map' class="screen">
    <Leaflet bind:map { bounds } baseLayer={ greyscale } labelLayer={ lightCarto } clickHandler={ mapClick }>
      <GeoJson feature={ $location?.msoa } bind:layer={ msoaOutline } style={ style.msoaFocus }></GeoJson>
      <Control>
        {#each ['parking', 'supermarket', 'distribution', 'warehouse'] as layer }
          {#if $location }
            <GeoJson feature={ $location[layer] } style={ style[layer] } { filter } name={ layerName(layer) }></GeoJson>
          {/if}
        {/each}
        <ChargepointLayer></ChargepointLayer>
      </Control>
      <Marker latLng={ $site } icon={ pin }>
        <Popup>
          <Location></Location>
        </Popup>
      </Marker>
    </Leaflet>
  </div>

  <ModelPane></ModelPane>

  <Attributions></Attributions>
{:catch}
  <p>
    It looks like you've come to this page without first selecing an Area to focus on.  
  </p>
  <p>
    Please <a href="ranking.html">return to the Ranking stage</a> to pick an area of focus.
  </p>
{/await}

<style>
  :global(.key-code) {
    width: 2em;
    vertical-align: bottom;
    fill-opacity: 0.2;
    stroke-width: 1.5;
  }
</style>