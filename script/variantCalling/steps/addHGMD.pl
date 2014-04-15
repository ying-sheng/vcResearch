#!/usr/bin/perl -w
use strict;

my ($inputVCF, $outputFile, $hgmdDir) = @ARGV;

my @annotationFiles = glob "$hgmdDir/*.vcf";

my $tagExpression;

# my $inputVCF = "all.filter.vcf";

if(-d "hgmd.vcf"){

  system "rm hgmd.vcf";

}

my $resultVCF;

foreach my $eachAnn (@annotationFiles){

  print "\n\nAdd $eachAnn\n\n";

  my $tag = $eachAnn;
  $tag =~ s/.*hgmd_(.*)\.vcf/$1/;

  my $resourceTag = join '_', "HGMD", $tag;

#  $tagExpression = "-E $resourceTag.amino -E $resourceTag.acc_num -E $resourceTag.disease -E $resourceTag.omimid -E $resourceTag.tag -E $resourceTag.comments -E $resourceTag.pmid -E $resourceTag.location -E $resourceTag.locref -E $resourceTag.deletion -E $resourceTag.insertion -E $resourceTag.type -E $resourceTag.score -E $resourceTag.wildtype ";
  $tagExpression = "-E $resourceTag.amino -E $resourceTag.acc_num -E $resourceTag.disease -E $resourceTag.omimid -E $resourceTag.tag -E $resourceTag.comments -E $resourceTag.pmid -E $resourceTag.location -E $resourceTag.locref -E $resourceTag.deletion -E $resourceTag.insertion ";

  $resultVCF = join '.', "all.filter", $tag, "vcf";

  my $err = join '_', "err", $tag;
  my $info = join '_', "info", $tag;

  print "java -Xmx4g -jar /Volumes/data.odin/ying/researchBundle/tools/GenomeAnalysisTK-2.8-1-g932cd3a/GenomeAnalysisTK.jar \n-T VariantAnnotator \n-R /Volumes/data.odin/ying/researchBundle/refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/human_g1k_v37_decoy.fasta \n--variant $inputVCF \n-L $inputVCF \n--resource:$resourceTag $eachAnn \n$tagExpression \n-o $resultVCF\n2>$err >$info\n\n";

  system "java -Xmx4g -jar /Volumes/data.odin/ying/researchBundle/tools/GenomeAnalysisTK-2.8-1-g932cd3a/GenomeAnalysisTK.jar -T VariantAnnotator -R /Volumes/data.odin/ying/researchBundle/refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/human_g1k_v37_decoy.fasta --variant $inputVCF -L $inputVCF --resource:$resourceTag $eachAnn $tagExpression -o $resultVCF 2>$err >$info";

  system "intersectBed -wa -a $eachAnn -b $inputVCF >> hgmd.vcf";

  $inputVCF = $resultVCF;

}

print "Will change $inputVCF to $outputFile\n\n";

system "mv $inputVCF $outputFile";
