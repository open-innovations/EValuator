# CPC EV project

Google doc on thoughts: https://docs.google.com/document/d/1JGvk4ODUaRWJ8caFH-Sn6_jtloO5TUk6n0GiWOSswy4/edit


## Processing data

### Making lookups

Make sure to have downloaded the [Postcode to Output Area to Lower Layer Super Output Area to Middle Layer Super Output Area to Local Authority District November 2021](https://geoportal.statistics.gov.uk/datasets/postcode-to-output-area-to-lower-layer-super-output-area-to-middle-layer-super-output-area-to-local-authority-district-november-2021-lookup-in-the-uk/about) [zip file](https://www.arcgis.com/sharing/rest/content/items/7db6988a695f4c75989f0dc6701d4167/data) and unzipped it.

Running `perl makeLookup.pl` will create three lookup files within `www/data/`:

  * `lookupLAD.tsv` - LAD codes with their associated MSOAs
  * `lookupMSOA.tsv` - every MSOA with its associated LAD
  * `lookupOA.tsv` - columns for OA, LSOA, MSOA, and LAD


### Local Authority District data

Running `makeLADs.pl` will create JSON files for chargepoints (UK Chargepoint Registry), supermarkets (OSM), distribution centres (OSM), and parking (OSM) for every LAD.

The [chargepoint data comes from the UK Chargepoint Registry](https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv) as CSV. This is first converted into sqlite by `ogr2ogr` to make later processing faster e.g.

```
ogr2ogr -f SQLite chargepoints.csv.sqlite chargepoints.csv -dialect sqlite -sql "select * from chargepoints where geometry is not null" -oo X_POSSIBLE_NAMES=longitude -oo Y_POSSIBLE_NAMES=latitude -oo KEEP_GEOM_COLUMNS=NO -a_srs 'EPSG:4326'
```

The command drops the two entries that are missing geometry and sets the longitude and latitude column headings.

The supermarkets, distribution centres, and parking all come from OpenStreetMap data. If you don't already have it, the code will download the [latest GB extract from GeoFabrik](https://download.geofabrik.de/europe/great-britain-latest.osm.pbf) into the `raw/` directory.

The code loops over all the LADs to create extracts using their boundaries e.g.

```
ogr2ogr -f GeoJSON E08000035.geojson chargepoints.csv.sqlite -clipsrc www/boundaries/E08000035.geojsonl
```

### MSOA-level data

