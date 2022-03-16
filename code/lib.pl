#!/usr/bin/perl

use strict;
use warnings;
use JSON::XS;
use Data::Dumper;
use Math::Trig;


sub loadConf {
	# Version 1.1
	my ($dir,$file,$conf,$str,$coder,@lines);
	$file = $_[0];
	$str = "{}";
	if(-e $file){
		open(FILE,$file);
		@lines = <FILE>;
		close(FILE);
		$str = join("",@lines);
	}else{
		error("No config file $file = $ENV{'SERVER_NAME'}.");
	}
	$coder = JSON::XS->new->utf8->allow_nonref;
	eval {
		$conf = $coder->decode($str);
	};
	my $basedir = "./";
	if($0 =~ /^(.*\/)[^\/]*/){ $basedir = $1; }
	$conf->{'basedir'} = $basedir."../";
	if($@){ error("Failed to load JSON from $file: <br /><textarea style=\"width: 100%;height:calc(100vh - 4em);\">\n$str\n</textarea>");	}
	return $conf;
}

sub error {
	my $str = $_[0];
	print "Content-type: text/html\n\n";
	print "Error: $str\n";
	exit;
}

sub trimGeoJSONFile {
	my $file = $_[0];
	my $out = "";
	my ($row,$comma,$other);

	open(FILE,$file);
	while(<FILE>){
		$row = $_;
		if($row =~ /{ "type": "Feature"/){
			$row =~ s/(\,?)[\n\r]+//g;
			$comma = $1;
			
			$row =~ s/ ?\], \[ ?/\],\[/g;
			$row =~ s/: \{ /:\{/g;
			$row =~ s/", "/","/g;
			$row =~ s/": "/":"/g;
			$row =~ s/ \] \]/\]\]/g;
			$row =~ s/ ?\[ \[ /\[\[/g;
			$row =~ s/ \} \}/\}\}/g;
			$row =~ s/([0-9]), (\-?[0-9])/$1,$2/g;
			$row =~ s/,"z_order": [0-9]+//g;
						
			if($row =~ /"other_tags":"(.*?)" \},/){
				#\"power\"=>\"generator\",\"generator:type\"=>\"horizontal_axis\"
				$other = $1;
				$other =~ s/\\\\/\\/g;
				$other =~ s/\\\\"/'/g;
				$other =~ s/\\\"([^\"]*)\\\"=>\\\"([^\"]*)\\\"/\"$1\":\"$2\"/g;
			}
			$row =~ s/"other_tags":"(.*?)" \},/\"other\":\{$other\}\},/g;

			$row =~ s/ ?([\-\+]?[0-9]+\.[0-9]{5})[0-9]+, ?([\-\+]?[0-9]+\.[0-9]{5})[0-9]+/$1,$2/g;
			$row =~ s/, ?\"[^\"]*": null//g;
			$row =~ s/{\"[^\"]*": null ?\, ?/\{/g;
			$row =~ s/" \}, "/"\},"/g;
			$row =~ s/": \[ /":\[/g;
			$row =~ s/", "/","/g;
			
			$row =~ s/\, ?\"[^\"]+\":\"\"//g;
			
			$row .= "$comma\n";
		}elsif($row =~ /^"crs": \{/){
			# Remove CRS line
			$row = "";
		}elsif($row =~ /^"name":/){
			# Remove Name line
			$row = "";
		}
		$out .= $row;
	}
	close(FILE);

	open(FILE,">",$file);
	print FILE $out;
	close(FILE);
}

sub getGeoJSONLasWKT {
	my $file = $_[0];
	my (@lines,$out);

	open(FILE,$file);
	@lines = <FILE>;
	close(FILE);
	
	if($lines[0] =~ /"type":"MultiPolygon","coordinates":([^\}]*)/){
		$out = $1;
		$out =~ s/\[ ?([0-9\-\.]+), ?([0-9\-\.]+) ?\]/$1 $2/g;
		$out =~ s/\[/\(/g;
		$out =~ s/\]/\)/g;
		$out = "MULTIPOLYGON ".$out;
	}else{
		print "WARNING: $file doesn't seem to contain a MultiPolygon.\n";
	}
	return $out;
}

