<script>
  import WarningIcon from './icons/Warning.svelte';
</script>

<aside>
  <WarningIcon classDefs='warning-icon'/>
  <p>
    <slot/>
  </p>
</aside>

<style>
  aside {
    --warning-colour: rgb(208, 55, 0);
    display: flex;
    align-items: center;
    border: 3px solid var(--warning-colour);
    padding: 1em;
    gap: 1em;
    margin-bottom: 1em;
  }
  aside :global(svg) {
    width: 3em;
    float: left;
  }
  aside :global(.warning-icon) {
    fill: var(--warning-colour);
  }
  p {
    margin: 0;
  }
</style>