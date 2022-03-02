#!/usr/bin/perl
use JSON::XS;
use Data::Dumper;

$layerfile = "layers.json";
$dir = "LAD/";

$coder = JSON::XS->new->utf8->canonical(1);

%msoa;
open(FILE,$layerfile);
@lines = <FILE>;
close(FILE);
$str = join("",@lines);

@headers;

if($str){

	$json = $coder->decode($str);

	@layers = @{$json};
	$n = @layers;

	for($l = 0; $l < $n; $l++){
		$src = $json->[$l]{'src'};
		print "$l - $src\n";
		push(@headers,$json->[$l]{'id'});
		
		if($src =~ /^http/){
			@lines = `wget -q --no-check-certificate -O- "$src"`;
		}elsif(-e $src){
			open(FILE,$src);
			@lines = <FILE>;
			close(FILE);
		}
		
		for($i = 0; $i < @lines; $i++){
			$lines[$i] =~ s/[\n\r]//g;
			($m,$score) = split(/\,/,$lines[$i]);
			if($m){
				if(!$msoa{$m}){ $msoa{$m} = {}; }
				$msoa{$m}{$json->[$l]{'id'}} = $score;
			}
		}
	}
}

opendir my $dh, $dir || die "$0: opendir: $!";
while (defined(my $name = readdir $dh)) {
	next unless -d "$dir/$name";
	next if $name eq ".";
	next if $name eq "..";

	print "$name\n";
	open(FILE,"$dir$name/$name-msoas.tsv");
	@lines = <FILE>;
	close(FILE);
	open(OUT,">","$dir$name/$name.csv");
	print OUT "MSOA";
	for($h = 0; $h < @headers; $h++){
		print OUT ",$headers[$h]";
	}
	print OUT "\n";
	foreach $line (@lines){
		($m,$name) = split(/\t/,$line);
		print OUT "$m";
		for($h = 0; $h < @headers; $h++){
			print OUT",".($msoa{$m}{$headers[$h]}||0);
		}
		print OUT "\n";
	}
	close(OUT);
}
closedir($dh);