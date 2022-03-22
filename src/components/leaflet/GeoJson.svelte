<script>
  import L from 'leaflet';
  import { getContext, setContext } from 'svelte';
  
	let classNames = undefined;
  export { classNames as class };

	export let layer = undefined;
  export let style = undefined;

  export let feature = undefined;
 
	const layerGroup = getContext('layerGroup')();

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
      layer = L.geoJSON(feature).addTo(layerGroup);
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