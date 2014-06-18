#!/usr/bin/perl -w
use strict;

my $file = shift;

open IN, $file or die;
while(my $line = <IN>){
  
  chomp $line;
  my ($chr, $start, $relPos) = (split /\t/, $line)[0,1,6];

  print "$chr\t", $start+$relPos-1, "\t", $start+$relPos-1, "\n";


}
close IN;
