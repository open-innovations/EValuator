#!/usr/bin/perl
use Data::Dumper;

#https://www.arcgis.com/sharing/rest/content/items/7db6988a695f4c75989f0dc6701d4167/data <- zip file

$lookupfile = "raw/PCD_OA_LSOA_MSOA_LAD_NOV21_UK_LU.csv";
$lookupdir = "www/data/";

if(!-e $lookupfile){
	print "WARNING: No lookup file exists at $lookupfile\n";
	print "You could download it from https://www.arcgis.com/sharing/rest/content/items/7db6988a695f4c75989f0dc6701d4167/data\n";
	exit;
}

%msoa;
%oa;
%lad;
open(FILE,$lookupfile);
while(<FILE>){
	#pcd7,pcd8,pcds,dointr,doterm,usertype,oa11cd,lsoa11cd,msoa11cd,ladcd,lsoa11nm,msoa11nm,ladnm,ladnmw
	#"AB1 0AA","AB1  0AA","AB1 0AA","198001","199606","0","S00090303","S01006514","S02001237","S12000033","Cults, Bieldside and Milltimber West - 02","Cults, Bieldside and Milltimber Wes","Aberdeen City",""
	$line = $_;
	if($line){
		($pcd7,$pcd8,$pcds,$dointr,$doterm,$usertype,$oa11cd,$lsoa11cd,$msoa11cd,$ladcd,$lsoa11nm,$msoa11nm,$ladnm,$ladnmw) = split(/,/,$line);
		# Remove quotation marks
		$ladcd =~ s/(^\"|\"$)//g;
		$msoa11cd =~ s/(^\"|\"$)//g;
		$lsoa11cd =~ s/(^\"|\"$)//g;
		$oa11cd =~ s/(^\"|\"$)//g;
		# If it isn't the header we use it
		if($pcd7 ne "pcd7"){
			if($msoa11cd ne "" && !$msoa{$msoa11cd}){
				$msoa{$msoa11cd} = $ladcd;
			}
			if($oa11cd ne "" && !$oa{$oa11cd}){
				$oa{$oa11cd} = {'lad'=>$ladcd,'lsoa'=>$lsoa11cd,'msoa'=>$msoa11cd};
			}
			if($ladcd ne ""){
				if(!$lad{$ladcd}){
					$lad{$ladcd} = {};
				}
				if(!$lad{$ladcd}{$msoa11cd}){ $lad{$ladcd}{$msoa11cd} = 0; }
				$lad{$ladcd}{$msoa11cd}++;
			}
		}
	}
}
close(FILE);

open(LOOKUP,">",$lookupdir."lookupMSOA.tsv");
print LOOKUP "MSOA\tLAD\n";
foreach $m (sort(keys(%msoa))){
	print LOOKUP "$m\t$msoa{$m}\n"
}
close(LOOKUP);

open(LOOKUP,">",$lookupdir."lookupOA.tsv");
print LOOKUP "OA\tLSOA\tMSOA\tLAD\n";
foreach $o (sort(keys(%oa))){
	print LOOKUP "$o\t$oa{$o}{'lsoa'}\t$oa{$o}{'msoa'}\t$oa{$o}{'lad'}\n"
}
close(LOOKUP);


open(LOOKUP,">",$lookupdir."lookupLAD.tsv");
print LOOKUP "LAD\tMSOAs\n";
foreach $l (sort(keys(%lad))){
	print LOOKUP "$l\t";
	print LOOKUP join(";",sort(keys(%{$lad{$l}})));
	print LOOKUP "\n";
}
close(LOOKUP);

