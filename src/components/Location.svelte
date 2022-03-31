<script>
  import { site } from '../stores/site';
  import { loadAppState } from '../lib/appState';

  let locked = loadAppState(['lock']).lock === 'true';
  $: site.setLock(locked);
</script>

<h3>
  Site
</h3>
<p>
  Location: {$site?.lat}, {$site?.lng}
</p>
<div class='controls'>
  <button on:click={() => (locked = !locked)}>
    {#if locked}
      Unlock
    {:else}
      Lock
    {/if}
  </button>
  <button on:click={site.clear}>
    Clear
  </button>
</div>

<style>
  .controls {
    display: flex;
    gap: 1em;
  }
  button {
    background-color: #d4dadc;
    vertical-align: unset;
    width: 100%;
  }
  button:hover {
    background-color: hsl(195, 10%, 75%);
  }
</style>
