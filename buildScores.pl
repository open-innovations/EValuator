#!/usr/bin/perl
use JSON::XS;
use Data::Dumper;

$layerfile = "www/data/layers.json";
$dir = "www/data/areas/";

$coder = JSON::XS->new->utf8->canonical(1);

%msoa;
open(FILE,$layerfile);
@lines = <FILE>;
close(FILE);
$str = join("",@lines);

@headers;

if($str){

	$json = $coder->decode($str);

	@categories = @{$json};
	for($c = 0; $c < @categories; $c++){
		
		@layers = @{$json->[$c]{'layers'}};
		$n = @layers;

		for($l = 0; $l < $n; $l++){
			$src = $json->[$c]{'layers'}[$l]{'src'};
	#		print "$l - $src\n";
			push(@headers,$json->[$c]{'layers'}[$l]{'id'});

			@lines = "";

			if($src =~ /^http/){
				print "Downloading file from: $src\n";
				@lines = `wget -q --no-check-certificate -O- "$src"`;
			}else{
				$tdir = $layerfile;
				$tdir =~ s/[^\/]*$//;
				if(-e $tdir.$src){
					print "Using file: $tdir$src\n";
					open(FILE,$tdir.$src);
					@lines = <FILE>;
					close(FILE);
				}
			}

			for($i = 0; $i < @lines; $i++){
				$lines[$i] =~ s/[\n\r]//g;
				($m,$score) = split(/\,/,$lines[$i]);
				if($m){
					if(!$msoa{$m}){ $msoa{$m} = {}; }
					$msoa{$m}{$json->[$c]{'layers'}[$l]{'id'}} = $score;
				}
			}
		}
	}
}

opendir my $dh, $dir || die "$0: opendir: $!";
while (defined(my $name = readdir $dh)) {
	next unless -d "$dir$name";
	next if $name eq ".";
	next if $name eq "..";

	open(FILE,"$dir$name/$name-msoas.tsv");
	@lines = <FILE>;
	close(FILE);
	print "Saving to file $dir$name/$name.csv\n";
	open(OUT,">","$dir$name/$name.csv");
	print OUT "MSOA,Name";
	for($h = 0; $h < @headers; $h++){
		print OUT ",$headers[$h]";
	}
	print OUT "\n";
	foreach $line (@lines){
		$line =~ s/[\n\r]//g;
		($m,$name) = split(/\t/,$line);
		print OUT "$m,\"$name\"";
		for($h = 0; $h < @headers; $h++){
			print OUT",".($msoa{$m}{$headers[$h]}||0);
		}
		print OUT "\n";
	}
	close(OUT);
}
closedir($dh);