#!/usr/bin/perl
use Text::CSV;
use Data::Dumper;
binmode(STDOUT, "encoding(UTF-8)");

$rootdir = "../";
%data = (
	'chargepoint'=>{
		'url'=>'https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv',
		'raw'=>$rootdir.'raw/chargepoints.csv',
		'processed'=>$rootdir.'www/data/chargepoints.csv',
		'dir'=>$rootdir.'www/data/chargepoints/'
		'dir'=>$rootdir.'www/data/chargepoints/'
	}
);


my $csv = Text::CSV->new ({ binary => 1 });

my %ids;
my %tinyids;

# Chargepoints
if(getFile($data{'chargepoint'}{'url'},$data{'chargepoint'}{'raw'},86400)){
	print "Got chargepoints: $data{'chargepoint'}{'raw'}\n";
	$i = 0;
	@head = ();
	open my $fh,'<:encoding(utf8)',$data{'chargepoint'}{'raw'};
	open(OUT,">:encoding(utf8)",$data{'chargepoint'}{'processed'});
	while (my $row = $csv->getline($fh)){
		my @cols = @$row;

		if($i == 0){
			@head = @cols;
			print OUT "shortID,".$cols[3].",".$cols[4].",Slow,Fast,Rapid\n";
		}else{
			$shortid = substr($cols[0],0,8);
			$tinyid = substr($cols[0],0,3);
			if(length($shortid) == 8){
				%nspeed = {'S'=>0,'F'=>0,'R'=>0};
				for($c = 0; $c < @head; $c++){
					if($head[$c] =~ /connector[0-9]*RatedOutputKW/ && $cols[$c]){
						if($cols[$c] < 7){ $nspeed{'S'}++; }
						if($cols[$c] >= 7 && $cols[$c] < 30){ $nspeed{'F'}++; }
						if($cols[$c] >= 30){ $nspeed{'R'}++; }
					}
				}
				
				print OUT $shortid.",".($i == 0 ? $cols[3] : sprintf("%0.5f",$cols[3])).",".($i == 0 ? $cols[4] : sprintf("%0.5f",$cols[4])).",$nspeed{'S'},$nspeed{'F'},$nspeed{'R'}\n";
				if($shortid && $shortid =~ /^[0-9a-z]+$/){
					if($ids{$shortid}){
						print "WARNING: $shortid already used.\n";
					}
					open(CP,">",$data{'chargepoint'}{'dir'}.$shortid.".json");
					print CP "{\n";
					$added = 0;
					for($c = 0; $c < @head; $c++){
						if($c > 0){ print CP ",\n"; }
						$cols[$c] =~ s/\t//g;
						print CP "\t\"$head[$c]\": ".($cols[$c] !~ /^[\+\-]?[0-9\.]*$/ || $head[$c] =~ /Telephone/i ? "\"$cols[$c]\"": $cols[$c]||"null");
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
	close($csvdata);
	close(OUT);
}

#$n = 0;
#foreach $id (sort{ $tinyids{$a} <=> $tinyids{$b}}(keys(%tinyids))){
#	print "$id - $tinyids{$id}\n";
#	$n++;
#}
#print "$n tinyids.\n";
#print Dumper %tinyids;


#############################
# SUBROUTINES

sub getFile {
	my ($url,$file,$refreshtime) = @_;
	my ($age,$days,@lines,$str);
	if(-e $file){
		my $days = -M "$file";
		$age = $days*60*60*24;
	}

	if(!-e $file || $age > $refreshtime){
		print "Getting $file from $url\n";
		@lines = `wget -q --no-check-certificate -O- "$url"`;
		$str = join("",@lines);

		# Fix newline inconsistencies
		$str =~ s/\r([^\n])/\r\n$1/g;

		# Save fixed file
		open(FILE,">:encoding(utf8)",$file);
		print FILE $str;
		close(FILE);
	}
	return (-e $file);
}