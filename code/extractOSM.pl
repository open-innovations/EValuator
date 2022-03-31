#!/usr/bin/perl
# Creates GeoJSON extracts per local authority for various OSM layers
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


$rebuild = ($ARGV[0] eq "rebuild");



open(FILE,$basedir.$conf->{'lookup'}{'area'});
@lines = <FILE>;
close(FILE);
%areas;
for($i = 0; $i < @lines ; $i++){
	$lines[$i] =~ s/[\n\r]//g;
	($id,$name,$list) = split(/\t/,$lines[$i]);
	$areas{$id} = {'name'=>$name};
	@{$areas{$id}{'msoas'}} = split(/;/,$list);
}

# Define some command line tools
$osmconvert = "osmconvert";
$osmfilter = "osmfilter";
$ogr = "ogr2ogr";
$ogrinfo = "ogrinfo";

# If we don't have the o5m version of the file
if(!-e $basedir.$conf->{'osm'}{'o5m'}){

	# Do we need to download the source PBF file?
	if(!-e $basedir.$conf->{'osm'}{'file'}){
		print "Downloading GB latest from $conf->{'osm'}{'url'} to $basedir$conf->{'osm'}{'file'}...\n";
		`curl -o "$basedir$conf->{'osm'}{'file'}" $conf->{'osm'}{'url'}`;
	}

	# Convert it to o5m to be more efficient
	print "Converting to o5m ($basedir$conf->{'osm'}{'o5m'})\n";
	`$osmconvert -o=$basedir$conf->{'osm'}{'o5m'} $basedir$conf->{'osm'}{'file'}`;
}


# Create the areas directory if it doesn't exist
if(!-d $basedir.$conf->{'areas'}{'dir'}){
	print "Creating directory $basedir$conf->{'areas'}{'dir'} for areas...\n";
	`mkdir $basedir$conf->{'areas'}{'dir'}`;
}



# Find all the area GeoJSON files (using the geography-bits repo)
foreach $code (sort(keys(%areas))){
	$type = "";
	foreach $type (keys(%{$conf->{'geojson'}})){
		if(-e $basedir.$conf->{'geojson'}{$type}{'dir'}.$code.".geojsonl"){
			push(@files,{'code'=>$code,'geojson'=>$basedir.$conf->{'geojson'}{$type}{'dir'}.$file,'poly'=>$basedir.$conf->{'geojson'}{$type}{'dir'}.$code.".poly",'dir'=>$basedir.$conf->{'geojson'}{$type}{'dir'}});
		}
	}
}





