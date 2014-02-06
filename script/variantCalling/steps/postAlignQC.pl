#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;


# The script need to be performed under 030_postAlignQC
# The script will output the following QC parameters:
# - capture efficiency : 1 - OFF_BAIT_BASES/PF_UQ_BASES_ALIGNED
# - MEAN_TARGET_COVERAGE
# - MEAN_INSERT_SIZE, STANDARD_DEVIATION
# - PCT_READS_ALIGNED_IN_PAIRS
# will save all these qc values under sample folder root: qcReport.txt


###################### INTRODUCTION ###############################################

# blank currently

###################### KEY INPUTS #################################################

my ($bamFile, $intervalTarget, $intervalBait, $code, $configFile, $hideMessage) = @ARGV;

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}

my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";

my ($bAlignSum, $bInsertSum, $bHsMetrics, $bInHouse);  

($bAlignSum, $bInsertSum, $bHsMetrics, $bInHouse) = split //, $code;

# sample
my $sampleID = $configuration->val("Sample","sampleID");
my $genePanel = $configuration->val("Sample","genePanel");

# reference file
my $refFile = $configuration->val("Data","genomeB37DecoyFasta");

# tools
my $picardDir = $configuration->val("Tool","picard");
my $coveragePath = $configuration->val("Script","coveragePath");

my $max_insert_size = 600;

system "date >> start.out";

open REPORT, ">> reportPostAlignQC.txt";
system "head start.out >> reportPostAlignQC.txt";
system "rm start.out";

print REPORT "The original input BAM file is:\n$bamFile\n\n";
print REPORT "The target interval file is:\n$intervalTarget\n\n";
print REPORT "The bait interval file is:\n$intervalBait\n\n";

####################### ANALYSIS ###################################################

print REPORT "The commands used in this step:\n\n";

###################### ANALYSIS ##########################################

#### CollectAlignmentSummaryMetrics ####

if($bAlignSum == 1){

  print REPORT "Doing collectAlignmentSummaryMetrics\n";
  print "Doing collectAlignmentSummaryMetrics ... start at -----";
  system "date";

  print REPORT "java -Xmx2g -jar $picardDir/CollectAlignmentSummaryMetrics.jar MAX_INSERT_SIZE=$max_insert_size INPUT=$bamFile OUTPUT=010_collectAlignmentSummaryMetrics/collectAlignmentSummaryMetrics.txt REFERENCE_SEQUENCE=$refFile VALIDATION_STRINGENCY=STRICT 2>010_collectAlignmentSummaryMetrics/errCollectAlignmentSummaryMetrics\n\n";
  system "java -Xmx2g -jar $picardDir/CollectAlignmentSummaryMetrics.jar MAX_INSERT_SIZE=$max_insert_size INPUT=$bamFile OUTPUT=010_collectAlignmentSummaryMetrics/collectAlignmentSummaryMetrics.txt REFERENCE_SEQUENCE=$refFile VALIDATION_STRINGENCY=STRICT 2>010_collectAlignmentSummaryMetrics/errCollectAlignmentSummaryMetrics";

  print REPORT "perl $FindBin::Bin/parseMetrics.pl 010_collectAlignmentSummaryMetrics/collectAlignmentSummaryMetrics.txt 1 > 010_collectAlignmentSummaryMetrics/collectAlignmentSummaryMetrics.easy.txt\n\n";
  system "perl $FindBin::Bin/parseMetrics.pl 010_collectAlignmentSummaryMetrics/collectAlignmentSummaryMetrics.txt 1 > 010_collectAlignmentSummaryMetrics/collectAlignmentSummaryMetrics.easy.txt";

  print "Finish collectAlignmentSummaryMetrics -----";
  system "date";
  print "\n";
}

#### CollectInsertSizeMetrics ####

if($bInsertSum == 1){

  print REPORT "Doing collectInsertSizeMetrics\n";
  print "Doing collectInsertSizeMetrics ... start at -----";
  system "date";

  print REPORT "java -Xmx2g -jar $picardDir/CollectInsertSizeMetrics.jar HISTOGRAM_FILE=020_collectInsertSizeMetrics/insertSizeHistogram INPUT=$bamFile OUTPUT=020_collectInsertSizeMetrics/collectInsertSizeMetrics.txt REFERENCE_SEQUENCE=$refFile VALIDATION_STRINGENCY=STRICT 2>020_collectInsertSizeMetrics/errCollectInsertSizeMetrics\n\n";
  system "java -Xmx2g -jar $picardDir/CollectInsertSizeMetrics.jar HISTOGRAM_FILE=020_collectInsertSizeMetrics/insertSizeHistogram INPUT=$bamFile OUTPUT=020_collectInsertSizeMetrics/collectInsertSizeMetrics.txt REFERENCE_SEQUENCE=$refFile VALIDATION_STRINGENCY=STRICT 2>020_collectInsertSizeMetrics/errCollectInsertSizeMetrics";

  print REPORT "perl $FindBin::Bin/parseMetrics.pl 020_collectInsertSizeMetrics/collectInsertSizeMetrics.txt 1 > 020_collectInsertSizeMetrics/collectInsertSizeMetrics.easy.txt\n\n";
  system "perl $FindBin::Bin/parseMetrics.pl 020_collectInsertSizeMetrics/collectInsertSizeMetrics.txt 1 > 020_collectInsertSizeMetrics/collectInsertSizeMetrics.easy.txt";

  print "Finish collectInsertSizeMetrics -----";
  system "date";
  print "\n";

}

#### CalculateHsMetrics ####

