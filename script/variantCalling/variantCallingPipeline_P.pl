#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/lib/";
use Config::IniFiles;

print "\n\n#######################\n\n\nThe script you are running now and all the scripts calling by the script are only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";


my $configFile = shift;

# must have sample.conf

my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";

##### Construct Directory Structure

print "########### Set up directory structures .....\n\n"; # if the folder didn't exist, generate it

if(!(-d "000_fastqFilesAndQC")){
  system "mkdir 000_fastqFilesAndQC";
}

if(!(-d "010_alignment")){ 
  system "mkdir 010_alignment";
}

if(!(-d "020_refineAlignment")){
  system "mkdir 020_refineAlignment";
}

if(!(-d "030_postAlignQC")){
  system "mkdir 030_postAlignQC";
}

if(!(-d "040_variantCalling")){
  system "mkdir 040_variantCalling";
}

if(!(-d "050_postVarCalProcess")){
  system "mkdir 050_postVarCalProcess";
}

if(!(-d "060_delivery")){
  system "mkdir 060_delivery";
}

if(-e "qcReport.txt"){

  system "rm qcReport.txt";

}

##### Main inputs and options

print "########### Get main inputs and options from profileFile.txt or command line .....\n\n"; # need: run name, project name, sample ID and capture kits

my $runID = $configuration->val("Sample","runID");
my $project = $configuration->val("Sample","project");
my $sampleID = $configuration->val("Sample","sampleID");
my $captureKitDir = $configuration->val("Sample","captureKit");

my $captureV = $captureKitDir;
$captureV =~ s/.*\/(.*)$/$1/;
my $intervalTarget = join '.', $captureV, "baits", "list";
my $intervalBait = join '.', $captureV, "baits", "list";
my $intervalFile = join '.', $captureV, "baits", "slop50", "merged", "list";

$intervalTarget = join '/', $captureKitDir, $intervalTarget;
$intervalBait = join '/', $captureKitDir, $intervalBait;
$intervalFile = join '/', $captureKitDir, $intervalFile;


my $scriptPath = "$FindBin::Bin";

if(!(-e "$intervalTarget")){
  
  print "Interval files for target doesn't exist (please write in this format <abs path>/<file name>):";
  $intervalTarget = <>;
  chomp $intervalTarget;

}

if(!(-e "$intervalBait")){
  
  print "Interval files for bait doesn't exist (please write in this format <abs path>/<file name>):";
  $intervalBait = <>;
  chomp $intervalBait;

}
 
if(!(-e "$intervalFile")){
 
  print "Interval files for variant calling (please write in this format <abs path>/<file name>):";
  $intervalFile = <>;
  chomp $intervalFile;
  
}

my @bamFiles = `ls /Volumes/condor_share.berlin/projects/$project/$sampleID/mapping*/results/*.posiSrt.bam`;

my $currentDir = `pwd`;
chomp $currentDir;

my $bamIndex;
if(scalar(@bamFiles) > 1){

  my $bamString = join "\n", @bamFiles;
  print "Please specify the input bam files, there are more than one mapping folders under condor (0 for the 1st bam, 1 for the 2nd bam, etc)\n";
  print "$bamString\n\n";
  $bamIndex = <>;
  chomp $bamIndex;
  
}

my $bamFile;
if($bamIndex){

  $bamFile = $bamFiles[$bamIndex];

}else{

  $bamFile = $bamFiles[0];

}

chomp $bamFile;

print "The script will work with $bamFile\n";
print "\nAnd interval files used in the analysis are followings: \n\n$intervalTarget - for WES target coverage calculation\n$intervalBait - for WES bait coverage calculation\n$intervalFile - for WES variant calling\n\n";

##### Copy fastq files and fastqc files to 000_fastqFilesAndQC
# system "rsync -ruap /condor_sh/projects/$project/$sampleID/data/*.fastq.gz 000_fastqFilesAndQC";
system "rsync -ruap /Volumes/condor_share.berlin/projects/$project/$sampleID/*.pdf 000_fastqFilesAndQC";

##### Check and copy all log/necessary files for alignment to 010_alignment

my $bamFilePath = $bamFile;
$bamFilePath =~ s/(.*)\/results\/.*/$1/;

my @checkAlignment = `grep -i done $bamFilePath/logs/*`;
my @alignLogs = glob "$bamFilePath/logs/*";
if((scalar(@checkAlignment) != scalar(@alignLogs)) or (scalar(@alignLogs) < 3)){
  print "The alignment doesn't finish properly. The following are finished steps:\n";
  print join ("\n", @checkAlignment), "\n";
  print "Please check and rerun the script\n";
  exit;  
}

system "mkdir 010_alignment/result";
system "mkdir 010_alignment/logs";

