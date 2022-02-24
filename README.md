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

The next step is to create JSON files for chargepoints (UK Chargepoint Registry), supermarkets (OSM), distribution centres (OSM), and parking (OSM) for every LAD.

There are some dependencies that you will need. These come from the GDAL suite of tools: `ogr2ogr`, `ogrinfo`, `osmconvert`, and `osmfilter`.

The [chargepoint data comes from the UK Chargepoint Registry](https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv) as CSV. This is first converted into sqlite by `ogr2ogr` to make later processing faster e.g.

```
ogr2ogr -f SQLite chargepoints.csv.sqlite chargepoints.csv -dialect sqlite -sql "select * from chargepoints where geometry is not null" -oo X_POSSIBLE_NAMES=longitude -oo Y_POSSIBLE_NAMES=latitude -oo KEEP_GEOM_COLUMNS=NO -a_srs 'EPSG:4326'
```

The command drops the two entries that are missing geometry and sets the longitude and latitude column headings.

The supermarkets, distribution centres, and parking all come from OpenStreetMap data. If you don't already have it, the code will download the [latest GB extract from GeoFabrik](https://download.geofabrik.de/europe/great-britain-latest.osm.pbf) into the `raw/` directory.

Running `perl makeLADs.pl` will loop over all the LADs to create extracts for each layer using their boundaries e.g.

```
ogr2ogr -f GeoJSON E08000035.geojson chargepoints.csv.sqlite -clipsrc www/boundaries/E08000035.geojsonl
```

### MSOA-level data

We can now create temporary extracts of the data at MSOA level in preparation for analysis. 

```
perl makeMSOAGeoJSON.pl
```

It loads the LAD-MSOA lookup table from `www/data/lookupLAD.tsv` to get a mapping from LAD to MSOA. Rather than clip to each MSOA (there are several thousand) from the GB-level data - which would be slow - we clip the LAD-level data that we created previously.

For every layer and MSOA we can run something like this:

`ogr2ogr -f GeoJSON E02006875.geojson E08000035.geojson -clipsrc ../geography-bits/data/MSOA11CD/E02006875.geojsonl`;

where `E08000035.geojson` is our input file for the LAD, `E02006875.geojson` is our output file for MSOA, and `../geography-bits/data/MSOA11CD/E02006875.geojsonl` is the boundary for the MSOA taken from our [geography-bits repo](https://github.com/odileeds/geography-bits/).
