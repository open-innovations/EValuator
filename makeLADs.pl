#!/usr/bin/perl
use Data::Dumper;
require "./lib.pl";

# Creates GeoJSON extracts per local authority for various OSM layers

$osmconvert = "osmconvert";
$osmfilter = "osmfilter";
$mode = "info";
$ogr = "ogr2ogr";
$ogrinfo = "ogrinfo";


$ddir = "www/boundaries/";
$adir = "www/data/LAD/";
$osmpbf = "raw/great-britain-latest.pbf";
$osmfile = "raw/great-britain-latest.o5m";


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
	{ 'key'=>'supermarket', 'args'=>['--keep="shop=supermarket" --drop="entrance= amenity=atm barrier="'], 'file'=>'raw/GB-supermarket.o5m', 'layers'=>['points','multipolygons','polygons'] },
	{ 'key'=>'parking', 'args'=>['--keep= --keep-ways="amenity=parking" --drop="barrier= or entrance="'], 'file'=>'raw/GB-parking.o5m', 'layers'=>['points','multipolygons','polygons'] },
	{ 'key'=>'distribution', 'args'=>['--keep="name=*Distribution*"'], 'file'=>'raw/GB-distribution.o5m' }
);

%chargepoints = (
	'url'=>'https://chargepoints.dft.gov.uk/api/retrieve/registry/format/csv',
	'raw'=>'raw/chargepoints.csv',
	'processed'=>'www/data/chargepoints.csv',
	'dir'=>'www/data/chargepoints/'
);




@files = ();
# Find sub directories in areas folder
@dirs = ();
opendir (DIR,$ddir) or die "Couldn't open directory, $!";
while ($cc = readdir DIR){

	# Only process files
	if(-d $ddir.$cc && -d $ddir.$cc && $cc !~ /^\.+$/){
		$ccspat = "";
		$ccspatcomma = "";
		$bbfile = $ddir.$cc.".yaml";

		# If there is a yaml file for this country code
		if(-e $bbfile){
			open(BOUNDS,$bbfile);
			@lines = <BOUNDS>;
			close(BOUNDS);
			foreach $line (@lines){
				$line =~ s/[\n\r]//g;
				if($line =~ /BOUNDS: +(.*)/){
					$ccspat = "$1";
				}
			}
		}

		if($ccspat){
			$ccspatcomma = $ccspat;
			$ccspatcomma =~ s/ /\,/g;
		}
		
		opendir(SUBDIR,$ddir.$cc) or die "Couldn't open directory, $!";
		while($file = readdir SUBDIR){
			if($file =~ /^(.*).geojson/){
				$code = $1;
				$bbfile = $ddir.$cc."/".$1.".yaml";
				$polyfile = $ddir.$cc."/".$1.".poly";
				$clipfile = $ddir.$cc."/".$file;
				$spat = "";
				$nm = "";
				if(-e $bbfile){
					open(BOUNDS,$bbfile);
					@lines = <BOUNDS>;
					close(BOUNDS);
					foreach $line (@lines){
						$line =~ s/[\n\r]//g;
						if($line =~ /BOUNDS: +(.*)/){
							$spat = "$1";
						}elsif($line =~ /NAME: +(.*)/){
							$nm = $1;
						}
					}
					#print "\tUsing $spat for $nm\n";
				}else{
					print "\tNo spatial bounds provided for $code (this may be slow)\n";
				}
				
				push(@files,{'cc'=>$cc,'b'=>$spat,'code'=>$code,'geojson'=>$clipfile,'poly'=>$polyfile,'yaml'=>$bbfile,'bounds'=>($spat ? "-spat $spat":""),'name'=>$nm});
			}
		}
		closedir(SUBDIR);
	}
}
closedir(DIR);



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
		print "\tAlready have SQLite file\n";
	}

	
	for($f = 0; $f < @files; $f++){
		
		$tfile = $adir.$files[$f]{'code'}.'-'.$extracts[$e]->{'key'}.".osm";
		$gfile = $adir.$files[$f]{'code'}.'-'.$extracts[$e]->{'key'}.".geojson";

		if(!-e $gfile){
			print "\tProcessing $files[$f]{'code'}: ";
			`$osmconvert $extracts[$e]->{'file'} -B=$files[$f]{'poly'} -o=$tfile`;

			# We need to find the layers
			@lines = `$ogrinfo $tfile`;
			@gfiles = ();
			@features = ();

			for($l = 0; $l < @lines; $l++){
				if($lines[$l] =~ /^[0-9]+\: ([a-z]+) /){
					$layer = $1;
					$lfile = $adir.$files[$f]{'code'}.'-'.$extracts[$e]->{'key'}."-".$layer.".geojson";
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
							
							
							push(@features,$row);
						}
					}
					if(-e $lfile){
						`rm $lfile`;
					}
				}
			}

			print "$gfile";
			open(FILE,">",$gfile);
			print FILE "{\n";
			print FILE "\"type\": \"FeatureCollection\",\n";
			print FILE "\"features\": [\n";
			# Now we need to join the GeoJSON results
			print FILE join(",\n",@features)."\n";
			print FILE "]\n";
			print FILE "}\n";
			close(FILE);
			
			if(-e $tfile){
				`rm $tfile`;
			}
			print "\n";
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
		$bfile = $ddir.$files[$f]{'cc'}."/".$files[$f]{'code'}.".geojson";
		if(!-e $gfile){
			#`rm $gfile`;
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

