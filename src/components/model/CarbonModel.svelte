<script>
  import { prefixed } from '../../lib/units';

  export let params;

  const UTILISATION = 0.9;
  const DAILY_MILES_ICE = 50;
  const DAILY_MILES_EV = 35;
  const EV_PER_ICE = DAILY_MILES_EV / DAILY_MILES_ICE;
  const CARBON_PER_MILE = 0.2 * 1000;

  $: schemeSize = params.chargepoints;
  $: abatement = DAILY_MILES_ICE * CARBON_PER_MILE * EV_PER_ICE * schemeSize * UTILISATION * 365;
</script>

<p>
  This is an example of providing a Carbon Abatement model, focussed on commercial LGV. It's derived from research conducted by the team,
  and has not yet been validated by experts in sustainability.
</p>

{#if abatement > 0}
  <p class='output'>
    The specified scheme could save { prefixed(abatement.toPrecision(3), 'g') } of CO<sub>2</sub> per year.
  </p>
{/if}

<h3>
  Modelling assumptions
</h3>

<ul>
  <li>{ DAILY_MILES_ICE} miles per day per active ICE vehicle (100 if rural)</li>
  <li>{ UTILISATION * 100 }% of EV fleet active during a day</li>
  <li>Only one trip per EV vehicle per day, to allow for charging time.</li>
  <li>Effective EV route { DAILY_MILES_EV } miles</li>
  <li>{ DAILY_MILES_EV } / { DAILY_MILES_ICE } = { EV_PER_ICE } ICE vehicles replaced per EV.</li>
  <li>{ prefixed(CARBON_PER_MILE, 'g') }/mile CO<sub>2</sub> emitted by an ICE vehicle.</li>
  <li>The model ignores any CO<sub>2</sub> emitted during production of EV, or the embodied CO<sub>2</sub> in the scheme.</li>
</ul>


<h3>Sources</h3>
<ul>
  <li>
    <a href="https://www.mercedes-benz.co.uk/vans/en/e-sprinter-panel-van">https://www.mercedes-benz.co.uk/vans/en/e-sprinter-panel-van</a>
  </li>
  <li>
    <a href="https://fleetworld.co.uk/co2-calculator/">https://fleetworld.co.uk/co2-calculator/</a>
  </li>
  <li>
    <a href="https://www.vehicle-certification-agency.gov.uk/information-for-light-good-vehicles/">https://www.vehicle-certification-agency.gov.uk/information-for-light-good-vehicles/</a>
  </li>
  <li>
    <a href="https://ec.europa.eu/clima/news-your-voice/news/first-co2-emissions-data-vans-published-2013-06-18_en">https://ec.europa.eu/clima/news-your-voice/news/first-co2-emissions-data-vans-published-2013-06-18_en</a>
  </li>
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
