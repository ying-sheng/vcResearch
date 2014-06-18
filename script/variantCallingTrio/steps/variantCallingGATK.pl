#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;

# The script need to be done under 040_variantCalling
# The script will output the following QC parameters:
# - Total number of variants
# - % in dbSNP build 
# - Transition/Transversion (Ti/Tv) ratio for known and novel
# - the heterozygosity to non-reference homozygosity ratio (het/hom), PF variants


# The 
# BEGIN {require "/Users/yingsh/home/script/variaitonCalling/GATK2.0-agilentV4/config.pl";}
# is under KEY INPUTS part

###################### INTRODUCTION ###############################################

# blank currently

###################### KEY INPUTS ###############################################

my ($bamFile, $intervalFile, $configFile, $code, $hideMessage) = @ARGV;

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}



my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";


my ($bVarCall, $bVarFilter, $bSNPFinger) = split //, $code;

# reference file
my $refFile = $configuration->val("Data","genomeB37DecoyFasta");

# files required by GATK variation calling
my $dbsnpFile = $configuration->val("Data","dbSNP137");

# tools
my $gatkDir = $configuration->val("Tool","gatk");
my $gatk = "$gatkDir/GenomeAnalysisTK.jar";

# data
my $omni = $configuration->val("Data","omni");
my $hapmap = $configuration->val("Data","hapmap3");
my $kgSNP = $configuration->val("Data","kgsnp");
my $snpFingerPrinting = $configuration->val("Data","snpFingerPrintingRegion");

# how many threads can be used
my $nt = 3;

###################### ANALYSIS ##########################################

my $callConf = 50;
my $emitConf = 10;
my $allRawOut = "gatk/all.raw.vcf";
my $snpRawOut = "gatk/snp.raw.vcf";
my $indelRawOut = "gatk/indel.raw.vcf";

open REPORT, ">> reportVarCalFilter.txt";

if($bVarCall == 1){

  system "date > start.out";
  system "echo \"The process is started at: \" > reportVarCalFilter.txt";
  system "head start.out >> reportVarCalFilter.txt";
  system "rm start.out";

  print REPORT "The original input BAM file is:\n$bamFile\n\n";
  print REPORT "The interval file used for variant calling is:\n$intervalFile\n\n";

##### variant calling

  print REPORT "The commands used in this step:\n\n";
  
  print REPORT "Calling variants\n";
  print "Variant calling ... start at -----";
  system "date";

  print REPORT "java -Xmx4g -jar $gatk -R $refFile -T UnifiedGenotyper -I $bamFile --dbsnp $dbsnpFile -o $allRawOut -stand_call_conf $callConf -stand_emit_conf $emitConf -L $intervalFile -nt $nt -glm BOTH -dcov 200 2>gatk/errUnifiedGenotyper > gatk/unifiedGenotyperInfo.txt\n\n";
  system "java -Xmx4g -jar $gatk -R $refFile -T UnifiedGenotyper -I $bamFile --dbsnp $dbsnpFile -o $allRawOut -stand_call_conf $callConf -stand_emit_conf $emitConf -L $intervalFile -nt $nt -glm BOTH -dcov 200 2>gatk/errUnifiedGenotyper > gatk/unifiedGenotyperInfo.txt";

  print "Finish variant calling -----";
  system "date";

##### Extracting snp calls

  print REPORT "Extract SNP calls\n";
  print "Extract SNP calls ... start at -----";
  system "date";

  print REPORT "java -Xmx2g -jar $gatk \n-R $refFile \n-T SelectVariants \n--variant $allRawOut \n-o $snpRawOut \n-selectType SNP \n-nt $nt \n2>gatk/errSelectVariantsSNP \n> gatk/selectVariantSNPInfo.txt\n\n";
  system "java -Xmx2g -jar $gatk -R $refFile -T SelectVariants --variant $allRawOut -o $snpRawOut -selectType SNP -nt $nt 2>gatk/errSelectVariantsSNP > gatk/selectVariantsSNPInfo.txt";

  print "Finish extracting SNP calls -----";
  system "date";

##### Extracting indel calls

  print REPORT "Extract INDEL calls\n";
  print "Extract INDEL calls ... start at -----";
  system "date";

  print REPORT "java -Xmx2g -jar $gatk \n-R $refFile \n-T SelectVariants \n--variant $allRawOut \n-o $indelRawOut \n-selectType INDEL \n-nt $nt \n2>gatk/errSelectVariantsIndel \n> gatk/selectVariantsIndelInfo.txt\n\n";
  system "java -Xmx2g -jar $gatk -R $refFile -T SelectVariants --variant $allRawOut -o $indelRawOut -selectType INDEL -nt $nt 2>gatk/errSelectVariantsIndel > gatk/selectVariantsIndelInfo.txt";

  print "Finish extracting INDEL calls -----";
  system "date";

}

