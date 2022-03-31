#!/usr/bin/perl
use Data::Dumper;
use Cwd qw(abs_path);

# Get the real base directory for this script
my $basedir = "./";
if(abs_path($0) =~ /^(.*\/)[^\/]*/){ $basedir = $1; }
# Step back out of the code directory
$basedir =~ s/code\/$//g;
require $basedir."code/lib.pl";


# Read in the configuration JSON file
$conf = loadConf($basedir."code/conf.json");




# Read in the user-set areas
%areas;
if(!-e $basedir.$conf->{'areas'}{'file'}){
	print "WARNING: The area file doesn't exist ($basedir$conf->{'areas'}{'file'}). It should be a TSV file with the ONS code in the first column and the name in the second column.\n";
	exit;
}
open(FILE,$basedir.$conf->{'areas'}{'file'});
@lines = <FILE>;
for($i = 1; $i < @lines; $i++){
	$lines[$i] =~ s/[\n\r]+//g;
	@cols = split(/\t/,$lines[$i]);
	$areas{$cols[0]} = $cols[1];
}
close(FILE);




# Download the House of Commons Library MSOA name lookup
if(!-e $basedir.$conf->{'lookup'}{'names'}){
	print "Downloading MSOA names file to $basedir$conf->{'lookup'}{'names'}\n";
	`curl -o "$basedir$conf->{'lookup'}{'names'}" $conf->{'lookup'}{'namesurl'}`;
}

# Load in the House of Commons Library MSOA name lookup
print "Reading MSOA name lookup\n";
open(FILE,$basedir.$conf->{'lookup'}{'names'});
while(<FILE>){
	#msoa11cd,msoa11nm,msoa11nmw,msoa11hclnm,msoa11hclnmw,Laname
	#E02006534,Adur 001,Adur 001,Hillside,,Adur
	$line = $_;
	if($line){
		$line =~ s/[\n\r]+//g;
		($msoa11cd,$msoa11nm,$msoa11nmw,$msoa11hclnm,$msoa11hclnmw,$Laname) = split(/,/,$line);
		if($msoa11cd !~ /msoa11cd/ && $msoa11hclnm){
			$msoa11hclnm =~ s/(^\"|\"$)//g;
			$msoa{$msoa11cd} = {'name'=>$msoa11hclnm};
		}
	}
}
close(FILE);





%lookup;
open(FILE,$basedir.$conf->{'lookup'}{'file'});
@lines = <FILE>;
for($i = 0; $i < @lines; $i++){
	$lines[$i] =~ s/[\n\r]+//g;
	#MSOA11CD	MSOA11NM	MSOA11HCLNM	LAD21CD	LAD21NM	CAUTH21CD	CAUTH21NM	Area
	#E02000001	City of London 001	City of London	E09000001	City of London			46155312.6057659
	@cols = split(/\t/,$lines[$i]);
	#print "$cols[0]\t$cols[2]\n";
	if($i == 0){
		@header = @cols;
	}else{

		$msoa11cd = $cols[0];

		if($msoa11cd){

			for($c = 1; $c < @header; $c++){
				if($header[$c] =~ /CD$/){
					if($areas{$cols[$c]}){
						if(!$lookup{$cols[$c]}){
							$lookup{$cols[$c]} = {'msoas'=>{},'name'=>$cols[$c+1]};
						}
						if(!$lookup{$cols[$c]}{'msoas'}{$msoa11cd}){ $lookup{$cols[$c]}{'msoas'}{$msoa11cd} = 0; }
						$lookup{$cols[$c]}{'msoas'}{$msoa11cd}++;
					}
				}
			}
		}

	}
}
close(FILE);




# Create the area to MSOA lookup
print "Saving area lookup to $basedir$conf->{'lookup'}{'area'}\n";
open(LOOKUP,">",$basedir.$conf->{'lookup'}{'area'});
print LOOKUP "Area\tArea name\tMSOAs\n";
foreach $l (sort(keys(%lookup))){
	print LOOKUP "$l\t$lookup{$l}{'name'}\t";
	print LOOKUP join(";",sort(keys(%{$lookup{$l}{'msoas'}})));
	print LOOKUP "\n";
}
close(LOOKUP);




# Create the GeoJSON files for each area
foreach $a (sort(keys(%areas))){
	
	if(!$lookup{$a}){
		print "WARNING: The area $a doesn't appear in the lookup.\n";
	}else{

		print "$a:\n";

		# Step 1: Make the directory if it doesn't already exist
		$adir = $basedir.$conf->{'areas'}{'dir'}.$a."/";
		if(!-d $adir){
			print "\tMaking directory $adir\n";
			`mkdir $adir`;
		}


		# Step 2: Store MSOA lookup for this area
		print "\tSaving MSOA lookup to $adir$a-msoas.tsv\n";
		open(LOOKUP,">",$adir."$a-msoas.tsv");
		@msoas = sort(keys(%{$lookup{$a}{'msoas'}}));
		for($m = 0; $m < @msoas; $m++){
			print LOOKUP "$msoas[$m]\t$msoa{$msoas[$m]}{'name'}\n";
		}
		close(LOOKUP);



		# Step 3: Create the GeoJSON
		$gfile = $basedir.$conf->{'areas'}{'dir'}."$a/$a.geojson";
		$geojson = "";
		for($m = 0; $m < @msoas; $m++){
			$str = getGeoJSON(
				'code'=>$msoas[$m],
				'type'=>'MSOA11CD',
				'url'=>$conf->{'geojson'}{$type}{'url'},
				'dir'=>$basedir.$conf->{'geojson'}{'MSOA'}{'dir'}
			);
			$str =~ s/[\n\r]//g;
			$str =~ s/(,"msoa11nm":"[^\"]*")/$1,"msoa11hclnm":"$msoa{$msoas[$m]}{'name'}"/g;
			$str =~ s/(,"msoa11nmw":"[^\"]*")//;
			$geojson .= ($geojson ? ",\n":"").$str;
		}
		if($geojson){
			print "\tSaving GeoJSON to $gfile\n";
			open(GEO,">",$gfile);
			print GEO "{\n";
			print GEO "\"type\": \"FeatureCollection\",\n";
			print GEO "\"features\":[\n";
			print GEO $geojson."\n";
			print GEO "]\n";
			print GEO "}\n";
			close(GEO);
		}else{
			print "\tWARNING: No GeoJSON for $l ($gfile)\n";
		}
	}
}

