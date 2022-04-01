<script>
  import L from 'leaflet';
  import GeoJson from './leaflet/GeoJson.svelte';
  import MarkerCluster from './leaflet/MarkerCluster.svelte';
  import { location } from '../stores/location';

  const evcolours = {
    S: '#efd463',
    F: '#00a3da',
    R: '#d772da',
    U: '#93da72',
  };

  const icon = (color = 'black') => L.divIcon({
    className: '',
    html: `<svg width="7.0556mm" height="11.571mm" version="1.1" viewBox="0 0 25 41.001" xmlns="http://www.w3.org/2000/svg">
        <path d="m12.5 0.5a12 12 0 0 0-12 12 12 12 0 0 0 1.3047 5.439h-0.0039l10.699 23.059 10.699-23.059h-0.017a12 12 0 0 0 1.318-5.439 12 12 0 0 0-12-12z" fill="${color}"/><path transform="matrix(.93753 0 0 .93753 -.00050402 0)" d="m10.441 6.4473c-0.554 0-1 0.446-1 1v3.6328h-1.9453v6.5625c0 1.108 0.892 2 2 2h2.3633v5.375h2.9648v-5.375h2.3457c1.108 0 2-0.892 2-2v-6.5625h-1.9453v-3.6328c0-0.554-0.446-1-1-1h-0.96484c-0.554 0-1 0.446-1 1v3.6328h-1.8535v-3.6328c0-0.554-0.446-1-1-1z" fill="white" />
      </svg>`,
    iconSize: [27, 44],
    iconAnchor: [13, 44],
    popupAnchor: [0, -44],
  });

  const SLOW = 'S';
  const FAST = 'F';
  const RAPID = 'R';
  const ULTRA_RAPID = 'U';

  const type = (v) => {
    if (v > 50) return ULTRA_RAPID;
    if (v > 22) return RAPID;
    if (v > 7) return FAST;
    return SLOW;
  }

  const clusterhtml = function (pins) {
    const ratings = pins.map((p) => {
      const connectorKeys = Object.keys(p.feature.properties).filter((x) =>
        x.match(/connector\d*ratedoutputkW/i)
      );
      const powerRatings = connectorKeys.map((k) =>
        parseFloat(p.feature.properties[k])
      );
      return powerRatings;
    });
    const colours = ratings.flat().reduce(
      (colours, p) => {
        colours[type(p)]++
        return colours;
      },
      { S: 0, F: 0, R: 0, U: 0 }
    );
    const total = ratings.flat().length;
    let grad = '';
    // The number of colours
    let p = 0;
    for (const s in colours) {
      if (grad) grad += ', ';
      grad += evcolours[s] + ' ' + Math.round(p) + '%';
      p += (100 * colours[s]) / total;
      grad += ' ' + Math.round(p) + '%';
    }
    return `<div class="marker-group">
        <div class="marker-group-head" style="background:linear-gradient(to right, ${grad}); color:black;"></div>
        <span>${pins.length}</span>
      </div>`;
  };

  const options = {
    chunkedLoading: true,
    maxClusterRadius: 40,
    iconCreateFunction: function (cluster) {
      const pins = cluster.getAllChildMarkers();
      const html = clusterhtml(pins);
      return L.divIcon({
        html: html,
        className: '',
        iconSize: L.point(40, 40),
      });
    },
    // Disable all of the defaults:
    spiderfyOnMaxZoom: true,
    showCoverageOnHover: false,
    zoomToBoundsOnClick: true,
  };

  const pointToLayer = (f, latlng) => {
    // TODO check if this is safe!
    return L.marker(latlng, { icon: icon(evcolours[type(f.properties.connector1ratedoutputkw)]) });
  };
</script>

{#if $location}
  <MarkerCluster name="Chargepoints" {options}>
    <GeoJson feature={$location.chargepoints} {pointToLayer} />
  </MarkerCluster>
{/if}
