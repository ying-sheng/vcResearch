#!/usr/bin/perl -w
use strict;

my @adds = @ARGV;

my $file = shift @adds;

my $add = join "\t", @adds;

my $otherInfoIndex;
open IN, $file or die;
while(my $line = <IN>){
  
  chomp $line;
  
  my @items = split /\t/, $line;
  
  my $newline;
  
  if($line =~ /Func/){
    
    for(my $x = 0; $x < scalar(@items); $x ++){
      
      if($items[$x] eq 'gff3'){
	
	$items[$x] = "RepeatMasker";
	
      }
      
      if($items[$x] eq "Otherinfo"){
	
	$otherInfoIndex = $x;
	
      }

    }
    
    pop @items;
    $newline = join "\t", @items, "vcf_chrom", "vcf_pos", "vcf_id", "vcf_ref", "vcf_alt", "vcf_qual", "vcf_filter", "vcf_info", "vcf_format", $add;
    
  }else{
    
    splice @items, $otherInfoIndex,1;
    $newline = join "\t", @items;
    
  }
  
  print "$newline\n";
  
}
close IN;
