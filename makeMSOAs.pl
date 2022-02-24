#!/usr/bin/perl

use Data::Dumper;
require "./lib.pl";

$osmconvert = "osmconvert";
$osmfilter = "osmfilter";
$mode = "info";
$ogr = "ogr2ogr";
$ogrinfo = "ogrinfo";
$lookup = "lookupMSOA.csv";

$msoadir = "../geography-bits/data/MSOA11CD/";
$laddir = "www/data/LAD/";

%data = (
	'chargepoints' => { 'file'=>'raw/chargepoints.csv.sqlite', 'odir'=>'www/data/MSOA/' }
);


open(FILE,$lookup);
$i = 0;
while(<FILE>){
	$line = $_;
	if($i > 0){
		$line =~ s/[\n\r]//;
		($msoa,$lad) = split(/\t/,$line);
		$msoas{$msoa} = $lad;
		if(!$lads{$lad}){
			$lads{$lad} = ();
		}
		push(@{$lads{$lad}},$msoa);
	}
	$i++;
}

@msoaorder = sort(keys(%msoas));
@ladorder = sort(keys(%lads));


foreach $layer (sort(keys(%data))){

	if(!-d $data{$layer}{'odir'}){
		`mkdir $data{$layer}{'odir'}`;
	}
	# Loop over MSOAs
	
	for($m = 0; $m < @msoaorder; $m++){
		#$wkt = getMSOAWKT($msoas[$m]);
		#print "$wkt";
		$msoa = $msoaorder[$m];
		$bfile = $msoadir.$msoa.".geojsonl";
		if(!-e $bfile){
#			print "WARNING: No GeoJSON boundary for MSOA $msoa. $gfile\n";
		}else{
			$gfile = $data{$layer}{'odir'}.$msoa."-$layer.geojson";
			$lfile = $laddir.$msoas{$msoa}."-$layer.geojson";
			if(!-e $gfile){
				print "$msoa\n";
				`ogr2ogr -f GeoJSON $gfile $lfile -clipsrc $bfile 2>&1`;
				trimGeoJSONFile($gfile);
			}
		}
	}

}


