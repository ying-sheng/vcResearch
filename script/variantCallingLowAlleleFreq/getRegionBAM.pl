#!/usr/bin/perl -w
use strict;

my ($bamFile, @regions) = @ARGV;

open IN, $bamFile or die;
while(my $line = <IN>){

  chomp $line;

  my ($eachBam, $sampleID) = (split / +/, $line)[0,1];

  print "$sampleID:\n\n";

  my $count = 1;
  my @outputs;
  foreach my $eachRegion(@regions){
    my $outFile = join '.', $sampleID, $count, "bam";
    push @outputs, $outFile;
    system "samtools view -b $eachBam $eachRegion > $outFile";
    print "$outFile\n";
    $count ++;
  }

  my $final = join '.', $sampleID, "region", "bam";

  if(scalar(@outputs) > 1){
    my $fileString = join ' ', @outputs;
    system "samtools merge -f $final $fileString";
  }elsif(scalar(@outputs) == 1){
    system "mv $outputs[0] $final";
  }
  print "\nFinal: $final\n\n";

}
close IN;
