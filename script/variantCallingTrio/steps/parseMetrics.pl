#!/usr/bin/perl -w
use strict;

my ($file, $hideMessage) = @ARGV;

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}

my $count = 1;
my %row;
my $num;
open IN, $file or die;
while(my $line = <IN>){

  chomp $line;

  if($line !~ /^#/){

    if($line){

      my @items = split /\t/, $line;
      push @{$row{$count}}, @items;

      if(!$num or $num < scalar(@items)){
	$num = scalar(@items);
      }

      $count ++;

    }

  }

}
close IN;

for(my $x = 0; $x < $num; $x ++){

  foreach my $key(sort {$a<=>$b} keys %row){

    if($row{$key}[$x]){
      print "$row{$key}[$x]\t";
    }else{
  print "-\t";
    }

  }
  
  print "\n";


}
