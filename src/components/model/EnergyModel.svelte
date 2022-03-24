<script>
  export let params = {};
  let demand;

  const SLOW = 6;
  const FAST = 22;
  const RAPID = 43;

  function calcDemand({ slow, fast, rapid }) {
    return slow * SLOW + fast * FAST + rapid * RAPID;
  }
  $: demand = calcDemand(params);
</script>

<p>Demand estimated at { demand }kW</p>
<p>Model assumes { SLOW}kW per slow charger, { FAST }kW per fast charger and { RAPID }kW per rapid charger.</p>

