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




# Define some variables
my (@cols,$row,@head,$shortid,$tinyid,$c,%nspeed,$i,%ids,$added,%tinyids,$msoadir,$csv,%chargepoints,@lines,$str,@msoafeatures,$f,%heads,$lat,$lon,$msoa,%msoalookup,$ofile,$hasmsoa,@rows,$r);


# Define some paths
%chargepoints = (
	'url'=>'https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv',
	'raw'=>$basedir.'raw/chargepoints.csv',
	'processed'=>$basedir.'docs/data/chargepoints.csv',
	'dir'=>$basedir.'docs/data/chargepoints/'
);



# Create the CSV parser
$csv = Text::CSV->new ({ binary => 1 });


# Load the MSOA features
@msoafeatures = loadFeatures($basedir.$conf->{'geojson'}{'MSOA'}{'all'});


# Step 1: Get the chargepoints data
if(getFile($chargepoints{'url'},$chargepoints{'raw'},86400)){

	print "Got chargepoints: $chargepoints{'raw'}\n";

	# Step 2: Read in the CSV
	$i = 0;
	$hasmsoa = 0;
	@head = ();
	print "Reading $chargepoints{'raw'}\n";
	open my $fh,'<:encoding(utf8)',$chargepoints{'raw'};
	print "Saving individual chargepoint JSON in $chargepoints{'dir'}\n";
	print "Processing CSV...\n";
	while($row = $csv->getline($fh)){
		@cols = @$row;

		if($i == 0){
			@head = @cols;
			for($c = 0; $c < @head; $c++){
				$heads{$head[$c]} = $c;
			}
		}else{
			$shortid = substr($cols[$heads{'chargeDeviceID'}],0,8);
			$tinyid = substr($shortid,0,3);

			if($i % 1000 == 0){
				print "\t$i ($hasmsoa with MSOAs identified)\n";
			}

			if(length($shortid) == 8){
				%nspeed = ('S'=>0,'F'=>0,'R'=>0);
				for($c = 0; $c < @head; $c++){
					if($head[$c] =~ /connector[0-9]*RatedOutputKW/ && $cols[$c]){
						if($cols[$c] < 7){ $nspeed{'S'}++; }
						if($cols[$c] >= 7 && $cols[$c] < 30){ $nspeed{'F'}++; }
						if($cols[$c] >= 30){ $nspeed{'R'}++; }
					}
				}

				$lat = $cols[$heads{'latitude'}];
				$lon = $cols[$heads{'longitude'}];

				$msoa = getFeature("msoa11cd",$lat,$lon,@msoafeatures);
				if($msoa){
					if(!$msoalookup{$msoa}){ $msoalookup{$msoa} = 0; }
					#$msoalookup{$msoa} += ($nspeed{'S'}+$nspeed{'F'}+$nspeed{'R'});
					$msoalookup{$msoa}++;
					$hasmsoa++;
				}

				push(@rows,$shortid.",".($i == 0 ? $lat : sprintf("%0.5f",$lat)).",".($i == 0 ? $lon : sprintf("%0.5f",$lon)).",".($nspeed{'S'}||"").",".($nspeed{'F'}||"").",".($nspeed{'R'}||""));

				if($shortid && $shortid =~ /^[0-9a-z]+$/){
					if($ids{$shortid}){
						print "WARNING: $shortid already used.\n";
					}
					# Save individual chargepoint JSON files
					open(CP,">",$chargepoints{'dir'}.$shortid.".json");
					print CP "{\n";
					$added = 0;
					for($c = 0; $c < @head; $c++){
						if($c > 0){ print CP ",\n"; }
						print CP "\t\"$head[$c]\": ";
						if($cols[$c]){
							$cols[$c] =~ s/\t//g;
							if($cols[$c] !~ /^[\+\-]?[0-9\.]*$/ || $head[$c] =~ /Telephone/i){
								print CP "\"".($cols[$c]||"null")."\"";
							}else{
								print CP ($cols[$c]||"null");
							}
						}else{
							print CP "null";
						}
					}
					print CP "\n}\n";
					close(CP);
					$ids{$shortid} = 1;
					if(!$tinyids{$tinyid}){ $tinyids{$tinyid} = 0; }
					$tinyids{$tinyid}++;
				}else{
					print "WARNING: No short ID for $cols[0] ($shortid) on line $i.\n";
				}
			}
		}

		$i++;
	}
	close($fh);
	
	
	# Save the file ordered by chargepoint short ID
	print "Saving $chargepoints{'processed'}\n";
	open(OUT,">:encoding(utf8)",$chargepoints{'processed'});
	@rows = sort(@rows);
	print OUT "shortID,latitude,longitude,Slow,Fast,Rapid\n";
	for($r = 0; $r < @rows; $r++){
		print OUT "$rows[$r]\n";
	}
	close(OUT);
		
	# Now save the MSOA-based layer
	$ofile = $basedir.$conf->{'layers'}{'dir'}."chargepoints.csv";
	print "Saving $ofile\n";
	open(FILE,">",$ofile);
	print FILE "msoa,chargepoints\n";
	foreach $msoa (sort(keys(%msoalookup))){
		print FILE "$msoa,$msoalookup{$msoa}\n";
	}
	close(FILE);

	# Make a badge
	my $pc = 100*$hasmsoa/$i;
	saveBadge($basedir."badge-chargepoints.svg","chargepoints",sprintf("%d",$pc)."%",($pc > 50 ? "SUCCESS" : "FAIL"));

}else{
	print "ERROR: No file $chargepoints{'raw'}\n";
	saveBadge($basedir."badge-chargepoints.svg","chargepoints","failing","FAIL");
}







#############################
# SUBROUTINES

sub getFile {
	my ($url,$file,$refreshtime) = @_;
	my ($age,$days,@lines,$str);
	if(-e $file){
		$days = -M "$file";
		$age = $days*60*60*24;
	}

	if(!-e $file || $age > $refreshtime){
		print "Getting $file from $url\n";
		@lines = `wget -q --no-check-certificate -O- "$url"`;
		$str = join("",@lines);

		# Fix newline inconsistencies
#		$str =~ s/\r([^\n])/\r\n$1/g;

		# Save fixed file
		open(FILE,">:encoding(utf8)",$file);
		print FILE $str;
		close(FILE);
	}
	return (-e $file);
}


