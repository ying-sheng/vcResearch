#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;

# The script will output the following QC parameters:
# - capture efficiency : 1 - OFF_BAIT_BASES/PF_UQ_BASES_ALIGNED
# - MEAN_TARGET_COVERAGE
# - MEAN_INSERT_SIZE, STANDARD_DEVIATION
# - PCT_READS_ALIGNED_IN_PAIRS
# will save all these qc values under sample folder root: qcReport.txt

my ($configFile, $hideMessage) = @ARGV;

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}

my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";
my $dbsnpFile = $configuration->val("Data","dbSNP137");

chdir("030_postAlignQC");

open QC, "> ../qcReport.txt" or die;

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

chdir("../040_variantCalling");

my $fDir = "../050_postVarCalProcess/gatk/010_qualityFiltration";
my $tranchFile = "$fDir/snp.vqsr.output.tranches";
my $tsFilterLevel = "99";

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

chdir("../050_postVarCalProcess/gatk/020_annovarAnnotation");

open QC, ">> ../../../qcReport.txt" or die;
# - Number of PF Exonic Variants
# - the number of novel PF (pass in the filter column) non-synonymous SNPs

my $noPFexonicVariants = `grep 'exonic' allAnnotation.hg19_multianno.txt | grep 'PASS' |cut -f7|grep -v 'ncRNA_exonic'|wc -l`;
chomp $noPFexonicVariants;

my $noPFnonsynonymousSNP = `grep 'PASS' allAnnotation.hg19_multianno.txt |grep 'nonsynonymous'|cut -f15|grep -c 'NA'`;
chomp $noPFnonsynonymousSNP;

print QC "No. of PF Exonic Variants : $noPFexonicVariants\n";
print QC "No. novel PF non-synonymous SNPs : $noPFnonsynonymousSNP\n";

close QC;
