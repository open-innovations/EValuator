<script>
  import { getContext, setContext } from 'svelte';
  import 'leaflet.markercluster';
  import L from 'leaflet';
  
  export let name;
  export let options = {};

  const layerGroup = getContext('layerGroup')();
  const control = getContext('control')();
  const markerCluster = L.markerClusterGroup(options);

  markerCluster.addTo(layerGroup);
  if (control && name) control.addOverlay(markerCluster, name);

  setContext('layerGroup', () => markerCluster);
  setContext('control', () => undefined);

  function initialise() {}
</script>

<div hidden>
  <div use:initialise>
    <slot></slot>
  </div>
</div>