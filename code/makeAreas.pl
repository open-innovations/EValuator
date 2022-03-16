#!/usr/bin/perl
use Data::Dumper;
require "./lib.pl";

# Creates GeoJSON extracts per local authority for various OSM layers

$osmconvert = "osmconvert";
$osmfilter = "osmfilter";
$ogr = "ogr2ogr";
$ogrinfo = "ogrinfo";

$rootdir = "../";
$adir = $rootdir."www/data/areas/";
$osmpbf = $rootdir."raw/great-britain-latest.pbf";
$osmfile = $rootdir."raw/great-britain-latest.o5m";
# Directories to look for boundaries
@boundarydirs = ($rootdir."../geography-bits/data/LAD21CD/");


# Download the GB extract
if(!-e $osmfile && !-e $osmpbf){
	`wget "https://download.geofabrik.de/europe/great-britain-latest.osm.pbf" -o $osmpbf`;
}

# Convert it to o5m to be more efficient
if(!-e $osmfile){
	print "Converting to o5m\n";
	`$osmconvert -o=$osmfile $osmpbf`;
}

if(!-d $adir){
	`mkdir $adir`;
}

@extracts = (
	{ 'key'=>'supermarket', 'args'=>['--keep="shop=supermarket" --drop="entrance= amenity=atm barrier="'], 'file'=>$rootdir.'raw/GB-supermarket.o5m', 'layers'=>['points','multipolygons','polygons'] },
	{ 'key'=>'parking', 'args'=>['--keep= --keep-ways="amenity=parking" --drop="barrier= or entrance="'], 'file'=>$rootdir.'raw/GB-parking.o5m', 'layers'=>['points','multipolygons','polygons'] },
	{ 'key'=>'distribution', 'args'=>['--keep="name=*Distribution*" --drop="amenity=loading_dock"'], 'file'=>$rootdir.'raw/GB-distribution.o5m' }
);

%chargepoints = (
	'url'=>'https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv',
	'raw'=>$rootdir.'raw/chargepoints.csv',
	'processed'=>$rootdir.'www/data/chargepoints.csv',
	'dir'=>$rootdir.'www/data/chargepoints/'
);




@files = ();
# Find sub directories in areas folder


for($d = 0; $d < @boundarydirs; $d++){
	opendir(SUBDIR,$boundarydirs[$d]) or die "Couldn't open directory, $!";
	while($file = readdir SUBDIR){
		if($file =~ /^(.*).geojsonl/){
			$code = $1;
			push(@files,{'code'=>$code,'geojson'=>$boundarydirs[$d].$file,'dir'=>$boundarydirs[$d]});
		}
	}
	closedir(SUBDIR);
}