system "rsync -ruaP /Volumes/condor_share.berlin/projects/$project/$sampleID/mapping*/logs/* 010_alignment/logs";
system "rsync -ruaP /Volumes/condor_share.berlin/projects/$project/$sampleID/mapping*/results/collectAlignmentSummaryMetrics.txt 010_alignment/result";

system "rsync -ruaP $configFile ./";

##### Refinement of alignment

print "\n########### Refinement of alignment .....\n\n";

chdir("020_refineAlignment");

print "Checking which steps have been done ......\n\n";

my ($bRealign, $bMark, $bBqsr) = (2,2,2);

if(!(-d "010_realignGATK")){ # if the analysis is NOT done, $bRealign = 1 

  $bRealign = 1;        
  system "mkdir 010_realignGATK";    

}else{
  
  chdir("010_realignGATK");

  if(-e "indelRealignerInfo.txt"){
    $bRealign = checkCompleted("010_realignGATK", "gatk");  # if there is err message, $bRealign = 1
  }else{
    $bRealign = 1;
  }

  chdir("../");
  
}

if(!(-d "020_markDupPicard")){

  $bMark = 1;
  system "mkdir 020_markDupPicard";

}else{

  chdir("020_markDupPicard");

  if(-e "errMarkDup"){
    $bMark = checkCompleted("020_markDupPicard", "picard");
  }else{
    $bMark = 1;
  }

  chdir("../");

}

if(!(-d "030_BQRecalGATK")){

  $bBqsr = 1;
  system "mkdir 030_BQRecalGATK";

}else{
  
  chdir("030_BQRecalGATK");

  if(-e "printReadsInfo.txt"){
    $bBqsr = checkCompleted("030_BQRecalGATK", "gatk");
  }else{
    $bBqsr = 1;
  }

  chdir("../");
  
}

my $refineAlignCode = join '', $bRealign, $bMark, $bBqsr;

if(($bRealign == 2) and ($bMark == 2) and ($bBqsr == 2)){

  print "All steps in refinement of alignments are finished successfully\n\n";

}else{

  print "Current work directory:\n";
  system "pwd";

  system "perl $scriptPath/steps/refineAlignment.pl $bamFile $refineAlignCode $configFile 1";

}

##### post-alignment QC

print "########### Evaluate alignment, insertion size and coverage .....\n\n";

chdir("../030_postAlignQC");

print "Checking which steps have been done ......\n\n";

my ($bAlignSum, $bInsertSum, $bHsMetrics, $bInHouse) = (2,2,2,2);

if(!(-d "010_collectAlignmentSummaryMetrics")){

  $bAlignSum = 1;
  system "mkdir 010_collectAlignmentSummaryMetrics";
  print "The 010_collectAlignmentSummaryMetrics need to be performed\n"; 

}else{
  
  chdir("010_collectAlignmentSummaryMetrics");

  if(-e "errCollectAlignmentSummaryMetrics"){
    $bAlignSum = checkCompleted("010_collectAlignmentSummaryMetrics", "picard");  
  }else{
    $bAlignSum = 1;
  }

  chdir("../");
  
}

if(!(-d "020_collectInsertSizeMetrics")){

  $bInsertSum = 1;
  system "mkdir 020_collectInsertSizeMetrics";
  print "The 020_collectInsertSizeMetricss need to be performed\n"; 

}else{

  chdir("020_collectInsertSizeMetrics");

  if(-e "errCollectInsertSizeMetrics"){
    $bInsertSum = checkCompleted("020_collectInsertSizeMetrics", "picard");
  }else{
    $bInsertSum = 1;
  }

  chdir("../");

}

if(!(-d "030_calculateHsMetrics")){

  $bHsMetrics = 1;
  system "mkdir 030_calculateHsMetrics";
  print "The 030_calculateHsMetrics need to be performed\n"; 

}else{
  
  chdir("030_calculateHsMetrics");

  if(-e "errCalculateHsMetrics"){
    $bHsMetrics = checkCompleted("030_calculateHsMetrics", "picard");
  }else{
    $bHsMetrics = 1;
  }

  chdir("../");
  
}

if(!(-d "040_coverageIn-house")){

  $bInHouse = 1;
  system "mkdir 040_coverageIn-house";
  print "The 040_coverageIn-house need to be performed\n"; 

}else{
  
  chdir("040_coverageIn-house");

  if(!(-e "coverage_per_cdExon.10.tsv") or (-z "coverage_per_cdExon.10.tsv")){
    $bInHouse = 1;
  }

  chdir("../");
  
}

my $postAlignQCCode = join '', $bAlignSum, $bInsertSum, $bHsMetrics, $bInHouse;

if(($bAlignSum == 2) and ($bInsertSum == 2) and ($bHsMetrics == 2) and ($bInHouse == 2)){

  print "All steps are finished successfully\n\n";

}else{

  print "Current work directory:\n";
  system "pwd";
  
  $bamFile="$currentDir/060_delivery/all.realigned.markDup.baseQreCali.bam";

  system "perl $scriptPath/steps/postAlignQC.pl $bamFile $intervalTarget $intervalBait $postAlignQCCode $configFile 1";

}

