<script>
  import Tabbed from './Tabbed';
  import ModelInputs from './model/ModelInputs.svelte';
  import EnergyModel from './model/EnergyModel.svelte';

  import SlidersIcon from './icons/Sliders.svelte';
  import EnergyIcon from './icons/Energy.svelte';

  let params = {
    slow: 0,
    fast: 0,
    rapid: 0,
  };
</script>

<h1>EV Model</h1>

<p>Please note, these models are for illustrative purposes only.</p>

<Tabbed.Set name="modelSelection">
  <div class="main-content">
    <Tabbed.Content checked={true}>
      <div slot='tab-top'><h2>Model Inputs</h2><SlidersIcon></SlidersIcon></div>
      <ModelInputs slot="tab-content" bind:params />
    </Tabbed.Content>
    <Tabbed.Content>
      <div slot='tab-top'><h2>Energy Impact</h2><EnergyIcon></EnergyIcon></div>
      <EnergyModel slot="tab-content" {params} />
    </Tabbed.Content>
  </div>
</Tabbed.Set>

<style>
  h2 {
    /* background-color: #efefef; */
    text-align: center;
    margin: 0;
  }
  .main-content {
    background-color: #efefef;
    padding: 0.5em 1em;
  }
  [slot=tab-top] {
    display: flex;
    gap: 0.5em;
    padding: 0.5em;
  }
  [slot=tab-top] :global(svg) {
    height: 1em;
    /* height: 10em; */
    /* border: 1px solid black; */
  }
  h2 {
    flex-grow: 2;
  }
</style>
