<script>
  import L from 'leaflet';
  import { getContext, setContext } from 'svelte';
  
	let classNames = undefined;
  export { classNames as class };

	export let layer = undefined;
  export let style = undefined;
  export let filter = undefined;
  export let pointToLayer = undefined;

  export let feature = undefined;

  export let name = undefined;
 
	const layerGroup = getContext('layerGroup')();
  const control = getContext('control')();

  setContext('layer', () => layer);

  function createLayer() {
    return {
      destroy() {
        if (layer) {
          layer.remove();
          layer = undefined;
        }
      },
    };
  }
  
  $: if (feature) {
    if (layer) {
      // layer.setLatLng(latLng);
    } else {
      layer = L.geoJSON(feature, { filter, pointToLayer }).addTo(layerGroup);
      if (control) control.addOverlay(layer, name);
    }
  }
  $: if(style && layer) layer.setStyle(style);
</script>

<div class="hidden">
  <div use:createLayer class={classNames}>
		{#if layer}
	    <slot />
		{/if}
  </div>
</div>