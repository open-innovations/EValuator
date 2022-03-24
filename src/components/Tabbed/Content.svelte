<script>
  import { getContext } from 'svelte';
  import { uuid } from '../../lib/uuid';
  const tabSet = getContext('tabSet');
  export let id = uuid();
  export let checked = false;
</script>

<div hidden>
  <label use:tabSet.register for={id}>
    <slot name="tab-top">Untitled tab</slot>
  </label>
</div>
<input type="radio" {id} name={tabSet.name} {checked} />
<div>
  <slot name="tab-content">No content</slot>
</div>

<style>
  div {
    display: none;
  }
  :checked + div {
    display: block;
  }
  input {
    display: none;
  }
  :global(.background [slot='tab-top']) {
    background: #d4dadc;
  }
</style>
