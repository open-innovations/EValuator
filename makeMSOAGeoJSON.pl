#!/usr/bin/perl

use Data::Dumper;
require "./lib.pl";

$osmconvert = "osmconvert";
$osmfilter = "osmfilter";
$mode = "info";
$ogr = "ogr2ogr";
$ogrinfo = "ogrinfo";
$lookup = "www/data/lookupLAD.tsv";

$msoadir = "../geography-bits/data/MSOA11CD/";
$laddir = "www/data/LAD/";

%data = (
	'chargepoints' => { 'odir'=>'raw/MSOA/chargepoints/' },
	'supermarkets' => { 'odir'=>'raw/MSOA/supermarkets/' },
	'distribution' => { 'odir'=>'raw/MSOA/distribution/' },
	'parking' => { 'odir'=>'raw/MSOA/parking/' }
);


if(!-d $msoadir){
	print "ERROR: $msoadir doesn't exist. This should contain all the geography bits https://github.com/odileeds/geography-bits/\n";
	exit;
}

if(!-d $laddir){
	makeDir($laddir);
}

%lookup = getLookup();


@msoaorder = sort(keys(%{$lookup{'MSOA'}}));
@ladorder = sort(keys(%{$lookup{'LAD'}}));

foreach $layer (sort(keys(%data))){

	# Make the output directory if it doesn't already exist
	makeDir($data{$layer}{'odir'});

	# Loop over MSOAs (ordered)
	for($m = 0; $m < @msoaorder; $m++){

		# Get the MSOA code
		$msoa = $msoaorder[$m];

		print "$msoa\n";
		$bfile = $msoadir.$msoa.".geojsonl";
		if(!-e $bfile){
#			print "WARNING: No GeoJSON boundary for MSOA $msoa. $gfile\n";
		}else{
			$gfile = $data{$layer}{'odir'}.$msoa."-$layer.geojson";
			$lfile = $laddir.$lookup{'MSOA'}{$msoa}."-$layer.geojson";
			if(!-e $gfile){
				`ogr2ogr -f GeoJSON $gfile $lfile -clipsrc $bfile 2>&1`;
				trimGeoJSONFile($gfile);
			}
		}
	}
}


