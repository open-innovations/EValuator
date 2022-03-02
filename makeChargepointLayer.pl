#!/usr/bin/perl

use strict;
use warnings;
use JSON::XS;
use Data::Dumper;


my $dir = "raw/MSOA/chargepoints/";

if(!-d $dir){
	print "WARNING: The MSOA chargepoints directory $dir doesn't exist.\n";
	exit;
}

my ($file,$code,@files,$max,$coder,$str,$n,@features,$i,@lines,$json);

opendir(DIR,$dir) or die "Couldn't open directory, $!";
while($file = readdir DIR){
	if($file =~ /^(.*)-chargepoints.geojson/){
		$code = $1;
		push(@files,{'code'=>$code,'geojson'=>$dir.$file});
	}
}
closedir(DIR);


$coder = JSON::XS->new->utf8->canonical(1);

$max = 0;
for($i = 0; $i < @files ; $i++){

	if(-e $files[$i]{'geojson'}){
		open(GEOJSON,$files[$i]{'geojson'});
		@lines = <GEOJSON>;
		close(GEOJSON);
		$str = join("",@lines);

		if($str){

			$json = $coder->decode($str);
			@features = @{$json->{'features'}};
			$n = @features;
			if($n > $max){ $max = $n; }
			$files[$i]{'n'} = $n;

		}else{
			print "WARNING: No valid GeoJSON for $files[$i]{'code'}\n";
		}
	}else{
		print "WARNING: No GeoJSON for $files[$i]{'code'}\n";
	}
}

open(FILE,">","www/data/layers/chargepoints.csv");
for($i = 0; $i < @files ; $i++){
	$files[$i]{'n'} /= $max;
	print FILE "$files[$i]{'code'},".sprintf("%0.2f",$files[$i]{'n'})."\n";
}
close(FILE);