# Now process each extract
for($e = 0; $e < @extracts; $e++){
	
	$infile = $osmfile;
	$outfile = $extracts[$e]->{'file'};
	$outfile =~ s/\./-step0./;
	print "$extracts[$e]->{'file'}:\n";
	if(!-e $extracts[$e]->{'file'}){
		$n = @{$extracts[$e]->{'args'}};
		for($a = 0; $a < $n; $a++){
			$b = $a+1;
			$outfile =~ s/-step[0-9]*/-step$b/;
			print "\tExtract $extracts[$e]->{'args'}[$a] from $infile to $outfile\n";
			`$osmfilter $infile $extracts[$e]->{'args'}[$a] > $outfile`;
			if($n > 1 && $infile ne $osmfile){
			#	`rm $infile`;
			}
			$infile = $outfile;
		}
		if($outfile ne $extracts[$e]->{'file'}){
			`mv $outfile $extracts[$e]->{'file'}`;
		}
	}

	$filesql = "$extracts[$e]->{'file'}\.sqlite";
	$filepbf = "$extracts[$e]->{'file'}\.pbf";

	# Convert to SQLite
	if(!-e $filesql){
		print "\tConverting $extracts[$e]->{'file'} to SQLite file $filesql\n";
		`$ogr $filesql $extracts[$e]->{'file'}`;
	}else{
		print "\tAlready have SQLite file ($filesql)\n";
	}

	
	for($f = 0; $f < @files; $f++){
		
		$tfile = $adir.$files[$f]{'code'}.'-'.$extracts[$e]->{'key'}.".sqlite";
		$cfile = $adir.$files[$f]{'code'}.'-'.$extracts[$e]->{'key'}."-cut.sqlite";
		$gfile = $adir.$files[$f]{'code'}.'/'.$files[$f]{'code'}.'-'.$extracts[$e]->{'key'}.".geojson";

		if(!-d $adir.$files[$f]{'code'}){
			`mkdir $adir$files[$f]{'code'}`;
		}

		if(!-e $gfile){
			
			print "\tProcessing $files[$f]{'code'}... ";
			
			# Create a temporary clipped file based on bounding box (to speed things up)
			$extent = `ogrinfo -so -al $files[$f]{'geojson'} | grep Extent`;
			if($extent =~ /\(([0-9\.\-\+]+), ([0-9\.\-\+]+)\) - \(([0-9\.\-\+]+), ([0-9\.\-\+]+)\)/){
				`$osmconvert $extracts[$e]->{'file'} -b=$1,$2,$3,$4 --complete-ways -o=$cfile`;
				`ogr2ogr -f SQLite $tfile $cfile -clipsrc $files[$f]{'geojson'} 2>&1`;
				`rm $cfile`;
			}

			# We need to find the layers
			@lines = `$ogrinfo $tfile`;
			@gfiles = ();
			@features = ();

			for($l = 0; $l < @lines; $l++){
				if($lines[$l] =~ /^[0-9]+\: ([a-z]+) /){
					$layer = $1;
					$lfile = $adir.$files[$f]{'code'}.'/'.$files[$f]{'code'}.'-'.$extracts[$e]->{'key'}."-".$layer.".geojson";
					# Remove any existing layer file
					if(-e $lfile){
						`rm $lfile`;
					}
					# Extract the layer
					`$ogr -f GeoJSON $lfile -lco "COORDINATE_PRECISION=5" -skipfailures $tfile $layer 2>&1`;
					push(@gfiles,$lfile);
					open(FILE,$lfile);
					@flines = <FILE>;
					close(FILE);
					for($j = 0; $j < @flines; $j++){
						$row = $flines[$j];
						if($row =~ /{ "type": "Feature"/){
							$row =~ s/\,?[\n\r]+//g;
							push(@features,$row);
						}
					}
					if(-e $lfile){
						`rm $lfile`;
					}
				}
			}

			open(FILE,">",$gfile);
			print FILE "{\n";
			print FILE "\"type\": \"FeatureCollection\",\n";
			print FILE "\"features\": [\n";
			# Now we need to join the GeoJSON results
			print FILE join(",\n",@features)."\n";
			print FILE "]\n";
			print FILE "}\n";
			close(FILE);

			trimGeoJSONFile($gfile);
			
			if(-e $tfile){
				`rm $tfile`;
			}
			print "saved to $gfile\n";
		}
	}
}



# Chargepoints
if(getFile($chargepoints{'url'},$chargepoints{'raw'},86400)){
	print "Got chargepoints: $chargepoints{'raw'}\n";

	$sqlfile = $chargepoints{'raw'}.".sqlite";
	if(!-e $sqlfile){
		$layer = $chargepoints{'raw'};
		$layer =~ s/\.([^\.]*)$//;
		# Convert the CSV into SQLite (for speed of access)
		# We want to drop any chargepoints that have no geometry (there are 2)
		`ogr2ogr -f SQLite $sqlfile $chargepoints{'raw'} -dialect sqlite -sql "select * from $layer where geometry is not null" -oo X_POSSIBLE_NAMES=longitude -oo Y_POSSIBLE_NAMES=latitude -oo KEEP_GEOM_COLUMNS=NO -a_srs 'EPSG:4326'`;
	}

	for($f = 0; $f < @files; $f++){
		$gfile = $adir.$files[$f]{'code'}."-chargepoints.geojson";
		$bfile = $files[$f]{'geojson'};
		if(!-e $gfile){
			print "\tCreating chargepoints for $files[$f]{'code'} using $bfile\n";
			`ogr2ogr -f GeoJSON $gfile 	$sqlfile -clipsrc $bfile`;
			trimGeoJSONFile($gfile);
		}
	}
}







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

