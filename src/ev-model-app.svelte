<script>
  import Key from './components/Key.svelte';
  import Leaflet from './components/Leaflet.svelte';
  import Sources from './components/Sources.svelte';
  import Popup from './components/Popup.svelte';
  import Marker from './components/Marker.svelte';
  import ModelPane from './components/ModelPane.svelte';

  import { uk } from './lib/maps/bounds';
  import { greyscale } from './lib/maps/basemaps';
  import { lightCarto } from './lib/maps/labels';

  import ModelInputs from './components/model/ModelInputs.svelte';
  import EnergyModel from './components/model/EnergyModel.svelte';

  const models = [ EnergyModel ];

  let map;

  const mapClick = e => location = e.latlng;

  let location = undefined;
  let modelParams = {
    slow: 0,
    fast: 0,
    rapid: 0,
  };
</script>


<h1>EValuator - EV Bulk Charging Planner Model</h1>
<section id='map' class="screen">
  <Leaflet bind:map bounds={uk} baseLayer={ greyscale } labelLayer={ lightCarto } clickHandler={ mapClick }>
    <Marker bind:latLng={ location }>
      <Popup>
        <ModelPane inputs={ ModelInputs } { models } bind:params={ modelParams }></ModelPane>
      </Popup>
    </Marker>
  </Leaflet>
</section>

<Key></Key>
<Sources></Sources>
