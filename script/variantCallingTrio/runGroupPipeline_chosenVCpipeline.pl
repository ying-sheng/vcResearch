#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/lib/";
use Config::IniFiles;

print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";


my ($groupProfile, $script) = @ARGV;

my %samples;
open IN, $groupProfile or die;
while(my $line = <IN>){

  chomp $line;
  my ($sampleID, $profileFile) = split /\t/, $line;
  $samples{$sampleID} = $profileFile;

}
close IN;

foreach my $key(keys %samples){

  print "####################### Running on sample $key #########################\n\n";

  if(!(-d $key)){
    system "mkdir $key";
  }
  chdir("$key");
  system "perl $script $samples{$key}";
  chdir("..");

}
