#!/usr/bin/perl
# Code to create lookup files

print "Deprecated.\n";
exit;




use Data::Dumper;

#https://www.arcgis.com/sharing/rest/content/items/7db6988a695f4c75989f0dc6701d4167/data <- zip file

$rootdir = "../";
$namefile = $rootdir."raw/MSOA-Names-Latest.csv";
$lookupfile = $rootdir."raw/PCD_OA_LSOA_MSOA_LAD_NOV21_UK_LU.csv";
$lookupdir = $rootdir."www/data/";
$boundarydir = $rootdir."../geography-bits/data/MSOA11CD/";

if(!-e $lookupfile){
	print "WARNING: No lookup file exists at $lookupfile\n";
	print "You could download it from https://www.arcgis.com/sharing/rest/content/items/7db6988a695f4c75989f0dc6701d4167/data\n";
	exit;
}

if(!-e $namefile){
	print "WARNING: No MSOA names file exists at $namefile\n";
	print "You could download it from https://houseofcommonslibrary.github.io/msoanames/MSOA-Names-Latest.csv\n";
	exit;
}

%msoa;
%oa;
%lad;

open(FILE,$namefile);
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

open(FILE,$lookupfile);
while(<FILE>){
	#pcd7,pcd8,pcds,dointr,doterm,usertype,oa11cd,lsoa11cd,msoa11cd,ladcd,lsoa11nm,msoa11nm,ladnm,ladnmw
	#"AB1 0AA","AB1  0AA","AB1 0AA","198001","199606","0","S00090303","S01006514","S02001237","S12000033","Cults, Bieldside and Milltimber West - 02","Cults, Bieldside and Milltimber Wes","Aberdeen City",""
	$line = $_;
	if($line){
		($pcd7,$pcd8,$pcds,$dointr,$doterm,$usertype,$oa11cd,$lsoa11cd,$msoa11cd,$ladcd,$lsoa11nm,$msoa11nm,$ladnm,$ladnmw) = split(/,/,$line);
		# Remove quotation marks
		$ladcd =~ s/(^\"|\"$)//g;
		$ladnm =~ s/(^\"|\"$)//g;
		$msoa11cd =~ s/(^\"|\"$)//g;
		$lsoa11cd =~ s/(^\"|\"$)//g;
		$oa11cd =~ s/(^\"|\"$)//g;
		# If it isn't the header we use it
		if($pcd7 ne "pcd7"){
			if($msoa11cd ne "" && $msoa11cd ne "msoa11cd"){
				if(!$msoa{$msoa11cd}){
					$msoa{$msoa11cd} = {'name'=>'?'};
				}
				$msoa{$msoa11cd}{'LAD'} = $ladcd;
			}
			if($oa11cd ne "" && !$oa{$oa11cd}){
				$oa{$oa11cd} = {'lad'=>$ladcd,'lsoa'=>$lsoa11cd,'msoa'=>$msoa11cd};
			}
			if($ladcd ne ""){
				if(!$lad{$ladcd}){
					$lad{$ladcd} = {'msoas'=>{},'name'=>$ladnm};
				}
				if(!$lad{$ladcd}{'msoas'}{$msoa11cd}){ $lad{$ladcd}{'msoas'}{$msoa11cd} = 0; }
				$lad{$ladcd}{'msoas'}{$msoa11cd}++;
			}
		}
	}
}
close(FILE);


open(LOOKUP,">",$lookupdir."lookupMSOA.tsv");
print LOOKUP "MSOA\tLAD\n";
foreach $m (sort(keys(%msoa))){
	print LOOKUP "$m\t$msoa{$m}{'LAD'}\n"
}
close(LOOKUP);

open(LOOKUP,">",$lookupdir."lookupOA.tsv");
print LOOKUP "OA\tLSOA\tMSOA\tLAD\n";
foreach $o (sort(keys(%oa))){
	print LOOKUP "$o\t$oa{$o}{'lsoa'}\t$oa{$o}{'msoa'}\t$oa{$o}{'lad'}\n"
}
close(LOOKUP);


open(LOOKUP,">",$lookupdir."lookupArea.tsv");
print LOOKUP "Area\tArea name\tMSOAs\n";
foreach $l (sort(keys(%lad))){
	print LOOKUP "$l\t$lad{$l}{'name'}\t";
	print LOOKUP join(";",sort(keys(%{$lad{$l}{'msoas'}})));
	print LOOKUP "\n";
}
close(LOOKUP);


open(LOOKUP,">",$lookupdir."Area.tsv");
print LOOKUP "Area\tArea name\n";
foreach $l (sort(keys(%lad))){
	print LOOKUP "$l\t$lad{$l}{'name'}\n";
}
close(LOOKUP);

foreach $l (sort(keys(%lad))){
	$geojson = "";
	open(LOOKUP,">",$lookupdir."areas/$l/$l-msoas.tsv");
	@msoas = sort(keys(%{$lad{$l}{'msoas'}}));
	for($m = 0; $m < @msoas; $m++){
		print LOOKUP "$msoas[$m]\t$msoa{$msoas[$m]}{'name'}\n";
		$mfile = $boundarydir.$msoas[$m].".geojsonl";
		if(-e $mfile){
			open(MSOA,$mfile);
			@lines = <MSOA>;
			close(MSOA);
			$lines[0] =~ s/[\n\r]//g;
			$lines[0] =~ s/(,"msoa11nm":"[^\"]*")/$1,"msoa11hclnm":"$msoa{$msoas[$m]}{'name'}"/g;
			$geojson .= ($geojson ? ",\n":"").$lines[0];
		}
	}
	close(LOOKUP);
	$gfile = $lookupdir."areas/$l/$l.geojson";
	if($geojson){
		open(GEO,">",$gfile);
		print GEO "{\n";
		print GEO "\"type\": \"FeatureCollection\",\n";
		print GEO "\"features\":[\n";
		print GEO $geojson."\n";
		print GEO "]\n";
		print GEO "}\n";
		close(GEO);
	}else{
		print "WARNING: No GeoJSON for $l ($gfile)\n";
	}
}
