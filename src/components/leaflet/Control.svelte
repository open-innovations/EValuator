<script>
  import { getContext, setContext } from 'svelte';
  import L from 'leaflet';

  export let options = {}
  const control = L.control.layers({}, {}, options)
  setContext('control', () => control);

  const map = getContext('map')();

  function createControl() {}
  map.addControl(control);
</script>

<div hidden>
  <div use:createControl>
    <slot />
  </div>
</div>