#!/usr/bin/perl
# getDistributionCentres (version 1.0)
# We read in the MSOA-level GeoJSON extracts for distribution centres that we've previously created
# For each polygon/multipolygon we:
#	- calculate the area
use strict;
use warnings;
use JSON::XS;
use Data::Dumper;


# Get the real base directory for this script
my $basedir = "./";
if($0 =~ /^(.*\/)[^\/]*/){ $basedir = $1; }
require "./".$basedir."lib.pl";

my ($conf,$layer,$coder,$file,$csv,@lines,$str,$json,@features,$f,$i,@cols,$dir,$area,$capacity,$estimate,$totalarea,$totalcapacity,$levels,$multi,%msoas,$msoa);


# Read in the configuration JSON file
$conf = loadConf($basedir."conf.json");


$layer = $ARGV[0]||"distribution";
print "Calculating areas for $layer layer.\n";

# Step up a directory
$basedir = "../".$basedir;


$dir = $basedir."tmp/MSOA/";

# Define a JSON loader
$coder = JSON::XS->new->utf8->canonical(1);



# Load file with areas we need to create scores for
open(FILE,$conf->{'basedir'}.$conf->{'lookup'}{'file'});
@lines = <FILE>;
for($i = 1; $i < @lines; $i++){
	$lines[$i] =~ s/[\n\r]+//g;
	@cols = split(/\t/,$lines[$i]);
	$msoas{$cols[0]} = $cols[2];
}
close(FILE);


$csv = "msoa,estimated capacity\n";
foreach $msoa (sort(keys(%msoas))){

	$csv .= "$msoa,";
	$file = $dir.$msoa."-$layer.geojson";

	$totalarea = 0;
	
	if(-e $file){
		open(FILE,$file);
		@lines = <FILE>;
		close(FILE);
		$str = join("",@lines);
		if($str eq ""){
			$str = "{\"features\":[]}";
		}

		# Decode the string
		$json = $coder->decode($str);

		# Get the features
		@features = @{$json->{'features'}};


		# Calculate the total area
		for($f = 0; $f < @features; $f++){

			if($features[$f]{'geometry'}{'type'} eq "Polygon" || $features[$f]{'geometry'}{'type'} eq "MultiPolygon"){
				$area = geometry($features[$f]{'geometry'});
				$totalarea += $area;
			}else{
			}
		}
	}
	$csv .= sprintf("%.2f",$totalarea)."\n";

}

# Save the output
print "Saving to $conf->{'basedir'}$conf->{'layers'}{'dir'}$layer.csv\n";
open(FILE,">",$conf->{'basedir'}.$conf->{'layers'}{'dir'}."$layer.csv");
print FILE $csv;
close(FILE);
