<script>
  import { saveAppState, loadAppState } from '../../lib/appState';
  import { site } from '../../stores/site';

  const defaults = {
    chargepoints: 0,
    slow: 0,
    fast: 0,
    rapid: 0,
    ultraRapid: 0,
  };
  export let params = defaults;

  const appState = loadAppState(Object.keys(defaults));
  params = { ...defaults, ...appState, ...params };

  $: {
    params.fast = params.chargepoints - params.slow - params.rapid - params.ultraRapid;
    params = params;
  }

  let locked = loadAppState(['lock']).lock === 'true';

  $: saveAppState(params);
  $: site.setLock(locked);
</script>

<p>
  Use this pane to enter the details of the plan.
  This will be provided to the individual models which can be accessed in the subsequent tabs.
</p>

<div class='grid'>
  <p>
    {#if $site?.lat && $site?.lng }
      Site location: { $site?.lat }, { $site?.lng }
    {:else}
      Click on the map to select a site.
    {/if}
  
  </p>
  <p>
    Lock site: 
    <button on:click={ () => locked = !locked }>
      {#if locked }
        Unlock
      {:else}
        Lock
      {/if}
    </button>
  </p>
</div>

<div>
  <label for='chargepoints'>Total Electric Vehicle Chargepoints</label>
  <input id='chargepoints' type='number' bind:value={ params.chargepoints } min=0 />
</div>
<h3>Chargepoint breakdown</h3>
<p>All chargepoints are assumed to be <strong>Fast</strong> unless otherwise stated.</p>
<div>
  <label for='slow'>Slow</label>
  <input id='slow' type='number' bind:value={ params.slow } min=0 max={ params.chargepoints } />
  <label for='fast'>Fast</label>
  <input id='fast' disabled bind:value={ params.fast } min=0 />  
  <label for='rapid'>Rapid</label>
  <input id='rapid' type='number' bind:value={ params.rapid } min=0 max={ params.chargepoints } />  
  <label for='ultra-rapid'>Ultra-Rapid</label>
  <input id='ultra-rapid' type='number' bind:value={ params.ultraRapid } min=0 max={ params.chargepoints } />  
</div>
<style>
  div {
    display: flex;
    gap: 1em;
    align-items: center;
  }
  label {
    flex-grow: 1;
  }
  input {
    text-align: right;
    width: 6em;
  }
  button {
    background-color: #d4dadc;
    vertical-align: unset;
  }
  button:hover {
    background-color: hsl(195, 10%, 75%);
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
  }
</style>
