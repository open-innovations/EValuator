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

my ($conf,$coder,$file,$csv,@lines,$str,$json,@features,$f,$i,@cols,$dir,$area,$capacity,$estimate,$totalarea,$totalcapacity,$levels,$multi,%msoas,$msoa);


$dir = $basedir.($ARGV[0]||"../raw/MSOA/distribution/");

# Read in the configuration JSON file
$conf = loadConf($basedir."conf.json");



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
	$file = $dir.$msoa."-distribution.geojson";

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

			#print "Feature ".$f." ($features[$f]{'geometry'}{'type'} ".($features[$f]{'properties'}{'osm_way_id'}||$features[$f]{'properties'}{'osm_id'})." / $msoa):\n";

			if($features[$f]{'geometry'}{'type'} eq "Polygon" || $features[$f]{'geometry'}{'type'} eq "MultiPolygon"){
				$area = geometry($features[$f]{'geometry'});
				$totalarea += $area;

				$capacity = $features[$f]{'properties'}{'other'}{'capacity'}||0;
				$capacity =~ s/[^0-9]//g;	# Remove non-numeric values e.g. "100 approx"
				$levels = ($features[$f]{'properties'}{'other'}{'building:levels'}||1);
				$multi = 0;
				if($features[$f]{'properties'}{'other'} && $features[$f]{'properties'}{'other'}{'parking'}){
					$multi = ($features[$f]{'properties'}{'other'}{'parking'} eq "multi-storey" ? 1 : 0);
				}

				$estimate = (1/0.34) * 0.0145*$area*$levels;

				$totalcapacity += ($capacity || $estimate);
	#			print "$estimate\n";

				#if($features[$f]{'properties'}{'other'}{'power'}){
				#	print "\tName = ".($features[$f]{'properties'}{'name'}||"")."\n";
				#	print "\tArea = ".sprintf("%.2f",$area)." m²\n";
				#}
			}else{
	#			print "\n\tType = $features[$f]{'geometry'}{'type'}\n";
			}
		}
#		print "Total area ($msoa): $totalarea m²\n";
#	print "Estimated capacity: $totalcapacity\n";
	}
	$csv .= sprintf("%.2f",$totalarea)."\n";

}

# Save the output
open(FILE,">",$conf->{'basedir'}.$conf->{'layers'}{'dir'}."distribution-centres.csv");
print FILE $csv;
close(FILE);
