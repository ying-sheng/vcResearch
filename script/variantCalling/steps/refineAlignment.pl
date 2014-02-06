#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;

# bam file and code
my ($bamFile, $code, $configFile, $hideMessage) = @ARGV;
# The code is composed by three digital, the first one is for realignment, the second one is for mark duplicate, the third one is for BQSR, 1 means need to do, 2 means finished

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}



my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";

##### Main inputs and options

if(!$bamFile or !$code){
  
  die("One/Both of the inputs are MISSING (the input bam file or the code for which step need to be performed), please check and rerun the script\n\n");
  
}

# reference file
my $refFile = $configuration->val("Data","genomeB37DecoyFasta");

# interval file
my $interval = $configuration->val("Sample","captureKit");
my $intervalFile = `ls $interval/*.slop50.merged.list`;
chomp $intervalFile;

# dbsnp rod file
my $dbsnpFile = $configuration->val("Data","dbSNP137");

# number of thread used
my $nt = 3; # seems doesn't work now
my $millIndel = $configuration->val("Data","millsIndels");
my $kgIndel = $configuration->val("Data","kgIndels");

system "date >> start.out";

open REPORT, ">> reportPostAlignProcess.txt";
system "head start.out >> reportPostAlignProcess.txt";
system "rm start.out";

print REPORT "The original input BAM file is:\n$bamFile\n\n";

###################### PROGRAM VERSIONS USED ###################################

my $gatkDir = $configuration->val("Tool","gatk");
my $gatk = "$gatkDir/GenomeAnalysisTK.jar";
my $picardDir = $configuration->val("Tool","picard");

###################### ANALYSIS ################################################

my ($bRealign, $bMark, $bBqsr) = split //, $code;

#### Local realignment around indels ####

my $realignBam = "010_realignGATK/all.realigned.bam";

if($bRealign eq "1"){

  print REPORT "Doing realignment around indels ...\n\nCommand used\n";

  print "Doing local realignment around indels ... start at\n";
  system "date";
    
  my $intervalFile="010_realignGATK/all.posiSrt.intervals";

  # Creating intervals (whole genome)

  print REPORT "Step 1: creating intervals ...\n";
  print "Step 1: creating intervals ... start at\n";
  system "date";

  print REPORT "java -Xmx2g -jar $gatk -T RealignerTargetCreator -R $refFile -o $intervalFile -I $bamFile --known $millIndel --known $kgIndel -nt 3 2>010_realignGATK/errRealignerTargetCreator > 010_realignGATK/realignerTargetCreatorInfo.txt\n\n";
  system "java -Xmx2g -jar $gatk -T RealignerTargetCreator -R $refFile -o $intervalFile -I $bamFile --known $millIndel --known $kgIndel -nt 3 2>010_realignGATK/errRealignerTargetCreator > 010_realignGATK/realignerTargetCreatorInfo.txt";

    print "Step 1 finish\n";
    system "date";

    # Realigning
    
    print REPORT "Step 2: realigning ...\n";
    print "Step 2: realigning ... start at\n";
    system "date";

# From GATK get satisfaction page: I've been told that the underlying BAM writing code that we use (from Picard) now supports writing uncompressed bams; you can trigger this with the toolkit-wide argument '-compress 0' (the default is a compression level of 5, with max being 9). When writing temporary bams (for example in the Indel Realigner step, which writes a temporary bam that is passed to FixMateInformation which will produce the final bam), we HIGHLY recommend turning off bam compression if you have the disk space. Preliminary results show that moving from compression level 5 to 0 can shave off 50% of the run time in some cases!

    print REPORT "java -Xmx4g -jar $gatk -T IndelRealigner -I $bamFile -R $refFile -targetIntervals $intervalFile -o $realignBam -known $millIndel -known $kgIndel -compress 0 2>010_realignGATK/errIndelRealigner > 010_realignGATK/indelRealignerInfo.txt\n\n";
    system "java -Xmx4g -jar $gatk -T IndelRealigner -I $bamFile -R $refFile -targetIntervals $intervalFile -o $realignBam -known $millIndel -known $kgIndel -compress 0 2>010_realignGATK/errIndelRealigner > 010_realignGATK/indelRealignerInfo.txt";
    
    print "Step 2 finish\n";
    system "date";

}

#### Mark Duplicates ####

my $markDupBam = "020_markDupPicard/all.realigned.markDup.bam";

if($bMark eq "1"){

  print REPORT "Marking duplicates:\n\n";

  print "Mark duplicates ... start at\n";
  system "date";

  print REPORT "java -Xmx2g -jar $picardDir/MarkDuplicates.jar INPUT=$realignBam OUTPUT=$markDupBam METRICS_FILE=020_markDupPicard/markDup.metrics.txt CREATE_INDEX=TRUE VALIDATION_STRINGENCY=STRICT 2>020_markDupPicard/errMarkDup\n\n";
  system "java -Xmx2g -jar $picardDir/MarkDuplicates.jar INPUT=$realignBam OUTPUT=$markDupBam METRICS_FILE=020_markDupPicard/markDup.metrics.txt CREATE_INDEX=TRUE VALIDATION_STRINGENCY=STRICT 2>020_markDupPicard/errMarkDup";

  print "Mark duplicates ... finished\n";
  system "date";

}