sub makeDir {
	my $dir = $_[0];
	if(-d $dir){
		return 0;
	}
	my @bits = split(/\//,$dir);
	my ($i,$path);
	$path = "";
	for($i = 0; $i < @bits; $i++){
		$path .= ($path ? "/":"").$bits[$i];
		if(!-d $path){
			`mkdir $path`;
		}
	}
	return 1;
}

sub getLookup {
	my $file = "../www/data/lookupArea.tsv";
	my (%lookup,$i,$line,$lad,$ms,$n,$m);

	%lookup = ('LAD'=>{},'MSOA'=>{});

	# Open the LAD/MSOA lookup file
	open(FILE,$file) || error("Couldn't open the file");
	$i = 0;
	while(<FILE>){
		$line = $_;
		if($i > 0){
			$line =~ s/[\n\r]//;
			($lad,$ms) = split(/\t/,$line);
			# Split the MSOAs for the LAD
			@{$lookup{'LAD'}{$lad}} = split(/;/,$ms);
			# Count the number of MSOAs
			$n = @{$lookup{'LAD'}{$lad}};
			for($m = 0; $m < $n;$m++){
				# Create a lookup for MSOAs
				$lookup{'MSOA'}{$lookup{'LAD'}{$lad}[$m]} = $lad;
			}
		}
		$i++;
	}
	return %lookup;
}

sub polyify {

	my (@lines,$name,$coder,$str,$json,@features,@feature,$nf,$n,$f,@polygons,$npoly,$p,@parts,$pt,$npt,$poly,@coords,$c,$file);

	$file = $_[0];

	#print "Opening $file\n";
	open(GEOJSON,$file);
	@lines = <GEOJSON>;
	close(GEOJSON);
	$str = join("",@lines);

	$coder = JSON::XS->new->utf8->canonical(1);

	if($file =~ /\.geojsonl/){
		$str = "{\"type\": \"FeatureCollection\",\"features\": [".$str."]}";
	}

	$json = $coder->decode($str);
	@features = @{$json->{'features'}};
	$n = @features;

	$name = $file;
	$name =~ s/\.[^\.]*$//;
	$name =~ s/[\/]/\_/g;

	$poly = "$name\n";
	#print "$n features\n";
	if($n > 0){
		for($f = 0; $f < $n; $f++){
			# If this feature is a MultiPolygon
			if($features[$f]{'geometry'}{'type'} eq "MultiPolygon"){
				@feature = @{$features[$f]{'geometry'}{'coordinates'}};
				$nf = @feature;
				#print "\tnf = $nf\n";
				for($p = 0; $p < $nf; $p++){
					@parts = @{$features[$f]{'geometry'}{'coordinates'}[$p]};
					$npt = @parts;
					for($pt = 0; $pt < $npt; $pt++){
						if($pt > 0){
							# Prefix for a hole
							$poly .= "!";
						}
						$poly .= "polygon\_$f\_$p\_$pt\n";
						@coords = @{$features[$f]{'geometry'}{'coordinates'}[$p][$pt]};
						# Print all the coordinates for this part
						for($c = 0; $c < @coords; $c++){
							$poly .= "\t".$coords[$c][0]."\t".$coords[$c][1]."\n";
						}
						$poly .= "END\n";
					}
				}
			}elsif($features[$f]{'geometry'}{'type'} eq "Polygon"){
				@feature = @{$features[$f]{'geometry'}{'coordinates'}};
				$nf = @feature;
				#print "\tnf = $nf\n";
				for($p = 0; $p < $nf; $p++){
					if($p > 0){
						# Prefix for a hole
						$poly .= "!";
					}
					$poly .= "polygon\_$f\_$p\n";
					@coords = @{$features[$f]{'geometry'}{'coordinates'}[$p]};
					$npt = @parts;
					#print "\t\tnpt = $npt\n";
					# Print all the coordinates for this part
					for($c = 0; $c < @coords; $c++){
						$poly .= "\t".$coords[$c][0]."\t".$coords[$c][1]."\n";
					}
					$poly .= "END\n";
				}
			}else{
				print "Unknown type\n";
			}
		}
	}
	$poly .= "END\n";
	return $poly;
}


#my @poly = ( [3,4], [5,11], [12,8], [9,5], [5,6] );
#say area_by_shoelace(   [3,4], [5,11], [12,8], [9,5], [5,6]   );
#say area_by_shoelace( [ [3,4], [5,11], [12,8], [9,5], [5,6] ] );
#say area_by_shoelace(  @poly );
#say area_by_shoelace( \@poly );
# Source: https://rosettacode.org/wiki/Shoelace_formula_for_polygonal_area#Perl
sub area_by_shoelace {
	my $area;
	our @p;
	$#_ > 0 ? @p = @_ : (local *p = shift);
	$area += $p[$_][0] * $p[($_+1)%@p][1] for 0 .. @p-1;
	$area -= $p[$_][1] * $p[($_+1)%@p][0] for 0 .. @p-1;
	return abs $area/2;
}

# Source: https://github.com/mapbox/geojson-area/blob/master/index.js
sub geometry {
	my $in = $_[0];
	my $area = 0;
	my $i;
	if($in->{'type'} eq 'Polygon'){
		return polygonArea(@{$in->{'coordinates'}});
	}elsif($in->{'type'} eq 'MultiPolygon'){
		for($i = 0; $i < @{$in->{'coordinates'}}; $i++){
			$area += polygonArea(@{$in->{'coordinates'}[$i]});
		}
		return $area;
	}elsif($in->{'type'} eq "Point" || $in->{'type'} eq "MultiPoint" || $in->{'type'} eq 'LineString' || $in->{'type'} eq 'MultiLineString'){
		return $area;
	}else{
		return $area;
	}
}

sub polygonArea{
	my @coords = @_;
	my $area = 0;
	my $len = scalar @coords;
	my $i;
	if($len > 0){
		$area += abs(ringArea(@{$coords[0]}));
		for($i = 1; $i < $len; $i++) {
			$area -= abs(ringArea(@{$coords[$i]}));
		}
	}
	return $area;
}


# Calculate the approximate area of the polygon were it projected onto
#	 the earth.  Note that this area will be positive if ring is oriented
#	 clockwise, otherwise it will be negative.
#
# Reference:
# Robert. G. Chamberlain and William H. Duquette, "Some Algorithms for
#	 Polygons on a Sphere", JPL Publication 07-03, Jet Propulsion
#	 Laboratory, Pasadena, CA, June 2007 http://trs-new.jpl.nasa.gov/dspace/handle/2014/40409
#
# Returns:
# {float} The approximate signed geodesic area of the polygon in square meters.
sub ringArea {
	my @coords = @_;
	my (@p1, @p2, @p3, $lowerIndex, $middleIndex, $upperIndex, $i, $area, $coordsLength,$wgs84radius);
	$wgs84radius = 6378137.0;
	$area = 0;
	$coordsLength = @coords;

	if($coordsLength > 2){
		for($i = 0; $i < $coordsLength; $i++) {
			if ($i == $coordsLength - 2) {	# i = N-2
				$lowerIndex = $coordsLength - 2;
				$middleIndex = $coordsLength -1;
				$upperIndex = 0;
			} elsif ($i == $coordsLength - 1) {	# i = N-1
				$lowerIndex = $coordsLength - 1;
				$middleIndex = 0;
				$upperIndex = 1;
			} else { # i = 0 to N-3
				$lowerIndex = $i;
				$middleIndex = $i+1;
				$upperIndex = $i+2;
			}
			@p1 = @{$coords[$lowerIndex]};
			@p2 = @{$coords[$middleIndex]};
			@p3 = @{$coords[$upperIndex]};
			$area += ( rad($p3[0]) - rad($p1[0]) ) * sin( rad($p2[1]) );
		}

		$area = $area * $wgs84radius * $wgs84radius / 2;
	}

	return $area;
}

sub rad {
	return $_[0] * pi() / 180;
}

1;