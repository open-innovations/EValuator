<script>
  import L from '../../lib/vendor/leaflet';
  import { getContext, setContext } from 'svelte';

  export let marker = undefined;
  export let icon = undefined;

  export let latLng;

  const layerGroup = getContext('layerGroup')();

  setContext('layer', () => marker);

  function createMarker() {
    return {
      destroy() {
        if (marker) {
          marker.remove();
          marker = undefined;
        }
      },
    };
  }
  $: if (latLng) {
    if (marker) {
      marker.setLatLng(latLng);
    } else {
      marker = L.marker(latLng, { icon }).addTo(layerGroup);
    }
  }
</script>

<div class="hidden">
  <div use:createMarker>
    {#if marker}
      <slot />
    {/if}
  </div>
</div>