#### Base quality score recalibration ####

if($bBqsr eq "1"){

  print REPORT "Doing Base Quality Score Recalibration:\n\n";

  print "Base quality score recalibration ... start at\n";
  system "date";

  print REPORT "Step 1: generating recal_data.grp for calibration ...\n";
  print "Step 1: generating recal_data.grp for calibration ... start at\n";
  system "date";

  my $grpFile = "030_BQRecalGATK/recal_data.grp";

  print REPORT "java -Xmx4g -jar $gatk -T BaseRecalibrator -I $markDupBam -R $refFile -knownSites $dbsnpFile -knownSites $millIndel -knownSites $kgIndel -L $intervalFile -o $grpFile -nct 3 2>030_BQRecalGATK/errBaseRecalibratorPre > 030_BQRecalGATK/baseRecalibratorPreInfo.txt\n\n";
  system "java -Xmx4g -jar $gatk -T BaseRecalibrator -I $markDupBam -R $refFile -knownSites $dbsnpFile -knownSites $millIndel -knownSites $kgIndel -L $intervalFile -o $grpFile -nct 3 2>030_BQRecalGATK/errBaseRecalibratorPre > 030_BQRecalGATK/baseRecalibratorPreInfo.txt";

  print "Step 1 finish\n";
  system "date";

  print REPORT "Step 2: generating post_recal_data.grp for ploting improvements ...\n";  print "Step 2: generating post_recal_data.grp for ploting improvements ...\n";  
  system "date";

  my $postgrpFile = "030_BQRecalGATK/post_recal_data.grp";

  print REPORT "java -Xmx4g -jar $gatk -T BaseRecalibrator -I $markDupBam -R $refFile -knownSites $dbsnpFile -knownSites $millIndel -knownSites $kgIndel -L $intervalFile -o $postgrpFile -BQSR $grpFile -nct 3 2>030_BQRecalGATK/errBaseRecalibratorPost > 030_BQRecalGATK/baseRecalibratorPostInfo.txt\n\n";
  system "java -Xmx4g -jar $gatk -T BaseRecalibrator -I $markDupBam -R $refFile -knownSites $dbsnpFile -knownSites $millIndel -knownSites $kgIndel -L $intervalFile -o $postgrpFile -BQSR $grpFile -nct 3 2>030_BQRecalGATK/errBaseRecalibratorPost > 030_BQRecalGATK/baseRecalibratorPostInfo.txt";

  print REPORT "Step 3: generating plot showing improvements ...\n";  
  print "Step 3: generating plot showing improvements ...\n";  
  system "date";

  my $plotFile = "030_BQRecalGATK/bqsr_plots.pdf";

  print REPORT "java -Xmx4g -jar $gatk -T AnalyzeCovariates -R $refFile -L $intervalFile -before $grpFile -after $postgrpFile -plots $plotFile 2>030_BQRecalGATK/errAnalyzeCovariates > 030_BQRecalGATK/analyzeCovariatesInfo.txt\n\n";
  system "java -Xmx4g -jar $gatk -T AnalyzeCovariates -R $refFile -L $intervalFile -before $grpFile -after $postgrpFile -plots $plotFile 2>030_BQRecalGATK/errAnalyzeCovariates > 030_BQRecalGATK/analyzeCovariatesInfo.txt";

  print REPORT "Step 4: generating results with original quality score for calibration ...\n";
  print "Step 4: generating results with original quality score for calibration ... start at\n";
  system "date";

  my $recalBam="../060_delivery/all.realigned.markDup.baseQreCali.bam";

  print REPORT "java -Xmx1g -jar $gatk -T PrintReads -R $refFile -I $markDupBam -BQSR $grpFile -EOQ -o $recalBam -L $intervalFile -nct 3 2>030_BQRecalGATK/errPrintReads > 030_BQRecalGATK/printReadsInfo.txt\n";
  system "java -Xmx1g -jar $gatk -T PrintReads -R $refFile -I $markDupBam -BQSR $grpFile -EOQ -o $recalBam -L $intervalFile -nct 3 2>030_BQRecalGATK/errPrintReads > 030_BQRecalGATK/printReadsInfo.txt";

  print "Step 4 finish\n";
  system "date";

}

print "Script finished\n";
system "date > end.out";
print REPORT "\n";
system "cat end.out >> reportPostAlignProcess.txt";
system "rm end.out";
close REPORT;

###################### INTRODUCTION ###############################################

#### Requirement ####
# bam file with:
# - sorted in coordinates in this way: chrM, chr1-22, chrX and chrY
# - indexed
# - with "read group" tags
# reference genome sorted in the same way
# dbSNP file sorted in the same way
# Java installed
# GATK installed
# Picard installed
# Samtools installed

#### Procedure ####
# Local realignment around indels to reduce false-positive SNPs around indels
# - Determining (small) suspicious intervals which are likely in need of realignment
# - Running the realigner over those intervals
# - Fixing the mate pairs of realigned reads

# Base quality score recalibration
# - CountCovariates
# - TableRecalibrate
# - samtools index on the recalibrated BAM file
# - CountCovariates again on the recalibrated BAM file
# - AnalyzedCovariates on both files to see the improvement by recalibration

