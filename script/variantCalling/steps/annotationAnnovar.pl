#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;

# The script need to be performed under 050_postVarCalProcess/gatk/020_annovarAnnotation
# The script will output the following QC parameters:
# - Number of PF Exonic Variants
# - the number of novel PF (pass in the filter column) non-synonymous SNPs


# The 
# BEGIN {require "/Users/yingsh/home/script/variaitonCalling/GATK2.0-agilentV4/config.pl";}
# is under KEY INPUTS part

###################### INTRODUCTION ###############################################

# blank currently

###################### CHECKING WHICH STEPS HAVE BEEN FINISHED #####################

print "\nChecking whether the following steps have been done ......\n\n\tannotation\n\n";

if(-e "allAnnotation.hg19_multianno.txt"){
  
  print "The annotation has been finished\n\n";
  exit 0;
  
}else{
  
  print "The annotation need to be performed\n";
  
}

###################### KEY INPUTS ###############################################

my ($file, $configFile, $hideMessage) = @ARGV;

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}

my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";

my $sampleID = $configuration->val("Sample","sampleID");
my $pipelineVersion = $configuration->val("Version", "variantCallingPipelineVersion");

my $scriptPath = $configuration->val("Script", "scriptPath");

my $inhDB = $configuration->val("Data", "inhDB");

my $annovarDir = $configuration->val("Tool","annovar");
my $bedDir = $configuration->val("Tool", "bedtools");

system "date > start.out";
system "echo \"The process is started at: \" > reportVarAnnotation.txt";
system "head start.out >> reportVarAnnotation.txt";
system "rm start.out";

open REPORT, ">> reportVarAnnotation.txt";

#### Converting VCF into annovar format

print "\nStart to convert VCF to avinput ----- ";
system "date";
print "\n";

#print REPORT "perl $annovarDir/convert2annovar.pl --format vcf4 --includeinfo --chrmt MT --allallele --withzyg $file > all.filter.avinput 2>errConvert2annovarAll\n";
#system "perl $annovarDir/convert2annovar.pl --format vcf4 --includeinfo --chrmt MT --allallele --withzyg $file > all.filter.avinput 2>errConvert2annovarAll";

print REPORT "perl $annovarDir/convert2annovar.pl --format vcf4old --includeinfo --chrmt MT --withzyg $file > all.filter.avinput 2>errConvert2annovarAll\n";
system "perl $annovarDir/convert2annovar.pl --format vcf4old --includeinfo --chrmt MT --withzyg $file > all.filter.avinput 2>errConvert2annovarAll";

print "Start to do annotation by annovar ----- ";
system "date";
print "\n";

print REPORT "perl $annovarDir/table_annovar.pl all.filter.avinput $annovarDir/humandb/ --buildver hg19 --outfile allAnnotation --otherinfo --nastring NA --gff3dbfile repeatMasker_hg19_all.gff3 -protocol 'gff3,refGene,phastConsElements46way,genomicSuperDups,esp6500si_all,1000g2012apr_all,snp137,avsift,ljb2_all' --operation 'r,g,r,r,f,f,f,f,f' 2>errTableAnnovarAll\n";
system "perl $annovarDir/table_annovar.pl all.filter.avinput $annovarDir/humandb/ --buildver hg19 --outfile allAnnotation --otherinfo --nastring NA --gff3dbfile repeatMasker_hg19_all.gff3 -protocol 'gff3,refGene,phastConsElements46way,genomicSuperDups,esp6500si_all,1000g2012apr_all,snp137,avsift,ljb2_all' --operation 'r,g,r,r,f,f,f,f,f' 2>errTableAnnovarAll";

print "Start to add in-house db frequency and find the right transcript ----- ";
system "date";
print "\n";

print REPORT "perl $scriptPath/steps/refineAnnotation.pl allAnnotation.hg19_multianno.txt $file $inhDB allAnnotation.hg19_multianno.freq.txt 1\n";
system "perl $scriptPath/steps/refineAnnotation.pl allAnnotation.hg19_multianno.txt $file $inhDB allAnnotation.hg19_multianno.freq.txt 1";

system "cp allAnnotationInCand.hg19_multianno.freq.txt ../../../060_delivery/";

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
