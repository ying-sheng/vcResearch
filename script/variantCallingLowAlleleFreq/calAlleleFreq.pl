#!/usr/bin/perl -w
use strict;

my ($file, $vcCaller) = @ARGV;

open IN, $file or die;
while(my $line = <IN>){
  
  if($line =~ /^#/){
    next;
  }
  
  chomp $line;
  
  my ($filter, $info, $sample) = (split /\t/, $line)[6,7,9];
  
  my ($altAF, @values);
  if($vcCaller eq 'samtools'){
    
    foreach my $eachInfo (split /;/, $info){
      
      if($eachInfo =~ /DP4/){
	
	@values = split /,/, (split /=/, $eachInfo)[1]; 
	$altAF = ($values[2]+$values[3])/($values[0]+$values[1]+$values[2]+$values[3]);
	print "$altAF\n";
	
	last;
      }
      
    }

  }elsif($vcCaller eq 'gatk'){
      
    if($filter !~ /PASS/){
      next;
    }
    
    @values = split /,/, (split /:/, $sample)[1]; 
    $altAF = $values[1]/($values[0] + $values[1]);
    print "$altAF\n";
      
  }
    
}

close IN;
