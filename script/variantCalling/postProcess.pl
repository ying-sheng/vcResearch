#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;

# my $runID = $ARGV[0];

print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";


my @folder = glob "Sample*";

my $response;
foreach my $eachFolder (@folder){
  
  print "Process $eachFolder\n\n";
  my $configuration = Config::IniFiles->new(-file => "$eachFolder/sample.conf") or die "Could not open $eachFolder/sample.conf!";
  
  my $runID = $configuration->val("Sample","runID");
  my $sampleID = $configuration->val("Sample","sampleID");
  my $genePanel = $configuration->val("Sample","genePanel");
  my $genePanelTranscript = glob "$genePanel/*.transcripts.csv";
  $genePanelTranscript =~ s/.*\/(.*)$/$1/;
  my $pipelineVersion = $configuration->val("Version", "variantCallingPipelineVersion");

  print "The result folder (060_delivery) should contain the following files:\n\nBAM file:\nall.realigned.markDup.baseQreCali.bam\nall.realigned.markDup.baseQreCali.bai\n\nAnnotation variant file:\nallAnnotationInCand.hg19_multianno.freq.tsv\n\nCoverage results:\ncoverage_qc_exon.tsv\ncoverage_qc_transcript.tsv\nlow_coverage.tsv\n\nSNP fingerprinting test results from HTS:\nsnp.raw.snpFingerPrintingTest.vcf\nsnp.raw.snpFingerPrintingTest.vcf.idx\n\n";

  print "ls $eachFolder/060_delivery\n";
  system "ls $eachFolder/060_delivery";

  print "\ndu -h $eachFolder/060_delivery/*.ba*\n";
  system "du -h $eachFolder/060_delivery/*.ba*";
  
  print "\nDo you want to clean the intermediate bam files (bam files under realignment and mard duplicate steps) (y for clean, n for stop)?\n\n";
  $response = <STDIN>;
  chomp $response;
  
  my $bamFile;

  if($response eq 'y'){
    
    $bamFile = glob "$eachFolder/020_refineAlignment/010_realignGATK/*.bam";

    if($bamFile){

      print "rm $eachFolder/020_refineAlignment/010_realignGATK/*.bam\nrm $eachFolder/020_refineAlignment/010_realignGATK/*.bai\n";
      system "rm $eachFolder/020_refineAlignment/010_realignGATK/*.bam";
      system "rm $eachFolder/020_refineAlignment/010_realignGATK/*.bai";

    }
    
    $bamFile = glob "$eachFolder/020_refineAlignment/020_markDupPicard/*.bam";

    if($bamFile){

      print "rm $eachFolder/020_refineAlignment/020_markDupPicard/*.bam\nrm $eachFolder/020_refineAlignment/020_markDupPicard/*.bai\n";
      system "rm $eachFolder/020_refineAlignment/020_markDupPicard/*.bam";
      system "rm $eachFolder/020_refineAlignment/020_markDupPicard/*.bai";

    }
    
  }else{
    
    print "\nWill leave the intermediate files in the folders\n\n";
    
  }
  
  print "\nDo you want to get the right file name (y for proceed, n for not proceed)\n";
  
  ########## It is better to also print out the final file name to let decide whether want to proceed or not
  $response = <STDIN>;
  chomp $response;
  
  if($response eq 'y'){
    
    my $tag = join '.', $eachFolder, $runID;
    
    chdir("$eachFolder/060_delivery");

    open OUT, "tempHeader.txt" or die;
    print OUT "# $sampleID\n";
    print OUT "# $gp\n";
    print OUT "# Variant Calling Pipeline is $pipelineVersion\n\n\n";
    close OUT;

    my @files = glob "*";
    
    my ($finalBam, $finalBai);
    
    foreach my $eachFile(@files){

      if($eachFile =~ /$tag/){
	next;
      }

      my $newName = join ".", $tag, $eachFile;

      if(-T $eachFile){ # check if a file is a text file

	system "cat tempHeader.txt $eachFile > $newName";
	system "rm $eachFile";

      }else{

	system "mv $eachFile $newName";

      }
      
#      if($newName =~ /\.bam/){
#	$finalBam = $newName;
#      }
      
#      if($newName =~ /\.bai/){
#	$finalBai = $newName;
#      }
      
    }
    
    system "rm tempHeader.txt";
#    system "ln -s $finalBam ../020_refineAlignment/030_BQRecalGATK/all.realigned.markDup.baseQreCali.bam";
#    system "ln -s $finalBai ../020_refineAlignment/030_BQRecalGATK/all.realigned.markDup.baseQreCali.bai";
    
    chdir("../../");
    
  }else{
    
    next;
    
  }
  
}
