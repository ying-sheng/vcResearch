#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Config::IniFiles;

print "\n\n#######################\n\n\nThe script you are running now and all the scripts calling by the script are only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

my $configFile = shift;

my $configuration = Config::IniFiles->new(-file => $configFile) or die "Could not open $configFile!";

# Sample
my $bamFile = $configuration->val("Sample","bamFile");

# Tools
my $annovarDir = $configuration->val("Tools","annovar");
my $gatkDir = $configuration->val("Tools","gatk");
my $otherScriptDir = $configuration->val("Tools","otherDir");

# Data
my $hgmd = $configuration->val("Data","hgmd");
my $samtoolsRef = $configuration->val("Data", "samtoolsRef");
my $dataRepoRef = $configuration->val("Data", "dataRepoRef");

open OUT, ">annotation.bash" or die;
open IN, $bamFile or die;
while(my $line = <IN>){

  chomp $line;

  my ($eachBam, $sampleID) = (split / +/, $line)[0,1];

  my $varResult = join '.', $sampleID, "var", "flt", "final", "vcf";
  my $varResultR = join '.', $sampleID, "var", "flt", "final", "b37", "vcf";
  my $hgmdResult = join '.', $sampleID, "var", "flt", "final", "hgmd", "vcf";
  my $hgmdCVresult = join '.', $sampleID, "var", "flt", "final", "hgmd", "avinput";
  my $annovarResult = join '.', $sampleID, "hg19_multianno", "txt";
  my $refinedAnnovar = join '.', $sampleID, "hg19_multianno", "hgmd", "txt";

  print OUT "echo $sampleID\n";
  print OUT "perl $FindBin::Bin/reformat.pl ../analysis/$varResult > $varResultR\n";
  print OUT "perl $otherScriptDir/steps/addHGMD.pl $varResultR $hgmdResult $hgmd $gatkDir $dataRepoRef\n";
  print OUT "perl $annovarDir/convert2annovar.pl --format vcf4old --includeinfo --chrmt MT --withzyg $hgmdResult > $hgmdCVresult 2>errConvert2annovarAll_$sampleID\n";
  print OUT "perl $annovarDir/table_annovar.pl $hgmdCVresult $annovarDir/humandb/ --buildver hg19 --outfile $sampleID --otherinfo --nastring NA --gff3dbfile repeatMasker_hg19_all.gff3 -protocol \'gff3,refGene,phastConsElements46way,genomicSuperDups,esp6500si_all,1000g2012apr_all,snp137,avsift,ljb2_all,clinvar_20140211,ljb23_metalr,ljb23_metasvm,caddgt10\' --operation \'r,g,r,r,f,f,f,f,f,f,f,f,f\' 2>errTableAnnovarAll_$sampleID\n";
  print OUT "perl $otherScriptDir/steps/refineHGMD.pl $annovarResult hgmd.vcf > $refinedAnnovar\n\n";

}
close IN;
close OUT;
