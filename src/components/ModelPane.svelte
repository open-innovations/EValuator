<script>
  import Tabbed from './Tabbed';

  export let inputs;
  export let models = []
  export let params;
</script>
<h1>EV Model</h1>

<p>
  Please note, these models are for illustrative purposes only.
</p>
<Tabbed.Set name='modelSelection'>
  <Tabbed.Content checked={ true }>
    <h2 slot='tab-top'>Model Inputs</h2>
    <div slot='tab-content' class='main-content'>
      <svelte:component this={ inputs } bind:params></svelte:component>
    </div>
  </Tabbed.Content>
  {#each models as model}
    <Tabbed.Content>
      <h2 slot='tab-top'>Model</h2>
      <div slot='tab-content' class='main-content'>
        <svelte:component this={ model } { params }></svelte:component>
      </div>
    </Tabbed.Content>
  {/each}
</Tabbed.Set>

<style>
  h2 {
    background-color: #efefef;
    padding: 0.5em;
    text-align: center;
    margin: 0;
  }
  .main-content {
    background-color: #efefef;
    padding: 0.5em 1em;
  }
</style>
