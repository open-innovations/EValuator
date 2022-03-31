#!/usr/bin/perl
use JSON::XS;
use Data::Dumper;
use Cwd qw(abs_path);
use POSIX qw(strftime);

# Get the real base directory for this script
my $basedir = "./";
if(abs_path($0) =~ /^(.*\/)[^\/]*/){ $basedir = $1; }
# Step back out of the code directory
$basedir =~ s/code\/$//g;
require $basedir."code/lib.pl";


# Read in the configuration JSON file
$conf = loadConf($basedir."code/conf.json");


%months = ('Jan'=>'01','Feb'=>'02','Mar'=>'03','Apr'=>'04','May'=>'05','Jun'=>'06','Jul'=>'07','Aug'=>'08','Sep'=>'09','Oct'=>'10','Nov'=>'11','Dec'=>'12');

# Load file with areas we need to create scores for
%areas;
open(FILE,$basedir.$conf->{'areas'}{'file'});
@lines = <FILE>;
for($i = 1; $i < @lines; $i++){
	$lines[$i] =~ s/[\n\r]+//g;
	@cols = split(/\t/,$lines[$i]);
	$areas{$cols[0]} = $cols[1];
}
close(FILE);


$coder = JSON::XS->new->utf8->canonical(1);
$badges = "";
%msoa;
if(!-e $basedir.$conf->{'layers'}{'file'}){
	print "WARNING: No domains file at $basedir$conf->{'layers'}{'file'}\n";
	exit;
}else{
	open(FILE,$basedir.$conf->{'layers'}{'file'});
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
					
					$lastmod = getLastUpdateURL($src);
				}else{
					$tdir = $basedir.$conf->{'layers'}{'file'};
					$tdir =~ s/[^\/]*$//;
					if(-e $tdir.$src){
						print "Using file: $tdir$src\n";
						open(FILE,$tdir.$src);
						@lines = <FILE>;
						close(FILE);
					}
					$lastmod = strftime("%FT%H:%M",gmtime((stat($tdir.$src))[9]));
				}

				for($i = 0; $i < @lines; $i++){
					$lines[$i] =~ s/[\n\r]//g;
					($m,$score) = split(/\,/,$lines[$i]);
					if($m){
						if(!$msoa{$m}){ $msoa{$m} = {}; }
						$msoa{$m}{$json->[$c]{'layers'}[$l]{'id'}} = $score;
					}
				}
				# Save a badge for this layer
				saveBadge($basedir."badge-score-update-$json->[$c]{'layers'}[$l]{'id'}.svg","layer: $json->[$c]{'layers'}[$l]{'id'}",$lastmod);
				$badges .= ($json->[$c]{'layers'}[$l]{'update'} ? '[':'');
				$badges .= "![score update $json->[$c]{'layers'}[$l]{'id'}]($json->[$c]{'layers'}[$l]{'id'}.svg)";
				$badges .= ($json->[$c]{'layers'}[$l]{'update'} ? ']('.$json->[$c]{'layers'}[$l]{'update'}.')' : '')."\n";
			}
		}
	}
}


saveBadge($basedir."badge-score-update.svg","scores updated",strftime("%F",gmtime));
$badges = "[![score update](badge-score-update.svg)](https://github.com/open-innovations/EValuator/actions/workflows/scores.yml)\n".$badges;

# Add badge list to README.md
open(README,$basedir."README.md");
@lines = <README>;
close(README);
$str = join("",@lines);
$str =~ s/[\n]/:NEWLINE:/g;
$str =~ s/(\<\!-- Start Badges --\>).*(\<\!-- End Badges --\>)/$1\n$badges$2/g;
$str =~ s/:NEWLINE:/\n/g;
open(README,">",$basedir."README.md");
print README $str;
close(README);




foreach $a (sort(keys(%areas))){
	
	$adir = $basedir.$conf->{'areas'}{'dir'}.$a."/";

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





###########################
sub getLastUpdateURL {
	my $src = $_[0];
	my (@hlines,$lastmod,$line,$json,$str);
	$lastmod = "";

	if($src =~ /\/\/github.com\/([^\/]+)\/([^\/]+)\/raw\/[^\/]+\/(.*)/){
		# Use the Github API to find out the data about the last commit
		$src = "https://api.github.com/repos/$1/$2/commits?path=$3\&page=1\&per_page=1";
		$str = `wget -q --no-check-certificate -O- "$src"`;
		$json = $coder->decode($str);
		return $json->[0]{'commit'}{'author'}{'date'};
	}else{
		# Get the URL headers
		@hlines = `curl -sI "$src"`;
		foreach $line (@hlines){
			if($line =~ /last-modified.*([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4}) ([0-9]{2}:[0-9]{2}):[0-9]{2} ([A-Z]+)/i){
				$lastmod = "$3-".($months{substr($2,0,3)})."-".sprintf("%02d",$1)."T$4";
			}
		}
	}
	return $lastmod;
}
