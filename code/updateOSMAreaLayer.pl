#!/usr/bin/perl
# We read in the MSOA-level GeoJSON extracts for distribution centres that we've previously created
# For each polygon/multipolygon we:
#	- calculate the area
use strict;
use warnings;
use JSON::XS;
use Data::Dumper;
use Cwd qw(abs_path);

# Get the real base directory for this script
my $basedir = "./";
if(abs_path($0) =~ /^(.*\/)[^\/]*/){ $basedir = $1; }
# Step back out of the code directory
$basedir =~ s/code\/$//g;
require $basedir."code/lib.pl";


my ($conf,$layer,$coder,$file,$csv,@lines,$str,$json,@features,$f,$i,@cols,$dir,$area,$capacity,$estimate,$total,$levels,$multi,%msoas,$msoa,$n,$ok);


# Read in the configuration JSON file
$conf = loadConf($basedir."code/conf.json");


$layer = $ARGV[0]||"distribution";

if(!$conf->{'osm'}{'extracts'}{$layer}){
	print "No OSM extract defined for $layer.\n";
	exit;
}

print "Calculating areas for $layer layer.\n";



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

	$total = 0;
	
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

		$n += @features;
		# Calculate the total area
		for($f = 0; $f < @features; $f++){

			if($features[$f]{'geometry'}{'type'} eq "Polygon" || $features[$f]{'geometry'}{'type'} eq "MultiPolygon"){
				$area = geometry($features[$f]{'geometry'});

				if($layer eq "parking"){

					$capacity = $features[$f]{'properties'}{'other'}{'capacity'}||0;
					$capacity =~ s/[^0-9]//g;	# Remove non-numeric values e.g. "100 approx"
					$levels = ($features[$f]{'properties'}{'other'}{'building:levels'}||1);
					$multi = 0;
					if($features[$f]{'properties'}{'other'} && $features[$f]{'properties'}{'other'}{'parking'}){
						$multi = ($features[$f]{'properties'}{'other'}{'parking'} eq "multi-storey" ? 1 : 0);
					}

					# Our estimate of the number of spaces based on the distribution of car park areas with "capacity" set on OSM
					$estimate = (1/0.34) * 0.0145*$area*$levels;

					$total += ($capacity || $estimate);

		#			print "\n\tArea = ".sprintf("%.2f",$area)." m²\n\tLevels = ".($features[$f]{'properties'}{'other'}{'building:levels'}||1).($multi ? " (MULTI)":"")."\n\tCapacity = ".($capacity)." (est = ".sprintf("%.2f",$estimate).")\n";

				}else{

					$total += $area;

				}
			}
		}
	}else{
		print "No file for $msoa\n";
	}
	$csv .= sprintf("%.2f",$total)."\n";

}

# Save the output
print "Saving to $conf->{'basedir'}$conf->{'layers'}{'dir'}$conf->{'osm'}{'extracts'}{$layer}{'csv'}\n";
open(FILE,">",$conf->{'basedir'}.$conf->{'layers'}{'dir'}.$conf->{'osm'}{'extracts'}{$layer}{'csv'});
print FILE $csv;
close(FILE);


print "Update badge at $basedir$conf->{'badges'}{'dir'}$conf->{'osm'}{'extracts'}{$layer}{'badge'}\n";
saveBadge($basedir.$conf->{'badges'}{'dir'}.$conf->{'osm'}{'extracts'}{$layer}{'badge'},$layer,$n,"SUCCESS");