# Now process each extract
foreach $key (sort(keys(%{$conf->{'osm'}{'extracts'}}))){
	
	$infile = $basedir.$conf->{'osm'}{'o5m'};
	$outfile = $basedir.$conf->{'osm'}{'extracts'}{$key}{'file'};

	print "Layer: $key\n";

	if($rebuild && -e $outfile){
		`rm $outfile`;
	}

	# Only create the output file if we don't already have it
	if(!-e $outfile){

		print "\t$infile -> $outfile\n";

		$outfile =~ s/\.o5m/-step0.o5m/;

		$n = @{$conf->{'osm'}{'extracts'}{$key}{'steps'}};

		for($a = 0; $a < $n; $a++){
			$b = $a+1;
			$outfile =~ s/-step[0-9]*/-step$b/;
			print "\tStep $a: $conf->{'osm'}{'extracts'}{$key}{'steps'}[$a]\n";
			`$osmfilter $infile $conf->{'osm'}{'extracts'}{$key}{'steps'}[$a] > $outfile`;
			if($n > 1 && $infile ne $basedir.$conf->{'osm'}{'o5m'}){
				`rm $infile`;
			}
			$infile = $outfile;
		}
		if($outfile ne $basedir.$conf->{'osm'}{'extracts'}{$key}{'file'}){
			`mv $outfile $basedir$conf->{'osm'}{'extracts'}{$key}{'file'}`;
		}
	}else{
		print "\tSkip making extract\n";
	}

	$filesql = $basedir.$conf->{'osm'}{'extracts'}{$key}{'file'}.".sqlite";
	$filepbf = $basedir.$conf->{'osm'}{'extracts'}{$key}{'file'}.".pbf";

	# Convert to SQLite
	if($rebuild && -e $filesql){
		 `rm $filesql`;
	}
	if(!-e $filesql){
		print "\tConverting $basedir$conf->{'osm'}{'extracts'}{$key}{'file'} to SQLite file $filesql\n";
		`$ogr $filesql $basedir$conf->{'osm'}{'extracts'}{$key}{'file'}`;
	}else{
		#print "\tAlready have SQLite file ($filesql)\n";
	}

	for($f = 0; $f < @files; $f++){
		
		$adir = $basedir.$conf->{'areas'}{'dir'}.$files[$f]{'code'}."/";

		# Check if the directory exists for this area
		if(!-d $adir){
			print "Creating directory for $files[$f]{'code'}.\n";
			`mkdir $adir`;
		}


		$tfile = $adir.$files[$f]{'code'}."-".$key.".sqlite";
		$cfile = $adir.$files[$f]{'code'}."-".$key."-cut.sqlite";
		$gfile = $adir.$files[$f]{'code'}.'-'.$key.".geojson";


		if(!-e $gfile || $rebuild || $conf->{'osm'}{'extracts'}{$key}{'rebuild'}){
			
			print "\t$files[$f]{'code'}\n";
			

			if(-e $files[$f]{'poly'}){

				print "\t\tClip with $files[$f]{'poly'}...";
				`$osmconvert $basedir$conf->{'osm'}{'extracts'}{$key}{'file'} -B=$files[$f]{'poly'}  --complete-ways -o=$cfile`;
				`$ogr -f SQLite $tfile $cfile 2>&1`;

			}else{

				# Find the bounding box of the area
				$extent = `ogrinfo -so -al $files[$f]{'geojson'} | grep Extent`;
				if($extent =~ /\(([0-9\.\-\+]+), ([0-9\.\-\+]+)\) - \(([0-9\.\-\+]+), ([0-9\.\-\+]+)\)/){

					# Create a temporary clipped file based on bounding box (this is quicker than a polygon clip so helps reduce the data for that step)
					#print "\t\tExtract data for bounding box of area\n";
					print "\t\tClip with $files[$f]{'geojson'}...";
					`$osmconvert $basedir$conf->{'osm'}{'extracts'}{$key}{'file'} -b=$1,$2,$3,$4 --complete-ways -o=$cfile`;
					`$ogr -f SQLite $tfile $cfile -clipsrc $files[$f]{'geojson'} 2>&1`;
				}else{
					print "\t\tERROR: No bounding box for $key...";
				}
			}
			print " done\n";
			if(-e $cfile){
				`rm $cfile`;
			}

			# We need to find the layers
			#@lines = `$ogrinfo $tfile`;

			# Set which layers we want
			if($conf->{'osm'}{'extracts'}{$key}{'layers'}){
				@layers = @{$conf->{'osm'}{'extracts'}{$key}{'layers'}};
			}else{
				@layers = ("points","polygons","multipolygons");
			}
			@features = ();
			for($l = 0; $l < @layers; $l++){
				$layer = $layers[$l];
				$lfile = $basedir.$conf->{'areas'}{'dir'}.$files[$f]{'code'}.'/'.$files[$f]{'code'}.'-'.$key."-".$layer.".geojson";

				# Remove any existing layer file
				if(-e $lfile){
					`rm $lfile`;
				}

				# Extract the layer
				#print "\t\tExtracting $layer\n";
				`$ogr -f GeoJSON $lfile -lco "COORDINATE_PRECISION=5" -skipfailures $tfile $layer 2>&1`;

				# Read in the GeoJSON file and collect the features
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

			# Create the final GeoJSON file for this area/layer
			open(FILE,">",$gfile);
			print FILE "{\n";
			print FILE "\"type\": \"FeatureCollection\",\n";
			print FILE "\"features\": [\n";
			# Now we need to join the GeoJSON features
			print FILE join(",\n",@features)."\n";
			print FILE "]\n";
			print FILE "}\n";
			close(FILE);

			trimGeoJSONFile($gfile);
			
			if(-e $tfile){
				`rm $tfile`;
			}
			$nfeat = @features;
			print "\t\tSaved to $gfile ($nfeat features)\n";
		}
	}

}


