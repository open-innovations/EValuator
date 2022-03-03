#!/usr/bin/perl
use JSON::XS;
use Data::Dumper;

$layerfile = "www/data/domains.json";
$areafile = "www/data/areas.tsv";
$dir = "www/data/areas/";


# Load file with areas we need to create scores for
%areas;
open(FILE,$areafile);
@lines = <FILE>;
for($i = 1; $i < @lines; $i++){
	$lines[$i] =~ s/[\n\r]+//g;
	@cols = split(/\t/,$lines[$i]);
	$areas{$cols[0]} = $cols[1];
}
close(FILE);



$coder = JSON::XS->new->utf8->canonical(1);

%msoa;
if(!-e $layerfile){
	print "WARNING: No domains file at $layerfile.\n";
	exit;
}else{
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
}


foreach $a (sort(keys(%areas))){
	$adir = $dir.$a."/";

	if(!-d $adir){
		print "WARNING: There is no directory for $a. You should probably add it first with \"perl updateAreas.pl\".\n";
		exit;
	}
	
	$ifile = $adir.$a."-msoas.tsv";
	if(!-e $ifile){
		print "WARNING: There is no MSOA lookup for $a. You should probably make sure it is created with \"perl updateAreas.pl\".\n";
		exit;
	}
	
	$ofile = $adir.$a.".csv";
	if(!-e $ofile){

		open(FILE,$ifile);
		@lines = <FILE>;
		close(FILE);

		print "Saving to $ofile\n";
		open(OUT,">",$ofile);
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
}
exit;
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