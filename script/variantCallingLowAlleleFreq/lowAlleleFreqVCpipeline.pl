#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;

print "\n\n#######################\n\n\nThe script you are running now and all the scripts calling by the script are only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

my $configFile = shift;

# $bamFile : a file with all the absolute path of WES BAM files (e.g. samples.txt)
# $regionFile : a file with all the regions which want to extract reads (e.g. tsc12.bed), in format chr:start-end and 1-based
# $configFile : all the locations of ref files, tools

my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";

# Sample
my $bamFile = $configuration->val("Sample","bamFile");
my $regionFile = $configuration->val("Sample","regionFile");

# Tools
my $samtoolsDir = $configuration->val("Tools","samtoolsFolder");
my $picardDir = $configuration->val("Tools","picard");
my $novoalign = $configuration->val("Tools","novoalign");

# Data
my $novoalignRef = $configuration->val("Data","novoalignRef");
my $samtoolsRef = $configuration->val("Data","samtoolsRef");

if(!(-d "fastqFiles")){
  system "mkdir fastqFiles";
}

if(!(-d "analysis")){
  system "mkdir analysis";
}

if(!(-d "annotation")){
  system "mkdir annotation";
}

if(!(-d "result")){
  system "mkdir result";
}


open BAM, $bamFile or die;
open EXT, ">fastqFiles/extractReads.bash" or die;
open ANA, ">analysis/analysis.bash" or die;
while(my $bam = <BAM>){

  chomp $bam;

  my ($bamFile, $sampleID, $rg) = split / +/, $bam;
  $bamFile = (split /\t+/, $bamFile)[0];
  $sampleID = (split /\t+/, $sampleID)[0];
  $rg = (split /\t+/, $rg)[0];

  # Extract reads in the chosen regions
  my $extractBamFile = join '.', $sampleID, "region", "bam";
  print EXT "$samtoolsDir/samtools view -b -L $regionFile $bamFile > $extractBamFile\n";
  # Convert back the recalibrated base quality to original base quality
  my $oqBamFile = join '.', $sampleID, "region", "OQ", "bam";
  print EXT "java -Xmx4g -jar $picardDir/RevertSam.jar INPUT=$extractBamFile OUTPUT=$oqBamFile RESTORE_ORIGINAL_QUALITIES=TRUE SORT_ORDER=coordinate CREATE_INDEX=TRUE 2>errRevertSam_$sampleID\n";
  # Convert back from BAM to FASTQ files
  my $read1File = join '.', $sampleID, "region", "R1", "fastq";
  my $read2File = join '.', $sampleID, "region", "R2", "fastq";
  print EXT "java -Xmx4g -jar $picardDir/SamToFastq.jar INPUT=$oqBamFile FASTQ=$read1File SECOND_END_FASTQ=$read2File 2>errSamToFastq_$sampleID\n\n";

  # alignment by novoalign
  my $samFile = join '.', $sampleID, "sam";
  my $novoalignLog = join ".", $sampleID, "novoalign", "Stats", "txt";
  print ANA "$novoalign/novoalign -F STDFQ -f ../fastqFiles/$read1File ../fastqFiles/$read2File -o SAM \$\'$rg\' -c 99 -r None -i PE 200,50 -d $novoalignRef > $samFile 2>$novoalignLog\n";
  # fix mate information
  my $alignPosiSrt = join '.', $sampleID, "posiSrt", "bam";
  print ANA "java -Xmx4g -jar $picardDir/FixMateInformation.jar INPUT=$samFile OUTPUT=$alignPosiSrt CREATE_INDEX=TRUE SORT_ORDER=coordinate 2>errFixMateInformation_$sampleID\n";
  # remove duplicates
  my $rmdupBam = join '.', $sampleID, "posiSrt", "rmdup", "bam";
  print ANA "$samtoolsDir/samtools rmdup $alignPosiSrt $rmdupBam 2>errSamtoolsRmdup_$sampleID\n";
  # samtools variant calling
  my $rawVcf = join '.', $sampleID, "var", "raw", "bcf";
  print ANA "$samtoolsDir/samtools mpileup -uf $samtoolsRef $rmdupBam | $samtoolsDir/bcftools/bcftools view -bvcg -P flat - > $rawVcf 2>errSamtoolsVC_$sampleID\n";
  # variant filtration
  my $fltVcf = join '.', $sampleID, "var", "flt", "vcf";
  my $finalVcf = join '.', $sampleID, "var", "flt", "final", "vcf";
  print ANA "$samtoolsDir/bcftools/bcftools view $rawVcf | $samtoolsDir/bcftools/vcfutils.pl varFilter -a 3 -1 0.01 -2 0.01 -4 0.01 -3 0.01 > $fltVcf 2>errVarFilter_$sampleID\n";
  print ANA "perl $FindBin::Bin/filtration.pl $fltVcf > $finalVcf\n\n";


}
close BAM;
close ANA;
close EXT;