##### Construct directory system for "050_postVarCalProcess"

my $fDir = "../050_postVarCalProcess/gatk/010_qualityFiltration";
my $recalFile = "$fDir/snp.vqsr.output.recal";
my $tranchFile = "$fDir/snp.vqsr.output.tranches";
my $rscriptFile = "$fDir/snp.vqsr.output.plots.R";
my $tsFilterLevel = "99";

if($bVarFilter == 1){

##### SNP VQSR

  print REPORT "SNP Variant Quality Score Recalibration:\n";
  print "SNP Variant Quality Score Recalibration ... start at -----";
  system "date";

  print REPORT "- Doing VariantRecalibrator\n";

  print REPORT "java -Xmx4g -jar $gatk -T VariantRecalibrator -R $refFile -input $snpRawOut -resource:hapmap,known=false,training=true,truth=true,prior=15.0 $hapmap -resource:omni,known=false,training=true,truth=false,prior=12.0 $omni -resource:1000G,known=false,training=true,truth=false,prior=10.0 $kgSNP -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $dbsnpFile -an QD -an MQRankSum -an ReadPosRankSum -an FS -recalFile $recalFile -tranchesFile $tranchFile -rscriptFile $rscriptFile --maxGaussians 4 -mode SNP 2>$fDir/errVariantRecalibratorSNP > $fDir/variantRecalibratorSNPInfo.txt\n\n";
  system "java -Xmx4g -jar $gatk -T VariantRecalibrator -R $refFile -input $snpRawOut -resource:hapmap,known=false,training=true,truth=true,prior=15.0 $hapmap -resource:omni,known=false,training=true,truth=false,prior=12.0 $omni -resource:1000G,known=false,training=true,truth=false,prior=10.0 $kgSNP -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $dbsnpFile -an QD -an MQRankSum -an ReadPosRankSum -an FS -recalFile $recalFile -tranchesFile $tranchFile -rscriptFile $rscriptFile --maxGaussians 4 -mode SNP 2>$fDir/errVariantRecalibratorSNP > $fDir/variantRecalibratorSNPInfo.txt";

  print REPORT "- Doing ApplyRecalibration\n";

  print REPORT "java -Xmx3g -jar $gatk -T ApplyRecalibration -R $refFile -input $snpRawOut -mode SNP --ts_filter_level $tsFilterLevel -tranchesFile $tranchFile -recalFile $recalFile -o $fDir/snp.recalibrated.filtered.vcf > $fDir/applyRecalibrationSNPInfo.txt\n\n";

  system "java -Xmx3g -jar $gatk -T ApplyRecalibration -R $refFile -input $snpRawOut -mode SNP --ts_filter_level $tsFilterLevel -tranchesFile $tranchFile -recalFile $recalFile -o $fDir/snp.recalibrated.filtered.vcf > $fDir/applyRecalibrationSNPInfo.txt";

  print "Finish SNP Variant Quality Score Recalibration -----";
  system "date";

##### Indel hard filtering

  print REPORT "INDEL hard filtration:\n";
  print "INDEL hard filtration ... start at -----";
  system "date";

  print REPORT "java -Xmx2g -jar $gatk \n-R $refFile \n-T VariantFiltration \n-o $fDir/indel.hardFiltered.vcf \n--variant $indelRawOut \n--filterExpression \"QD < 2.0\" \n--filterExpression \"ReadPosRankSum < -20.0\" \n--filterExpression \"FS > 200.0\" \n--filterName QDFilter \n--filterName ReadPosFilter \n--filterName FSFilter \n2>../050_postVarCalProcess/gatk/010_qualityFiltration/errVariantFiltrationIndel \n>../050_postVarCalProcess/gatk/010_qualityFiltration/variantFiltrationIndelInfo.txt\n\n";
  system "java -Xmx2g -jar $gatk -R $refFile -T VariantFiltration -o $fDir/indel.hardFiltered.vcf --variant $indelRawOut --filterExpression \"QD < 2.0\" --filterExpression \"ReadPosRankSum < -20.0\" --filterExpression \"FS > 200.0\" --filterName QDFilter --filterName ReadPosFilter --filterName FSFilter 2>../050_postVarCalProcess/gatk/010_qualityFiltration/errVariantFiltrationIndel >../050_postVarCalProcess/gatk/010_qualityFiltration/variantFiltrationIndelInfo.txt";

  print "Finish INDEL hard filtration -----";
  system "date";

##### Merge SNP and Indel filtration vcf files

  print REPORT "Merge SNP and Indel filtration vcf files:\n";
  print "Merge SNP and Indel filtration vcf files ... start at -----";
  system "date";

  print REPORT "java -Xmx2g -jar $gatk \n-R $refFile \n-T CombineVariants \n--variant $fDir/snp.recalibrated.filtered.vcf \n--variant $fDir/indel.hardFiltered.vcf  \n-o $fDir/all.filter.vcf \n2>$fDir/errCombineVariants \n> $fDir/combineVariantsInfo.txt\n";
  system "java -Xmx2g -jar $gatk -R $refFile -T CombineVariants --variant $fDir/snp.recalibrated.filtered.vcf --variant $fDir/indel.hardFiltered.vcf -o $fDir/all.filter.vcf 2>$fDir/errCombineVariants > $fDir/combineVariantsInfo.txt";

}

