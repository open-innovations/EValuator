<script>
  import { prefixed } from '../../lib/units';
  export let params = {};
  let demand;

  const SLOW = 7000;
  const FAST = 22000;
  const RAPID = 50000;
  const ULTRA_RAPID = 1e6;

  function calcDemand({ slow, fast, rapid, ultraRapid }) {
    return slow * SLOW + fast * FAST + rapid * RAPID + ultraRapid * ULTRA_RAPID;
  }
  $: demand = calcDemand(params);
</script>

<p>
  This model is derived from the advice provided on the 
  <a href="https://www.gov.uk/government/publications/connecting-electric-vehicle-chargepoints-to-the-electricity-network/connecting-electric-vehicle-chargepoints-to-the-electricity-network">
  Connecting EV chargepoints to the electricity network</a> page.
</p>

<p class='output'>
  Demand estimated at { prefixed(demand, 'W') }.
</p>

<p>
  Find out who your network operator is at the Energy Networks Association <a href='https://www.energynetworks.org/operating-the-networks/whos-my-network-operator'>Who’s my energy supplier or network operator?</a> page.
</p>

<p>
  This is calculated as follows:
</p>

<ul>
  <li>{ params.slow } <strong>Slow</strong> chargepoints at { prefixed(SLOW, 'W') } per chargepoint</li>
  <li>{ params.fast } <strong>Fast</strong> chargepoints at { prefixed(FAST, 'W') } per fast charger</li>
  <li>{ params.rapid } <strong>Rapid</strong> chargepoints at { prefixed(RAPID, 'W') } per rapid charger</li>
  <li>{ params.ultraRapid } <strong>Ultra-Rapid</strong> chargepoints at { prefixed(ULTRA_RAPID, 'W') } per rapid charger</li>
</ul>

<style>
  ul {
    list-style-type: disc;
    margin-left: 2em;
  }
  .output {
    font-size: 1.5em;
    font-weight: bold;
    text-align: center;
  }
</style>
