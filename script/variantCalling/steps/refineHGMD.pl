#!/usr/bin/perl -w
use strict;

my ($annotationFile, $hgmdFile) = @ARGV;

# This script will do the following:
# - check the allele match for SNVs (not for multi-allelic sites), if not match, remove the HGMD annotations
# - if there are multiple HGMD record for one VCF entry, merge them together


## load HGMD information into %hgmdV

my %hgmdV;
open HGMD, $hgmdFile or die;
while(my $hgmd = <HGMD>){

  if($hgmd !~ /^#/){

    my ($chr, $pos, $id, $ref, $alt) = (split /\t/, $hgmd)[0,1,2,3,4];

    $hgmdV{$id}->{"chr"} = $chr;
    $hgmdV{$id}->{"ref"} = $ref;
    $hgmdV{$id}->{"alt"} = $alt;
    $hgmdV{$id}->{"all"} = $hgmd;

  }

}
close HGMD;

my $otherinfoIndex;

open ANNO, $annotationFile or die;
while(my $anno = <ANNO>){

  chomp $anno;

  my @items = split /\t/, $anno;

  ## Check if the VCF entry has HGMD annotation, 
  ## Check allele match (only for SNPs)
  ## remove it from info field, add in 6 additional column
  ## merge multiple HGMD records for one VCF entry

  if($anno =~ /HGMD/){

    my @info = split /;/, $items[-3];
    my $vChr = $items[-10];
    my $vRef = $items[-7];
    my $vAlt = $items[-6];

    my ($newInfo,%hgmdID,$hgmdInfo);
    foreach my $eachInfo(@info){

      if($eachInfo !~ /HGMD/){

	if(!$newInfo){
	  $newInfo = $eachInfo;
	}else{
	  $newInfo = join ';', $newInfo, $eachInfo;
	}

      }else{

	my ($tag, $value) = split /=/, $eachInfo;
	my ($type, $subType) = split /\./, $tag;

	$type =~ s/HGMD_(.*)/$1/;

	$hgmdID{$type}->{$subType} = $value;

      }

    }

    $items[-3] = $newInfo;

#    if(scalar(keys %hgmdID) > 1){

#      print "\n";

#    }

    my @subTypes = ("acc_num","disease","score","type","wildtype");

    my %final;
    my $v_tempRef = split //, $vRef;
    my $v_tempAlt = split //, $vAlt;

    foreach my $typeID(keys %hgmdID){

      my $hgmd_tempRef = split //, $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"};
      my $hgmd_tempAlt = split //, $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"};

      if(($v_tempRef > 1) or ($v_tempAlt > 1) or ($hgmd_tempRef > 1) or ($hgmd_tempAlt > 1)){
	
	if($final{"acc_num"}){
	  $final{"acc_num"} = join ';', $final{"acc_num"}, $hgmdID{$typeID}->{"acc_num"};
	}else{
	  $final{"acc_num"} = $hgmdID{$typeID}->{"acc_num"};
	}

	if($final{"change"}){
	  $final{"change"} = join ';', $final{"change"}, join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	}else{
	  $final{"change"} = join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	}


	if($final{"disease"}){
	  $final{"disease"} = join ';', $final{"disease"}, $hgmdID{$typeID}->{"disease"};
	}else{
	  $final{"disease"} = $hgmdID{$typeID}->{"disease"};
	}

	if(!($hgmdID{$typeID}->{"score"})){
	  $hgmdID{$typeID}->{"score"} = "NA";
	}

	if($final{"score"}){
	  $final{"score"} = join ';', $final{"score"}, $hgmdID{$typeID}->{"score"};
	}else{
	  $final{"score"} = $hgmdID{$typeID}->{"score"};
	}

	if(!($hgmdID{$typeID}->{"type"})){
	  $hgmdID{$typeID}->{"type"} = "NA";
	}

	if($final{"type"}){
	  $final{"type"} = join ';', $final{"type"}, $hgmdID{$typeID}->{"type"};
	}else{
	  $final{"type"} = $hgmdID{$typeID}->{"type"};
	}

	if(!($hgmdID{$typeID}->{"wildtype"})){
	  $hgmdID{$typeID}->{"wildtype"} = "NA";
	}

	if($final{"wildtype"}){
	  $final{"wildtype"} = join ';', $final{"wildtype"}, $hgmdID{$typeID}->{"wildtype"};
	}else{
	  $final{"wildtype"} = $hgmdID{$typeID}->{"wildtype"};
	}

      }elsif(($v_tempRef == 1) and ($v_tempAlt == 1) and ($hgmd_tempRef == 1) and ($hgmd_tempAlt == 1)){

	if($vAlt eq $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"}){

	  if($final{"acc_num"}){
	    $final{"acc_num"} = join ';', $final{"acc_num"}, $hgmdID{$typeID}->{"acc_num"};
	  }else{
	    $final{"acc_num"} = $hgmdID{$typeID}->{"acc_num"};
	  }
	  
	  if($final{"change"}){
	    $final{"change"} = join ';', $final{"change"}, join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	  }else{
	    $final{"change"} = join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	  }

	  if($final{"disease"}){
	    $final{"disease"} = join ';', $final{"disease"}, $hgmdID{$typeID}->{"disease"};
	  }else{
	    $final{"disease"} = $hgmdID{$typeID}->{"disease"};
	  }
	  
	  if(!($hgmdID{$typeID}->{"score"})){
	    $hgmdID{$typeID}->{"score"} = "NA";
	  }
	  
	  if($final{"score"}){
	    $final{"score"} = join ';', $final{"score"}, $hgmdID{$typeID}->{"score"};
	  }else{
	    $final{"score"} = $hgmdID{$typeID}->{"score"};
	  }
	  
	  if(!($hgmdID{$typeID}->{"type"})){
	    $hgmdID{$typeID}->{"type"} = "NA";
	  }
	  
	  if($final{"type"}){
	    $final{"type"} = join ';', $final{"type"}, $hgmdID{$typeID}->{"type"};
	  }else{
	    $final{"type"} = $hgmdID{$typeID}->{"type"};
	  }
	  
	  if(!($hgmdID{$typeID}->{"wildtype"})){
	    $hgmdID{$typeID}->{"wildtype"} = "NA";
	  }
	  
	  if($final{"wildtype"}){
	    $final{"wildtype"} = join ';', $final{"wildtype"}, $hgmdID{$typeID}->{"wildtype"};
	  }else{
	    $final{"wildtype"} = $hgmdID{$typeID}->{"wildtype"};
	  }	  

	}else{

	  if($final{"acc_num"}){
	    $final{"acc_num"} = join ';', $final{"acc_num"}, "NA";
	  }else{
	    $final{"acc_num"} = "NA";
	  }
	  
	  if($final{"change"}){
	    $final{"change"} = join ';', $final{"change"}, "NA";
	  }else{
	    $final{"change"} = "NA";
	  }
	  
	  if($final{"disease"}){
	    $final{"disease"} = join ';', $final{"disease"}, "NA";
	  }else{
	    $final{"disease"} = "NA";
	  }
	  
	  if(!($hgmdID{$typeID}->{"score"})){
	    $hgmdID{$typeID}->{"score"} = "NA";
	  }
	  
	  if($final{"score"}){
	    $final{"score"} = join ';', $final{"score"}, $hgmdID{$typeID}->{"score"};
	  }else{
	    $final{"score"} = $hgmdID{$typeID}->{"score"};
	  }
	  
	  if(!($hgmdID{$typeID}->{"type"})){
	    $hgmdID{$typeID}->{"type"} = "NA";
	  }
	  
	  if($final{"type"}){
	    $final{"type"} = join ';', $final{"type"}, $hgmdID{$typeID}->{"type"};
	  }else{
	    $final{"type"} = $hgmdID{$typeID}->{"type"};
	  }
	  
	  if(!($hgmdID{$typeID}->{"wildtype"})){
	    $hgmdID{$typeID}->{"wildtype"} = "NA";
	  }
	  
	  if($final{"wildtype"}){
	    $final{"wildtype"} = join ';', $final{"wildtype"}, $hgmdID{$typeID}->{"wildtype"};
	  }else{
	    $final{"wildtype"} = $hgmdID{$typeID}->{"wildtype"};
	  }	
	  
#	  print "\n";

	}

      }

    }

    splice @items,$otherinfoIndex,0,$final{"acc_num"},$final{"disease"},$final{"change"},$final{"score"},$final{"type"},$final{"wildtype"};
    print join("\t", @items), "\n";
#    print "\n";

  }elsif($anno =~ /^Chr/){

    for(my $x=0; $x < scalar(@items); $x ++){

      if($items[$x] eq 'Otherinfo'){
	$otherinfoIndex = $x;
	last;
      }

    }

    splice @items,$otherinfoIndex,0,"HGMD.acc_num", "HGMD.disease", "HGMD.alleleChange", "HGMD.score", "HGMD.type", "HGMD.wildtype";
    print join("\t", @items), "\n";

  }else{
    splice @items,$otherinfoIndex,0,"NA", "NA", "NA", "NA", "NA", "NA";
    print join("\t", @items), "\n";
  }

}
close ANNO;
