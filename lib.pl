#!/usr/bin/perl

sub trimGeoJSONFile {
	my $file = $_[0];
	my $out = "";
	my ($row,$comma);

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
			$row =~ s/" \}, "/"\},"/g;
			
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

sub getMSOAWKT {
	my $msoa = $_[0];
	my (@lines,$out);

	open(FILE,$msoadir.$msoa.".geojsonl");
	@lines = <FILE>;
	close(FILE);
	
	if($lines[0] =~ /"type":"MultiPolygon","coordinates":([^\}]*)/){
		$out = $1;
		$out =~ s/\[ ?([0-9\-\.]+), ?([0-9\-\.]+) ?\]/$1 $2/g;
		$out =~ s/\[/\(/g;
		$out =~ s/\]/\)/g;
		$out = "MULTIPOLYGON ".$out;
	}else{
		print "WARNING: $msoa doesn't seem to contain a MultiPolygon.\n";
	}
	return $out;
}
1;