if($bHsMetrics == 1){

  print REPORT "Doing calculateHsMetrics\n";
  print "Doing calculateHsMetrics ... start at -----";
  system "date";

  print REPORT "java -Xmx2g -jar $picardDir/CalculateHsMetrics.jar BAIT_INTERVALS=$intervalBait TARGET_INTERVALS=$intervalTarget INPUT=$bamFile OUTPUT=030_calculateHsMetrics/calculateHsMetrics.txt REFERENCE_SEQUENCE=$refFile PER_TARGET_COVERAGE=030_calculateHsMetrics/perTargetCoverage.txt VALIDATION_STRINGENCY=STRICT 2>030_calculateHsMetrics/errCalculateHsMetrics\n\n";
  system "java -Xmx2g -jar $picardDir/CalculateHsMetrics.jar BAIT_INTERVALS=$intervalBait TARGET_INTERVALS=$intervalTarget INPUT=$bamFile OUTPUT=030_calculateHsMetrics/calculateHsMetrics.txt REFERENCE_SEQUENCE=$refFile PER_TARGET_COVERAGE=030_calculateHsMetrics/perTargetCoverage.txt VALIDATION_STRINGENCY=STRICT 2>030_calculateHsMetrics/errCalculateHsMetrics";

  print REPORT "perl $FindBin::Bin/parseMetrics.pl 030_calculateHsMetrics/calculateHsMetrics.txt 1 > 030_calculateHsMetrics/calculateHsMetrics.easy.txt\n\n";
  system "perl $FindBin::Bin/parseMetrics.pl 030_calculateHsMetrics/calculateHsMetrics.txt 1 > 030_calculateHsMetrics/calculateHsMetrics.easy.txt";

  print "Finish calculateHsMetrics -----";
  system "date";
  print "\n";

}

#### In house coverage calculation ####

if($bInHouse == 1){

  print REPORT "Doing in-house coverage calculation\n\n";
  print "Doing in-house coverage calculation ... start at -----";
  system "date";

  chdir("040_coverageIn-house");

  print REPORT "python $coveragePath/coverage_qc.py --bampath $bamFile --genepanelpath $genePanel --outputdir ./ --samplename $sampleID --aggregation transcript --runinitial True --mainoutput \"coverage_per_transcript.csv\"\n";
  print REPORT "python $coveragePath/coverage_qc.py --bampath $bamFile --genepanelpath $genePanel --outputdir ./ --samplename $sampleID --aggregation exon --runinitial False --mainoutput \"coverage_per_exon.csv\"\n\n";

  system "python $coveragePath/coverage_qc.py --bampath $bamFile --genepanelpath $genePanel --outputdir ./ --samplename $sampleID --aggregation transcript --runinitial True --mainoutput \"coverage_per_transcript.csv\"";
  system "python $coveragePath/coverage_qc.py --bampath $bamFile --genepanelpath $genePanel --outputdir ./ --samplename $sampleID --aggregation exon --runinitial False --mainoutput \"coverage_per_exon.csv\"";

  system "cp coverage_per_transcript.csv ../../060_delivery/";
  system "cp coverage_per_exon.csv ../../060_delivery/";
  system "cp lowCoverage.bed ../../060_delivery";

  chdir("..");

}

open QC, ">> ../qcReport.txt" or die;
print QC "\n##########\n\nQuality of Alignment\n\n##########\n\n";
my $offBait = `grep OFF_BAIT_BASES 030_calculateHsMetrics/calculateHsMetrics.easy.txt`;
chomp $offBait;
$offBait = (split /\t+/, $offBait)[1];

if($offBait !~ /\d+/){
  $offBait = 0;
}

my $pfuqReadsAligned = `grep "^PF_UQ_READS_ALIGNED" 030_calculateHsMetrics/calculateHsMetrics.easy.txt`;
chomp $pfuqReadsAligned;
$pfuqReadsAligned = (split /\t+/, $pfuqReadsAligned)[1];

my $efficiency = int((1-($offBait/$pfuqReadsAligned))*100)/100;
print QC "CAPTURE_EFFICIENCY (OFF_BAIT_BASES/PF_UQ_READS_ALIGNED)\t$efficiency\n";

close QC;

system "grep PCT_READS_ALIGNED_IN_PAIRS 010_collectAlignmentSummaryMetrics/collectAlignmentSummaryMetrics.easy.txt >> ../qcReport.txt";
system "grep MEAN_INSERT_SIZE 020_collectInsertSizeMetrics/collectInsertSizeMetrics.easy.txt|cut -f1,2 >> ../qcReport.txt";
system "grep STANDARD_DEVIATION 020_collectInsertSizeMetrics/collectInsertSizeMetrics.easy.txt|cut -f1,2 >> ../qcReport.txt";
system "grep MEAN_TARGET_COVERAGE 030_calculateHsMetrics/calculateHsMetrics.easy.txt >> ../qcReport.txt";
system "grep PCT_TARGET_BASES_ 030_calculateHsMetrics/calculateHsMetrics.easy.txt >> ../qcReport.txt";

print REPORT "The script is finished\n";
close REPORT;

sub getBamFile{

  my ($fileName, $bamFileLoc, $outFile) = @_;

  open IN, $fileName or die;
  open OUT, ">$outFile" or die;
  while(my $line = <IN>){

    if($line =~ /BAMPath = <BAMFILE>/){
      $line = "BAMPath = $bamFileLoc";
      print OUT "$line\n";
    }else{
      print OUT $line;
    }

  }
  close IN;
  close OUT;

  system "rm $fileName";

}
