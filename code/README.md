# Code

## Create a new geographic area

Currently the tool contains Local Authorities and Combined Authorities. If you want to add a new area, add it to the file `docs/data/areas.tsv` with the ONS code and the name. Make sure that the code is included in the lookup file `docs/data/lookup/OA11-LAD21-CAUTH21.tsv` in a column with a header ending with `CD` so that we know which MSOAs it is connected to. Then run the following steps:

  * `perl generateAreas.pl` - this will create `docs/data/lookup/lookupArea.tsv` which contains all the area codes with their associated MSOAs. For each area it will generate:
    * `docs/data/areas/CODE/` - the sub-directory
	* `docs/data/areas/CODE/CODE-msoas.tsv` - the MSOAs for this area with their House of Commons names
	* `docs/data/areas/CODE/CODE.geojson` - a GeoJSON file with all the MSOA polygons for this area

## Updating layers

  * `perl extractOSM.pl rebuild` - creates GeoJSON extracts per local authority for various OSM layers
  * `perl makeMSOAGeoJSON.pl rebuild`  - creates MSOA-level extracts from the area extracts in preparation for analysis
  * `perl updateOSMAreaLayer.pl parking` - builds the carpark capacity CSV using the MSOA-level extracts of parking
  * `perl updateOSMAreaLayer.pl distribution` - builds the distribution centre CSV using the MSOA-level extracts of distribution centres
  * `perl updateOSMAreaLayer.pl supermarket` - builds the supermarket CSV using the MSOA-level extracts of supermarkets
  * `perl updateOSMAreaLayer.pl warehouse` - builds the warehouse CSV using the MSOA-level extracts of warehouses
  * `perl updateChargepointLayer.pl` - this will:
     1. download the latest data from the National Chargepoint Registry
	 2. update the chargepoint list at `docs/data/chargepoints.csv` and the individual chargepoint JSON files in `docs/data/chargepoints` for the map view
	 3. update the chargepoint MSOA layer at `docs/data/layers/chargepoints.csv` (you'll need to run `buildScores.pl` again to update the layers properly)
  * `perl updateCapacityLayer.pl` - builds the grid capacity layer at `docs/data/layers/grid-capacity.csv`
  * `perl buildScores.pl` - this will update the scores for every area listed in `docs/data/areas.tsv` creating `docs/data/areas/CODE/CODE.csv` as necessary



### Command line examples


```
ogr2ogr -f GeoJSON E02006875.geojson E08000035.geojson -clipsrc ../geography-bits/data/MSOA11CD/E02006875.geojsonl
```

where `E08000035.geojson` is our input GeoJSON for the area, `E02006875.geojson` is our output GeoJSON for a particular MSOA, and `../geography-bits/data/MSOA11CD/E02006875.geojsonl` is the boundary for the MSOA in our [geography-bits repo](https://github.com/odileeds/geography-bits/).





## Processing data



Next make a clone of our [geography-bits repo](https://github.com/odileeds/geography-bits/) so that we have boundaries for MSOAs and LADs.






### Local Authority District data

The next step is to create JSON files for chargepoints (UK Chargepoint Registry), supermarkets (OSM), distribution centres (OSM), and parking (OSM) for every LAD.

There are some dependencies that you will need. These come from the GDAL suite of tools: `ogr2ogr`, `ogrinfo`, `osmconvert`, and `osmfilter`.

The [chargepoint data comes from the UK Chargepoint Registry](https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv) as CSV. This is first converted into sqlite by `ogr2ogr` to make later processing faster e.g.

```
ogr2ogr -f SQLite chargepoints.csv.sqlite chargepoints.csv -dialect sqlite -sql "select * from chargepoints where geometry is not null" -oo X_POSSIBLE_NAMES=longitude -oo Y_POSSIBLE_NAMES=latitude -oo KEEP_GEOM_COLUMNS=NO -a_srs 'EPSG:4326'
```

The command drops the two entries that are missing geometry and sets the longitude and latitude column headings.

The supermarkets, distribution centres, and parking all come from OpenStreetMap data. If you don't already have it, the code will download the [latest GB extract from GeoFabrik](https://download.geofabrik.de/europe/great-britain-latest.osm.pbf) into the `raw/` directory.

Running `perl makeAreas.pl` will loop over all the areas (e.g. Local and Combined Authorities) to create extracts for each layer using their boundaries e.g.

```
ogr2ogr -f GeoJSON E08000035-data.geojson chargepoints.csv.sqlite -clipsrc docs/boundaries/E08000035.geojsonl
```

But it could be more efficient to clip the SQLite for the whole of GB to the bounding box of the LAD first. We could use `ogrinfo` to find the extent:

```
ogrinfo -so -al docs/boundaries/E08000035.geojsonl | grep Extent
```

which returns

```
Extent (lon1, lat2 - lon2, lat2)
```

Then we could clip the SQLite file with `osmconvert` and then clip that file with the e.g.

```
osmconvert chargepoints.csv.sqlite -b=lon1,lat1,lon2,lat2 --complete-ways -o=temporary.sqlite
ogr2ogr -f SQLite E08000035-data.geojson temporary.sqlite -clipsrc docs/boundaries/E08000035.geojsonl 2>&1`;
```

For some big/fractal-coasty Local Authorities, this two-step process makes it much quicker.