##### Variant Calling

print "########### Variant calling and VQSR/hard filtration .....\n\n";

chdir("../040_variantCalling");

print "Current work directory:\n";
system "pwd";

print "\nChecking whether the following steps have been done ......\n\n\tvariant calling\n\tvariant quality filtration\n\n";

my ($bVarCall, $bVarFilter) = (2,2); # The one has been dane will be non-defined, hasn't been done, value is 1

if(!(-d "gatk")){

  $bVarCall = 1;
  system "mkdir gatk";
  print "The variant calling need to be performed\n";    

}else{
  
  chdir("gatk");

  if(-e "selectVariantsIndelInfo.txt"){
    $bVarCall = checkCompleted("variant calling", "gatk");  
  }else{
    $bVarCall = 1;
  }

  chdir("../");
  
}

chdir("../");
if(!(-d "050_postVarCalProcess/gatk/010_qualityFiltration")){

  $bVarFilter = 1;
  system "mkdir -p 050_postVarCalProcess/gatk/010_qualityFiltration";
  chdir("040_variantCalling");
  print "The variant quality filtration need to be performed\n";

}else{

  chdir("050_postVarCalProcess/gatk/010_qualityFiltration");

  if(-e "combineVariantsInfo.txt"){
    $bVarFilter = checkCompleted("variant filtration", "gatk");
  }else{
    $bVarFilter = 1;
  }

  chdir("../../../040_variantCalling");

}

my $variantCallingCode = join '', $bVarCall, $bVarFilter, "1";

if(($bVarCall == 2) and ($bVarFilter == 2)){

#  print "\nAll steps are finished successfully\nPlease manually check whether the SNP fingerprinting sites are called\n\n";
  print "\nAll steps are finished successfully\n\n";

}else{

  $bamFile = "$currentDir/060_delivery/all.realigned.markDup.baseQreCali.bam";

  system "perl $scriptPath/steps/variantCallingGATK.pl $bamFile $intervalFile $configFile $variantCallingCode 1";

}

system "mkdir -p ../050_postVarCalProcess/gatk/020_annovarAnnotation";

chdir("../050_postVarCalProcess/gatk/020_annovarAnnotation");


##### annotation with annovar

print "########### Variant annotation .....\n\n";

system "perl $scriptPath/steps/annotationAnnovar_P.pl ../010_qualityFiltration/all.filter.vcf $configFile 1";

chdir("../../../");

##### Doing SNP finger printing checking automatically

# print "########### Comparing snp finger printing results betwen HTS and Taqman ......\n\n";

# my $amgPath = $scriptPath;
# $amgPath =~ s/(.*\/script\/amg).*/$1/;

# open REPORT, "> 070_QC/snpFingerPrintingReport.txt" or die;
# print REPORT "Running this under the root of Sample folder\n\npython $amgPath/fingerprinting/MergeResults.py\n";
# system "python $amgPath/fingerprinting/testData/MergeResults.py";
# system "cp 070_QC/snp.raw.snpFingerPrintingTest*report* 060_delivery";

print "The script is finished\n";

sub checkCompleted{

  my ($step, $type) = @_;

  my (@matchErr, @matchWarn, @matchInfo, @matchException, $noFilesErr, $noFilesInfo, $boolean);
  
  if($type eq 'gatk'){

    @matchInfo = `grep "Total runtime" *Info.txt`;
    $noFilesInfo = `ls -l *Info.txt|wc -l`;
    chomp $noFilesInfo;
    $noFilesInfo =~ s/.*(\d+)$/$1/;
    
    @matchErr = `grep "ERROR" err*`;
    $noFilesErr = `ls -l err*|wc -l`;
    chomp $noFilesErr;
    $noFilesErr =~ s/.*(\d+)$/$1/;
    
    if(!@matchErr and (scalar(@matchInfo) == $noFilesInfo)){
      $boolean = 2;
      print "The $step step was finished ..... \n\n";
    }else{
      $boolean = 1;
    }

  }elsif($type eq 'picard'){

    @matchErr = `grep "ERROR" err*`;
    @matchWarn = `grep "WARN" err*`;
    @matchException = `grep "Exception" err*`;

    my @done = `grep "done" err*`;

    if(!@matchErr and !@matchException and (scalar(@done) >= 1)){

      $boolean = 2;
      print "The $step was finished ...... \n\n";

      my $warningLine = join "\n", @matchWarn;
      print "It got the following warning message:\n\n$warningLine\n\n";

    }else{

            $boolean = 1;

    }

  }

  return $boolean; # if the process was NOT running OK, the $boolean = 1

}
