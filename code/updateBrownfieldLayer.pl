#!/usr/bin/perl
# Generate the chargepoint layer
use strict;
use warnings;
use JSON::XS;
use Text::CSV;
use Data::Dumper;
use Cwd qw(abs_path);

# Get the real base directory for this script
my $basedir = "./";
if(abs_path($0) =~ /^(.*\/)[^\/]*/){ $basedir = $1; }
# Step back out of the code directory
$basedir =~ s/code\/$//g;
require $basedir."code/lib.pl";



# Read in the configuration JSON file
my $conf = loadConf($basedir."code/conf.json");
my $ofile = $basedir."docs/data/layers/brownfield-areas.csv";


my ($coder,@features,$n,%msoas,@msoafeatures,$msoa,$i,$lat,$lon,$area,$name,$good);


# Create a JSON encoder/decoder
$coder = JSON::XS->new->utf8->canonical(1)->pretty;


# Load the MSOA features (this will calculate bounding boxes for them too)
# We will use @msoafeatures in getMSOA() later
@msoafeatures = loadFeatures($basedir."code/MSOA.geojson");


# Download data from Digital Land. It will go through all the pages until it gets everything.
@features = downloadFromDigitalLand("https://www.digital-land.info/entity.geojson?dataset=brownfield-land&limit=500");
#@features = loadFeatures($basedir."brownfield-sites.geojson"); <- could load from a local GeoJSON file instead


# Find out how many features there are
$n = @features;
print "Loaded $n brownfield land features.\n";


# Loop over the features
$good = 0;
for($i = 0; $i < $n; $i++){
	if($features[$i]){
		if($features[$i]{'geometry'}{'type'} ne "Point"){
			print "ERROR: feature $i is not a Point\n";
		}else{

			# Get the area for this feature
			$area = ($features[$i]{'properties'}{'json'}{'hectares'}||0);

			# Get the name of this feature
			$name = $features[$i]{'properties'}{'json'}{'site-address'};

			# Get the latitude and longitude of the feature
			$lon = $features[$i]{'geometry'}{'coordinates'}[0];
			$lat = $features[$i]{'geometry'}{'coordinates'}[1];
			
			# Work out the MSOA this point is in
			$msoa = getFeature("msoa11cd",$lat,$lon,@msoafeatures);

			# If we have an MSOA we add the area to the total for it
			if($msoa){
				# If we haven't already noted this MSOA we create a 0 value for it
				if(!$msoas{$msoa}){ $msoas{$msoa} = 0; }
				$msoas{$msoa} += $area;
				$good++;
			}else{
				print "No MSOA found for ($lat,$lon) - feature $i / $n\n";
			}
		}
	}else{
		#print "ERROR: No feature $i\n";
	}
}

# Save MSOA-binned output to a CSV file
open(FILE,">",$ofile);
print FILE "msoa,brownfield area\n";
# Print the sorted MSOA values
foreach $msoa (sort(keys(%msoas))){
	print FILE "$msoa,$msoas{$msoa}\n";
}
close(FILE);


# Make a badge
my $pc = 100*$good/$n;
saveBadge($basedir."badge-brownfield.svg","brownfield",sprintf("%d",$pc)."%",($pc > 50 ? "SUCCESS" : "FAIL"));



########################
# SUBROUTINES

sub downloadFromDigitalLand {
	my $url = shift(@_);
	my @features = @_;
	my ($str,$json);
	
	print "Getting $url...\n";
	$str = `wget -q --no-check-certificate -O- "$url"`;
	$json = $coder->decode($str);
	push(@features,@{$json->{'features'}});
	
	if($json->{'links'}{'next'}){
		#print "Need to download $json->{'links'}{'next'}\n";
		push(@features,downloadFromDigitalLand($json->{'links'}{'next'}));
	}

	return @features;
}