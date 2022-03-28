<script>
  import Tabbed from './Tabbed';
  import ModelInputs from './model/ModelInputs.svelte';
  import EnergyModel from './model/EnergyModel.svelte';
  import CarbonModel from './model/CarbonModel.svelte';

  import WarningMessage from './WarningMessage.svelte';

  import SlidersIcon from './icons/Sliders.svelte';
  import EnergyIcon from './icons/Energy.svelte';
  import Co2Icon from './icons/Co2.svelte';

  let params = {};
</script>

<h1>EV Model</h1>

<WarningMessage>
  These models presented here are not yet validated, and <strong>must not be used for planning purposes</strong>.
  Please get in touch if you can help us improve or validate them.
</WarningMessage>

<Tabbed.Set name="modelSelection">
  <div class="main-content">
    <Tabbed.Content checked={true}>
      <div slot='tab-top'><h2>Model Inputs</h2><SlidersIcon></SlidersIcon></div>
      <ModelInputs slot="tab-content" bind:params />
    </Tabbed.Content>
    <Tabbed.Content>
      <div slot='tab-top'><h2>Network Demand</h2><EnergyIcon></EnergyIcon></div>
      <EnergyModel slot="tab-content" {params} />
    </Tabbed.Content>
    <Tabbed.Content>
      <div slot='tab-top'><h2>Carbon Abatement</h2><Co2Icon></Co2Icon></div>
      <CarbonModel slot="tab-content" {params} />
    </Tabbed.Content>
  </div>
</Tabbed.Set>

<style>
  h2 {
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
    /* height: 10em;
    border: 1px solid black; */
  }
  h2 {
    flex-grow: 2;
  }
</style>
