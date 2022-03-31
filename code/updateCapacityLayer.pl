#!/usr/bin/perl
# Make the grid capacity layer
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


my ($file,$coder,@lines,$str,$json,$url,$i,@cols,%primarydata,$id,%header,$c,$primary,%msoalookup,$msoa,$csv,$max,$year);


# Set the output file
$file = $basedir."docs/data/layers/grid-capacity.csv";


# Define the reference year to calculate capacity
$year = "2030";


$coder = JSON::XS->new->utf8->canonical(1);


# Open the Primaries to MSOA mapping file
open(FILE,$basedir."code/primaries2msoa.json");
@lines = <FILE>;
close(FILE);
$str = join("",@lines);
$json = $coder->decode($str);

foreach $primary (sort(keys(%{$json}))){
	foreach $msoa (sort(keys(%{$json->{$primary}}))){
		if(!$msoalookup{$msoa}){ $msoalookup{$msoa} = {}; }
		if(!$msoalookup{$msoa}{$primary}){ $msoalookup{$msoa}{$primary} = 0; }
		$msoalookup{$msoa}{$primary}++;
	}
}

# Get peak utilisation (Steady Progression)
$url = "https://raw.githubusercontent.com/odileeds/northern-powergrid/master/2021-DFES/data/scenarios/primaries/PeakUtilisation-SP.csv";
@lines = `wget -q --no-check-certificate -O- "$url"`;
(@cols) = split(/,/,$lines[0]);
for($c = 0; $c < @cols; $c++){ $header{$cols[$c]} = $c; }
for($i = 1; $i < @lines; $i++){
	(@cols) = split(/,/,$lines[$i]);
	if($cols[$header{$year}]){
		$primarydata{$cols[$header{'Primary'}]} = {'utilisation'=>$cols[$header{$year}],'demand'=>0};
	}
}

# Get peak demand (Steady Progression)
$url = "https://raw.githubusercontent.com/odileeds/northern-powergrid/master/2021-DFES/data/scenarios/primaries/PeakDemand-SP.csv";
@lines = `wget -q --no-check-certificate -O- "$url"`;
(@cols) = split(/,/,$lines[0]);
for($c = 0; $c < @cols; $c++){ $header{$cols[$c]} = $c; }
for($i = 1; $i < @lines; $i++){
	(@cols) = split(/,/,$lines[$i]);
	if($cols[$header{$year}]){
		$id = $cols[$header{'Primary'}];
		$primarydata{$id}{'demand'} = $cols[$header{$year}];
		if($primarydata{$id}{'utilisation'} && $primarydata{$id}{'utilisation'} > 0){
			if($primarydata{$id}{'utilisation'} > 100){
				$primarydata{$id}{'status'} = 'RED';
				$primarydata{$id}{'capacity'} = 0;
			}else{
				$primarydata{$id}{'capacity'} = (((100-$primarydata{$id}{'utilisation'})/100))*$primarydata{$id}{'demand'};
				if($primarydata{$id}{'capacity'} >= 2){ $primarydata{$id}{'status'} = 'GREEN';}
				if($primarydata{$id}{'capacity'} < 2 && $primarydata{$id}{'capacity'} > 0){ $primarydata{$id}{'status'} = 'AMBER'; }
				if($primarydata{$id}{'capacity'} <= 0){ $primarydata{$id}{'status'} = 'RED'; }
			}
			if(!$json->{$id}){
				print "Bad $id\n";
			}

		}else{
			print "No utilisation for $id.\n";
		}
	}
}


# For each MSOA we want to find the primary with the most capacity
$csv = "msoa,capacity\n";
foreach $msoa (sort(keys(%msoalookup))){
	print "$msoa:\n";
	$max = 0;
	foreach $primary (sort(keys(%{$msoalookup{$msoa}}))){
		print "\t$primary = $primarydata{$primary}{'capacity'} MW\n";
		if($primarydata{$primary}{'capacity'} > $max){
			$max = $primarydata{$primary}{'capacity'};
		}
	}
	$csv .= "$msoa,".sprintf("%0.2f",$max)."\n";
}
open(FILE,">",$file);
print FILE $csv;
close(FILE);


