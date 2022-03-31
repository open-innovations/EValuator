#!/usr/bin/perl

use warnings;
use JSON::XS;
use Data::Dumper;
use Math::Trig;
use constant PI => 4 * atan2(1, 1);
use constant X         => 0;
use constant Y         => 1;
use constant TWOPI    => 2*PI;


sub getPixelLength {
	my $str = $_[0];
	my $fs = $_[1]||11;
	my ($i,$chr,$len,$ch,$l);
	
	$chr = {'i'=>0.6,'l'=>0.6,'m'=>1.2,'w'=>1.2,'1'=>0.8,'%'=>1.8};
	$len = 0;

	for($i = 0; $i < length($str); $i++){
		$ch = substr($str,$i,1);
		$l = $chr->{$ch}||1;
		$len += $l*$fs*0.6;
	}
	return $len;	
}
sub saveBadge {
	my $file = $_[0];
	my $key = $_[1];
	my $value = $_[2];
	my $status = $_[3]||"default";
	my ($wk,$wv,$w,$fs,$scale,$colour,$tcolour,$icolour,$pt,$pl,$h,%len);
	
	$fs = 11;
	$scale = 10;
	$h = 20;

	$wk = getPixelLength($key,$fs);
	$wv = getPixelLength($value,$fs);
	
	$pt = 4;
	$pl = 6;

	$colour = "#08DEF9";
	$tcolour = "black";
	$icolour = "#010101";

	if($status eq "SUCCESS"){ $colour = "#67E767"; $tcolour = "black"; $icolour = "white"; }
	elsif($status eq "FAIL"){ $colour = "#D60303"; $tcolour = "white"; $icolour = "black"; }

	$w = $pl + $wk + $pt*2 + $wv + $pl;

	# Make a badge
	open(BADGE,">",$file);
	print BADGE "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"$w\" height=\"20\" role=\"img\" aria-label=\"$key: $value\">";
	print BADGE "<title>$key: $value</title><linearGradient id=\"s\" x2=\"0\" y2=\"100%\"><stop offset=\"0\" stop-color=\"#bbb\" stop-opacity=\".1\"/><stop offset=\"1\" stop-opacity=\".1\"/></linearGradient>";
	print BADGE "<clipPath id=\"r\"><rect width=\"$w\" height=\"20\" rx=\"3\" fill=\"#fff\"/></clipPath>";
	print BADGE "<g clip-path=\"url(#r)\">";
	print BADGE "<rect width=\"".(($pl + $wk + 4))."\" height=\"20\" fill=\"#555\"/>";
	print BADGE "<rect x=\"".(($pl + $wk + 4))."\" width=\"".(($pl + $wv + 4))."\" height=\"20\" fill=\"$colour\"/>";
	print BADGE "<rect width=\"$w\" height=\"20\" fill=\"url(#s)\"/>";
	print BADGE "</g><g fill=\"#fff\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Verdana,Geneva,DejaVu Sans,sans-serif\" text-rendering=\"geometricPrecision\" font-size=\"".($fs*10)."\">";
	print BADGE "<text aria-hidden=\"true\" x=\"".(($pl + $wk/2)*$scale)."\" y=\"".(($h * 0.5 + 1) * $scale)."\" fill=\"#010101\" fill-opacity=\".3\" transform=\"scale(".(1/$scale).")\" textLength=\"".($wk*$scale)."\">$key</text>";
	print BADGE "<text x=\"".(($pl + $wk/2)*$scale)."\" y=\"".(($h * 0.5) * $scale)."\" fill=\"#fff\" transform=\"scale(".(1/$scale).")\" textLength=\"".($wk*$scale)."\">$key</text>";
	print BADGE "<text aria-hidden=\"true\" x=\"".(($pl + $wk + $pt*2 + $wv/2)*$scale)."\" y=\"".(($h * 0.5 + 1) * $scale)."\" fill=\"$icolour\" transform=\"scale(".(1/$scale).")\" fill-opacity=\".3\" textLength=\"".($wv*$scale)."\">$value</text>";
	print BADGE "<text x=\"".(($pl + $wk + $pt*2 + $wv/2)*$scale)."\" y=\"".(($h * 0.5) * $scale)."\" fill=\"$tcolour\" transform=\"scale(".(1/$scale).")\" textLength=\"".($wv*$scale)."\">$value</text>";
	print BADGE "</g></svg>";
	close(BADGE);

}


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

# Get the GeoJSON for the area
#   code = Area code
#   dir = Directory to geojsonl files
#   url = The URL to get the GeoJSON
sub getGeoJSON {
	my (%config) = @_;
	my (@lines,$url);
	
	if(-d $config{'dir'}){
		open(FILE,$config{'dir'}.$config{'code'}.".geojsonl");
		@lines = <FILE>;
		close(FILE);
	}else{
		$url = $config{'url'}||"https://raw.githubusercontent.com/odileeds/geography-bits/master/data/%TYPE%/%CODE%.geojsonl";
		$url =~ s/\%CODE\%/$config{'code'}/g;
		$url =~ s/\%TYPE\%/$config{'type'}/g;
		print "URL = $url\n";
		@lines = `wget -q --no-check-certificate -O- $url`;
	}
	return join("",@lines);
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


sub mapAdjPairs (&@) {
    my $code = shift;
    map { local ($a, $b) = (shift, $_[0]); $code->() } 0 .. @_-2;
}

sub Angle{
    my ($x1, $y1, $x2, $y2) = @_;
    my $dtheta = atan2($y1, $x1) - atan2($y2, $x2);
    $dtheta -= TWOPI while $dtheta >   PI;
    $dtheta += TWOPI while $dtheta < - PI;
    return $dtheta;
}

sub PtInPoly{
    my ($poly, $pt) = @_;
    my $angle=0;

    mapAdjPairs{
        $angle += Angle(
            $a->[X] - $pt->[X],
            $a->[Y] - $pt->[Y],
            $b->[X] - $pt->[X],
            $b->[Y] - $pt->[Y]
        )
    } @$poly, $poly->[0];

    return !(abs($angle) < PI);
}

sub getFeature {
	my $key = shift(@_);
	my $lat = shift(@_);
	my $lon = shift(@_);
	my @features = @_;
	
	my ($g,$n,$ok,@gs);
	for($g = 0; $g < @features; $g++){
		# Use pre-computed bounding box to do a first cut - this makes things a lot quicker
		if($lat >= $features[$g]->{'geometry'}{'bbox'}{'S'} && $lat <= $features[$g]->{'geometry'}{'bbox'}{'N'} && $lon >= $features[$g]->{'geometry'}{'bbox'}{'W'} && $lon <= $features[$g]->{'geometry'}{'bbox'}{'E'}){
			if($features[$g]->{'geometry'}->{'type'} eq "Polygon"){
				@gs = @{$features[$g]->{'geometry'}->{'coordinates'}[0]};
			}elsif($features[$g]->{'geometry'}->{'type'} eq "MultiPolygon"){
				# Only keep first item of MultiPolygon as the rest are holes
				@gs = @{$features[$g]->{'geometry'}->{'coordinates'}[0][0]};
			}
			$n = @gs;
			$ok = (PtInPoly( \@gs, [$lon,$lat]) ? 1 : 0);
			if($ok){
				return $features[$g]->{'properties'}->{$key};
			}
		}
	}
	return "";
}


1;