if($bSNPFinger == 1){

  print REPORT "Doing variant calling for SNP fingerprinting test sites\n";
  print "Variant calling on SNP fingerprinting test sites ... start at -----";
  system "date";

  print REPORT "java -Xmx4g -jar $gatk -R $refFile -T UnifiedGenotyper -I $bamFile --dbsnp $dbsnpFile -o gatk/snp.raw.snpFingerPrintingTest.vcf -stand_call_conf $callConf -stand_emit_conf 0 -L $snpFingerPrinting -nt $nt -glm BOTH -dcov 200 --output_mode EMIT_ALL_SITES 2>gatk/errSnpFingerPrintingTestUnifiedGenotyper > gatk/snpFingerPrintingTestUnifiedGenotyperInfo.txt\n";

  system "java -Xmx4g -jar $gatk -R $refFile -T UnifiedGenotyper -I $bamFile --dbsnp $dbsnpFile -o gatk/snp.raw.snpFingerPrintingTest.vcf -stand_call_conf $callConf -stand_emit_conf 0 -L $snpFingerPrinting -nt $nt -glm BOTH -dcov 200 --output_mode EMIT_ALL_SITES 2>gatk/errSnpFingerPrintingTestUnifiedGenotyper > gatk/snpFingerPrintingTestUnifiedGenotyperInfo.txt";

  system "cp gatk/snp.raw.snpFingerPrintingTest.vcf* ../060_delivery/";

}

open QC, ">> ../qcReport.txt" or die;
print QC "\n##########\n\nQuality of Variant Calling\n\n##########\n\n";

my $noPFSNPs = `grep -v '^#' $fDir/snp.recalibrated.filtered.vcf | cut -f7 |grep -c 'PASS'`;
chomp $noPFSNPs;

my $noKnownPFSNPs = `grep -v '^#' $fDir/snp.recalibrated.filtered.vcf | grep 'PASS' | cut -f3 |grep -c 'rs'`;
chomp $noKnownPFSNPs;

my $knownTTratio = `grep '^99.00' $tranchFile |cut -f4 -d','`;
chomp $knownTTratio;

my $novalTTratio = `grep '^99.00' $tranchFile |cut -f5 -d','`;
chomp $novalTTratio;

my $noPFhetSNP = `grep -v '^#' $fDir/snp.recalibrated.filtered.vcf | grep 'PASS' | cut -f10 |cut -f1 -d':'|grep -vc '1/1'`;
chomp $noPFhetSNP;

my $noPFhomSNP = `grep -v '^#' $fDir/snp.recalibrated.filtered.vcf | grep 'PASS' | cut -f10 |cut -f1 -d':'|grep -c '1/1'`;
chomp $noPFhomSNP;

print QC "Total No. of PF SNPs (No. of known PF SNPs) : $noPFSNPs ($noKnownPFSNPs)\n";
$dbsnpFile =~ s/.*\/(.*)/$1/;
print QC "% in dbSNP build ($dbsnpFile) : ", $noKnownPFSNPs/$noPFSNPs, "\n";
print QC "known PF SNPs Ti/Tv ratio (--ts_filter_level $tsFilterLevel) : $knownTTratio\n";
print QC "noval PF SNPs Ti/Tv ratio (--ts_filter_level $tsFilterLevel) : $novalTTratio\n";
print QC "PF SNP het/hom ratio : ", $noPFhetSNP/$noPFhomSNP, "\n";

close QC;

# - Total number of PF SNPs
# - % in dbSNP build (PF SNPs) 
# - Transition/Transversion (Ti/Tv) ratio for known and novel SNPs
# - the heterozygosity to non-reference homozygosity ratio (het/hom), PF SNPs


print "The script is finished -----";
system "date";

close REPORT;

