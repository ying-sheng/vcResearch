#!/usr/bin/perl -w
use strict;


my $file = shift;

open IN, $file or die;
while(my $line = <IN>){

  if($line =~ /^#/){

    print $line;

  }else{
    
    my ($chr, $pos, $ref, $alt, $qual, $filter, $info, $format, $sample) = (split /\t/, $line)[0,1,3,4,5,6,7,8,9];

    my @infos = split /;/, $info;

    foreach my $eachInfo (@infos){

      my ($tag, $value) = split /=/, $eachInfo;

      if($tag eq "DP4"){

	my ($refFor, $refRev, $altFor, $altRev) = split /,/, $value;

	if(($altFor > 0) and ($altRev > 0)){
	  print $line;
	  last;
	}

      }

    }

  }

}
close IN;
