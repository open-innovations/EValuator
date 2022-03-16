#!/usr/bin/perl

use Data::Dumper;
require "./lib.pl";

$osmconvert = "osmconvert";
$osmfilter = "osmfilter";
$mode = "info";
$ogr = "ogr2ogr";
$ogrinfo = "ogrinfo";

$rootdir = "../";
$lookup = $rootdir."www/data/lookupArea.tsv";

$msoadir = $rootdir."../geography-bits/data/MSOA11CD/";
$laddir = $rootdir."www/data/areas/";

%data = (
	'chargepoints' => { 'odir'=>$rootdir.'raw/MSOA/chargepoints/' },
	'supermarkets' => { 'odir'=>$rootdir.'raw/MSOA/supermarkets/' },
	'distribution' => { 'odir'=>$rootdir.'raw/MSOA/distribution/' },
	'parking' => { 'odir'=>$rootdir.'raw/MSOA/parking/' }
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


