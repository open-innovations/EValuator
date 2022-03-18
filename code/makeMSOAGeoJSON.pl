#!/usr/bin/perl
# Create MSOA-level extracts of the data layers by clipping the LAD-level extracts with the MSOA boundary

use Data::Dumper;
# Get the real base directory for this script
my $basedir = "./";
if((readlink $ENV{'SCRIPT_FILENAME'} || $0) =~ /^(.*\/)[^\/]*/){ $basedir = $1; }
require "./".$basedir."lib.pl";


# Read in the configuration JSON file
$conf = loadConf($basedir."conf.json");

# Step up a directory
$basedir = "../".$basedir;



%lookup = getLookup($basedir.$conf->{'lookup'}{'file'});
@msoaorder = sort(keys(%{$lookup{'MSOA'}}));
@ladorder = sort(keys(%{$lookup{'LAD'}}));



$msoadir = $basedir.$conf->{'geojson'}{'MSOA'}{'dir'};
if(!-d $msoadir){
	print "ERROR: $msoadir doesn't exist. This should contain all the geography bits https://github.com/odileeds/geography-bits/\n";
	exit;
}


if(!-d $basedir.$conf->{'areas'}{'dir'}){
	makeDir($basedir.$conf->{'areas'}{'dir'});
}


# Make the output directory if it doesn't already exist
$dir = $basedir."tmp/MSOA/";
makeDir($dir);



# Loop over MSOAs (ordered)
for($m = 0; $m < @msoaorder; $m++){

	# Get the MSOA code
	$msoa = $msoaorder[$m];

	# Get the boundary file
	$bfile = $msoadir.$msoa.".geojsonl";

	
	if(!-e $bfile){
			print "WARNING: No GeoJSON boundary for MSOA $msoa.\n";
	}else{

		for($k = 0; $k < @{$conf->{'layers'}{'keys'}}; $k++){

			$layer = $conf->{'layers'}{'keys'}[$k];
			$gfile = $dir.$msoa."-$layer.geojson";
			$lfile = $basedir.$conf->{'areas'}{'dir'}.$lookup{'MSOA'}{$msoa}."/$lookup{'MSOA'}{$msoa}-$layer.geojson";

			if(-e $lfile){
				if(!-e $gfile){
					print "Creating $gfile\n";
					`ogr2ogr -f GeoJSON $gfile $lfile -clipsrc $bfile 2>&1`;
					trimGeoJSONFile($gfile);
				}
			}else{
				print "No file $lfile (you should run the other script first)\n";
			}
		}
	}
}



################################

sub getLookup {
	my $file = $_[0];
	my (%lookup,$i,$line,$msoa,$name,$junk,$lad);

	%lookup = ('area'=>{},'MSOA'=>{});

	# Open the Area/MSOA lookup file
	open(FILE,$file) || error("Couldn't open the file");
	$i = 0;
	while(<FILE>){
		$line = $_;
		if($i > 0){
			$line =~ s/[\n\r]//;
			#MSOA11CD	MSOA11NM	MSOA11HCLNM	LAD21CD	LAD21NM	CAUTH21CD	CAUTH21NM	Area
			#E02000001	City of London 001	City of London	E09000001	City of London			46155312.6057659
			($msoa,$junk,$name,$lad,$junk) = split(/\t/,$line);
			
			$lookup{'MSOA'}{$msoa} = $lad;
			if(!$lookup{'LAD'}{$lad}){ $lookup{'LAD'}{$lad} = (); }
			push(@{$lookup{'LAD'}{$lad}},$msoa);
		}
		$i++;
	}
	return %lookup;
}
