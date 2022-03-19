<script>
  export let params = {
    slow: 0,
    fast: 0,
    rapid: 0,
  };

</script>
<div>
  <label for='slow'>Slow chargers</label>
  <input id='slow' type='number' bind:value={ params.slow } min=0 />
</div>
<div>
  <label for='fast'>Fast chargers</label>
  <input id='fast' type='number' bind:value={ params.fast } min=0 default=0/>  
</div>
<div>
  <label for='rapid'>Rapid chargers</label>
  <input id='rapid' type='number' bind:value={ params.rapid } min=0 />  
</div>
<style>
  div {
    display: flex;
  }
  label {
    flex-grow: 1;
  }
  input[type=number] {
    text-align: right;
    width: 6em;
  }
</style>
