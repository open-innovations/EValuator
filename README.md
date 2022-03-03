# CPC EV project

Google doc on thoughts: https://docs.google.com/document/d/1JGvk4ODUaRWJ8caFH-Sn6_jtloO5TUk6n0GiWOSswy4/edit

## Create a new geographic area

Currently the tool contains Local Authorities and Combined Authorities. If you want to add a new area, add it to the file `www/data/areas.tsv` with the ONS code and the name. Make sure that the code is included in the lookup file `www/data/OA11-LAD21-CAUTH21.tsv` in a column with a header ending with `CD` so that we know which MSOAs it is connected to. Then run the following steps:

  * `perl updateAreas.pl` - this will:
     * create the appropriate sub-directory within `www/data/areas/`
	 * create an MSOA lookup file in `www/data/areas/CODE/CODE-msoas.tsv`
	 * make a GeoJSON file in `www/data/areas/CODE/CODE.geojson`
  * `perl buildScores.pl` - this will update the scores for every area listed in `www/data/areas.tsv` creating `www/data/areas/CODE/CODE.csv` as necessary



## Processing data

### Setting up

Make sure to have downloaded the [Postcode to Output Area to Lower Layer Super Output Area to Middle Layer Super Output Area to Local Authority District November 2021](https://geoportal.statistics.gov.uk/datasets/postcode-to-output-area-to-lower-layer-super-output-area-to-middle-layer-super-output-area-to-local-authority-district-november-2021-lookup-in-the-uk/about) [zip file](https://www.arcgis.com/sharing/rest/content/items/7db6988a695f4c75989f0dc6701d4167/data) and unzipped it.

Running `perl makeLookup.pl` will create three lookup files within `www/data/`:

  * `lookupLAD.tsv` - LAD codes with their associated MSOAs
  * `lookupMSOA.tsv` - every MSOA with its associated LAD
  * `lookupOA.tsv` - columns for OA, LSOA, MSOA, and LAD

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

Running `perl makeLADs.pl` will loop over all the LADs to create extracts for each layer using their boundaries e.g.

```
ogr2ogr -f GeoJSON E08000035-data.geojson chargepoints.csv.sqlite -clipsrc www/boundaries/E08000035.geojsonl
```

But it could be more efficient to clip the SQLite for the whole of GB to the bounding box of the LAD first. We could use `ogrinfo` to find the extent:

```
ogrinfo -so -al www/boundaries/E08000035.geojsonl | grep Extent
```

which returns

```
Extent (lon1, lat2 - lon2, lat2)
```

Then we could clip the SQLite file with `osmconvert` and then clip that file with the e.g.

```
osmconvert chargepoints.csv.sqlite -b=lon1,lat1,lon2,lat2 --complete-ways -o=temporary.sqlite
ogr2ogr -f SQLite E08000035-data.geojson temporary.sqlite -clipsrc www/boundaries/E08000035.geojsonl 2>&1`;
```

For some big/fractal-coasty Local Authorities, this two-step process makes it much quicker.

### MSOA-level data

We can now create temporary extracts of the data at MSOA level in preparation for analysis. 

```
perl makeMSOAGeoJSON.pl
```

It loads the LAD-MSOA lookup table from `www/data/lookupLAD.tsv` to get a mapping from LAD to MSOA. Rather than clip to each MSOA (there are 7201) from the GB-level data - which would be slow - we clip the LAD-level data that we created previously.

For every layer and MSOA we can run something like this:

```
ogr2ogr -f GeoJSON E02006875.geojson E08000035.geojson -clipsrc ../geography-bits/data/MSOA11CD/E02006875.geojsonl
```

where `E08000035.geojson` is our input file for the LAD, `E02006875.geojson` is our output file for MSOA, and `../geography-bits/data/MSOA11CD/E02006875.geojsonl` is the boundary for the MSOA in our [geography-bits repo](https://github.com/odileeds/geography-bits/).


