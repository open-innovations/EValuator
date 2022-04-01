<script>
  import { createEventDispatcher, setContext } from 'svelte';
  import L from 'leaflet';
  import 'leaflet/dist/leaflet.css';
  
  export let baseLayer;
  export let labelLayer = undefined;
  
	// Must set either bounds, or view and zoom.
  export let bounds = undefined;
	export let view = undefined;
	export let zoom = undefined;
  export let clickHandler = () => {};

  let mapProp = undefined;
  export { mapProp as map };

	export const invalidateSize = () => map?.invalidateSize();
  
	const dispatch = createEventDispatcher();

	let map;
  $: mapProp = map;
	
  export const getMap = () => map;
  setContext('layerGroup', getMap);
  setContext('layer', getMap);
  setContext('map', getMap);
  setContext('control', () => undefined);

  function createLeaflet(node) {
    map = L.map(node).on('zoom', (e) => dispatch('zoom', e));
    map.on('click', clickHandler);

    baseLayer.addTo(map);
    labelLayer?.addTo(map);
		
    return {
      destroy() {
        map.remove();
        map = undefined;
      },
    };
  }
	
	$: if(map) {
		if(bounds) {
      map.fitBounds(bounds)
		} else {
			map.setView(view, zoom);
		}
	}
</script> 

<style>
  :global(.leaflet-control-container) {
    position: static;
  }

  div {
    height: 100%;
    width: 100%;
  }
</style>

<div use:createLeaflet>
  {#if map}
    <slot {map} />
  {/if}
</div>