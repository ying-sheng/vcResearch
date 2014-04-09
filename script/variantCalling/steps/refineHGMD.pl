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

    my ($chr, $pos, $id, $ref, $alt, $gt) = (split /\t/, $hgmd)[0,1,2,3,4,9];

    $hgmdV{$id}->{"chr"} = $chr;
    $hgmdV{$id}->{"ref"} = $ref;
    $hgmdV{$id}->{"alt"} = $alt;
    $hgmdV{$id}->{"all"} = $hgmd;
    $hgmdV{$id}->{"gt"} = $gt;

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

    my @subTypes = ("amino", "acc_num","disease", "omimid", "tag", "comments", "pmid", "location", "locref", "deletion", "insertion", "score","type","wildtype");

    my %final;
    my $v_tempRef = split //, $vRef;
    my $v_tempAlt = split //, $vAlt;

    foreach my $typeID(keys %hgmdID){

      my $hgmd_tempRef = split //, $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"};
      my $hgmd_tempAlt = split //, $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"};

      if(($v_tempRef > 1) or ($v_tempAlt > 1) or ($hgmd_tempRef > 1) or ($hgmd_tempAlt > 1)){ # if the variation is indels or HGMD is indels, without checking of allele match
	
	foreach my $eachSubTypes (@subTypes){

	  if(!($hgmdID{$typeID}->{$eachSubTypes})){
	    $hgmdID{$typeID}->{$eachSubTypes} = "NA";
	  }

	  if($final{$eachSubTypes}){
	    $final{$eachSubTypes} = join ';', $final{$eachSubTypes}, $hgmdID{$typeID}->{$eachSubTypes};
	  }else{
	    $final{$eachSubTypes} = $hgmdID{$typeID}->{$eachSubTypes};
	  }

	}

	if($final{"change"}){
	  $final{"change"} = join ';', $final{"change"}, join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	}else{
	  $final{"change"} = join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	}

	if($final{"gt"}){
	  $final{"gt"} = join ';', $final{"gt"}, $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"gt"};
	}else{
	  $final{"gt"} = $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"gt"};
	}

      }elsif(($v_tempRef == 1) and ($v_tempAlt == 1) and ($hgmd_tempRef == 1) and ($hgmd_tempAlt == 1)){

	if($vAlt eq $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"}){

	  foreach my $eachSubTypes (@subTypes){

	    if(!($hgmdID{$typeID}->{$eachSubTypes})){
	      $hgmdID{$typeID}->{$eachSubTypes} = "NA";
	    }

	    if($final{$eachSubTypes}){
	      $final{$eachSubTypes} = join ';', $final{$eachSubTypes}, $hgmdID{$typeID}->{$eachSubTypes};
	    }else{
	      $final{$eachSubTypes} = $hgmdID{$typeID}->{$eachSubTypes};
	    }

	  }

	  if($final{"change"}){
	    $final{"change"} = join ';', $final{"change"}, join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	  }else{
	    $final{"change"} = join ('', $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"ref"}, "->", $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"alt"});
	  }

	  if($final{"gt"}){
	    $final{"gt"} = join ';', $final{"gt"}, $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"gt"};
	  }else{
	    $final{"gt"} = $hgmdV{$hgmdID{$typeID}->{"acc_num"}}->{"gt"};
	  }

	}else{

	  foreach my $eachSubTypes (@subTypes){

	    $final{$eachSubTypes} = "NA";
	    
	  }

	  $final{"change"} = "NA";

	  $final{"gt"} = "NA";


#	  print "\n";

	} # ending for allele not match of SNPs

      } # ending for SNPs

    } # ending for each hgmd files

    # if there has HGMD annotations
# ("amino", "acc_num","disease", "omimid", "tag", "comments", "pmid", "location", "locref", "deletion", "insertion", "score","type","wildtype");

    splice @items,$otherinfoIndex,0,$final{"amino"}, $final{"gt"}, $final{"acc_num"},$final{"disease"},$final{"omimid"}, $final{"tag"}, $final{"comments"}, $final{"pmid"}, $final{"location"}, $final{"locref"}, $final{"deletion"}, $final{"insertion"}, $final{"change"},$final{"score"},$final{"type"},$final{"wildtype"};
    print join("\t", @items), "\n";
#    print "\n";

  }elsif($anno =~ /^Chr/){ # if header line

    for(my $x=0; $x < scalar(@items); $x ++){

      if($items[$x] eq 'Otherinfo'){
	$otherinfoIndex = $x;
	last;
      }

    }

    splice @items,$otherinfoIndex,0,"HGMD.amino", "HGMD.GT", "HGMD.acc_num", "HGMD.disease", "HGMD.omimid", "HGMD.tag", "HGMD.comments", "HGMD.pmid", "HGMD.location", "HGMD.locref", "HGMD.deletion", "HGMD.insertion", "HGMD.alleleChange", "HGMD.score", "HGMD.type", "HGMD.wildtype";
    print join("\t", @items), "\n";

  }else{ # if no HGMD annotation
    splice @items,$otherinfoIndex,0,"NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA", "NA";
    print join("\t", @items), "\n";
  }

}
close ANNO;
