<script>
  import L from 'leaflet';
  import { getContext, setContext } from 'svelte';

  export let marker = undefined;
  export let icon = undefined;

  export let latLng;

  const layerGroup = getContext('layerGroup')();

  setContext('layer', () => marker);

  const destroy = () => {
    if (marker) {
      marker.remove();
      marker = undefined;
    }
  };

  function createMarker() {
    return {
      destroy,
    };
  }
  $: if (latLng && marker) {
      marker.setLatLng(latLng);
    } else if (latLng) {
      marker = L.marker(latLng, { icon }).addTo(layerGroup);
    } else if (marker) {
      destroy();
    }
</script>

<div class="hidden">
  <div use:createMarker>
    {#if marker}
      <slot />
    {/if}
  </div>
</div>
