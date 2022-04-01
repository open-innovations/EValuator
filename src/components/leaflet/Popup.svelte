<script>
  import L from 'leaflet';
  import { getContext } from 'svelte';
  let classNames = undefined;
  export { classNames as class };
  export let popup = undefined;
  let layer = getContext('layer')();
  
	function createPopup(popupElement) {
    popup = L.popup().setContent(popupElement);    
    layer.bindPopup(popup);
    return {
      destroy() {
        if (popup) {
          layer.unbindPopup();
          popup.remove();
          popup = undefined;
        }
      },
    };
  }
</script>

<div hidden>
  <div use:createPopup class={classNames}>
    <slot />
  </div>
</div>