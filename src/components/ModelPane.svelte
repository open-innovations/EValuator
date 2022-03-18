<script>
  export let inputs;
  export let models = []
  let params;
</script>
<h1>EV Model</h1>

<svelte:component this={ inputs } bind:params></svelte:component>

{#each models as model}
  <svelte:component this={ model } { params }></svelte:component>
{/each}
