#!/usr/bin/perl -w
use strict;

my $file = shift;

open IN, $file or die;
while(my $line = <IN>){

  if($line =~ /^#/){
    print $line;
  }else{
    $line =~ s/^chr(.*)/$1/;
    print $line;

  }


}
close IN;
