<script>
  import { setContext } from 'svelte';
  export let name;
  let titles = [];
  let current = 0;
  setContext('tabSet', { name, register: (t) => { titles.push(t); titles = titles; } });
  function addTabTop(node, titleNode) {
    node.appendChild(titleNode);
  }
</script>
<div>
  <div class='tabs'>
    {#each titles as title, i}
      <div class:background={ i !== current } use:addTabTop={ title } on:click={() => current = i }></div>
    {/each}
  </div>
  <slot></slot>
</div>

<style>
  .tabs {
    display: flex;
    gap: 4px;
  }
</style>