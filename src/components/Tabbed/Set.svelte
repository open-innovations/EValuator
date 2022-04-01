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
      <div class='tab-top' class:active={ i === current } use:addTabTop={ title } on:click={() => current = i }></div>
    {/each}
  </div>
  <slot></slot>
</div>

<style>
  .tabs {
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
    justify-content: space-between;
  }
  .tab-top {
    font-size: 1.5em;
    flex-grow: 1;
  }
  .tab-top :global(*) {
    font-size: inherit;
  }
  .tab-top :global([slot='tab-top']) {
    background-color: #d4dadc;
    box-shadow: inset 0 -0.25em 0.25em -0.25em rgba(0,0,0,0.2);
  }
  .active :global([slot='tab-top']) {
    background-color: #efefef;
    box-shadow: unset;
  }
</style>