#!/usr/bin/perl -w
use strict;


my ($annFile, $columnP, $vcfFile, $freqFile, $outputFile, $hideMessage, $transcriptFile) = @ARGV;

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}

my $index = 0;
my %vcfIndex;
open CP, $columnP or die;
while(my $cp = <CP>){

  chomp $cp;
  $vcfIndex{$cp} = $index;
  $index ++;

}
close CP;

my %freq;
my $totalSampleNo;

open FREQ, $freqFile or die;
while(my $freq = <FREQ>){

  if($freq !~ /^#/){

    chomp $freq;
    my @info = split /\t/, $freq;
    my $chr = shift @info;
    my $start = shift @info;
    shift @info;
    my $ref = shift @info;
    my $alt = shift @info;
    shift @info;
    my $filter = shift @info;
    shift @info;
    shift @info;

    if(!$totalSampleNo){
      $totalSampleNo = scalar(@info) - 2;
    }

    my $info_gt = $info[-2];
    my $info_af = $info[-1];

    foreach my $k_gt(split /;/, $info_gt){

      my ($gt, $gtf) = split /=/, $k_gt;

      $freq{"$chr\t$start"}->{$gt} = $gtf;

    }

    foreach my $k_af(split /;/, $info_af){

      my ($af, $aff) = split /=/, $k_af;

      $freq{"$chr\t$start"}->{$af} = $aff;

    }

    $freq{"$chr\t$start"}->{"infoGT"} = $info_gt;
    $freq{"$chr\t$start"}->{"infoAF"} = $info_af;
    $freq{"$chr\t$start"}->{"filter"} = $filter;

#    print "$freq\t$info\t$info_a\n";

  }

}
close FREQ;

my %transcript;

if($transcriptFile){

  open TRANS, $transcriptFile or die;
  while(my $trans = <TRANS>){

    if($trans !~ /^#/){

      chomp $trans;
      my $transcriptID = (split /\t/, $trans)[3];
      $transcript{$transcriptID} = 1;
      #  print "\n";

    }

  }
  close TRANS;

}

my %alt; # only record multi-allelic site
open VCF, $vcfFile or die;
while(my $vcf = <VCF>){

  if($vcf !~ /^#/){

    my ($vChr, $vStart, $vAlt) = (split /\t/, $vcf)[0,1,4];

    if($vAlt =~ /,/){
      $alt{"$vChr\t$vStart"} = $vAlt;
    }

  }


}
close VCF;


my $headerString;
open OUT, ">$outputFile" or die;

# print OUT "# $sampleID\n";
# my $gp = $transcriptFile;
# $gp =~ s/.*\/(.*)$/$1/;
# print OUT "# $gp\n";
# print OUT "# Variant Calling Pipeline is $pipelineVersion\n\n";

open ANN, $annFile or die;
while(my $ann = <ANN>){

  chomp $ann;

  my @anns = split /\t/, $ann;

  if($ann =~ /Chr/){

    # VCF Chr - 32
    # VCF Start - 33
    # VCF Ref - 35
    # VCF Alt - 36
    # Func.refGene - 6
    # Gene.refGene - 7
    # ExonicFunc.refGene - 8
    # AAChange.refGene - 9
    # esp6500si_all - 12
    # 1000g2012apr_all - 13
    # intDb_alleleFrequency(132)	
    # intDb_genotypeFrequency(66)	
    # intDb_filter	
    # snp137 - 14
    # VCF_QUAL - 37
    # VCF_FILTER - 38
    # VCF_GT_genotype - 41-0
    # VCF_AD_AlleleDepth - 41-1
    # VCF_DP_depth - 41-2
    # avsift - 15
    # LJB2_SIFT - 16
    # LJB2_PolyPhen2_HDIV - 17
    # LJB2_LRT - 21
    # LJB2_MutationTaster - 23
    # LJB_MutationAssessor - 25
    # LJB2_FATHMM - 27
    # LJB2_GERP++ - 28
    # LJB2_PhyloP - 29
    # LJB2_SiPhy - 30
    # repeatMasker - 5
    # phastConsElements46way - 10
    # VCF_GQ_genotypeQuality - 41-3
    # VCF_PL_genotypeProbability - 41-4
    # VCF_Info - 39

    $headerString = join '', "VCF_CHR\tVCF_START\tVCF_REF\tVCF_ALT\tFunc.refGene\tGene.refGene\tExonicFunc.refGene\tAAChange.refGene\tesp6500si_all\t1000g2012apr_all\tintDb_alleleFrequency(",$totalSampleNo*2,")\tintDb_genotypeFrequency($totalSampleNo)\tintDb_filter\tHGMD.acc_num\tHGMD.disease\tHGMD.alleleChange\tHGMD.score\tHGMD.type\tHGMD.wildtype\tclinvar_20140211\tsnp137\tVCF_QUAL\tVCF_FILTER\tVCF_GT_genotype\tVCF_AD_AlleleDepth\tVCF_DP_depth\tljb23_metalr\tljb23_metasvm\tavsift\tLJB2_SIFT\tLJB2_PolyPhen2_HDIV\tLJB2_PolyPhen2_HVAR\tLJB2_LRT\tLJB2_MutationTaster\tLJB_MutationAssessor\tLJB2_FATHMM\tLJB2_GERP++\tLJB2_PhyloP\tLJB2_SiPhy\trepeatMasker\tphastConsElements46way\tVCF_GQ_genotypeQuality\tVCF_PL_genotypeProbability\tVCF_INFO";

    print OUT "$headerString\n";

  }else{

    # Get selected transcript

    if(($anns[9] ne 'NA') and (lc($anns[9]) ne 'unknown')){

      if(%transcript){

	my $found;

	foreach my $aa(split /,/, $anns[9]){

	  if($transcript{(split /:/, $aa)[1]}){
	    $anns[9] = $aa;
	    $found = 1;
	    last;
	  }

	}

	if(!$found){
	  print "can not find selected transcript, print origianl transcript annotation ------------ $anns[9]\n";
	}

      }
#      print "\n";

    }

    # Get allele frequency

    my ($indbal, $indbgt, $indbaf_all, $indbgt_all, $indb_filter);

    my $annRef = $anns[44];
    my $annAlt = $anns[45];

    my $annAltCom;
    if($alt{"$anns[41]\t$anns[42]"}){
      $annAltCom = $alt{"$anns[41]\t$anns[42]"};
    }


    my %b;
    $b{"0"} = $annRef;

    my $n = 1;
    my $splitAlt = $annAlt;
    if($annAltCom){
      $splitAlt = $annAltCom;
    }

    foreach my $eAl(split /,/, $splitAlt){
      $b{$n} = $eAl;
      $n ++;
    }

    my $ngt;
    my @ngt;
    my $g = (split /:/, $anns[-1])[0];

    foreach my $eg (split /\//, $g){
      push @ngt, $b{$eg};
    }

    $ngt = join '/', (sort @ngt);

    if($freq{"$anns[41]\t$anns[42]"}->{$ngt}){
      $indbgt = $freq{"$anns[41]\t$anns[42]"}->{$ngt};
    }else{
      $indbgt = "NA";
    }

    foreach my $bkey (keys %b){

      if($bkey != 0){

	if($freq{"$anns[41]\t$anns[42]"}->{$b{$bkey}}){
	  
	  if(!$indbal){
	    $indbal = $freq{"$anns[41]\t$anns[42]"}->{$b{$bkey}};
	  }else{
	    $indbal = join ',', $indbal, $freq{"$anns[41]\t$anns[42]"}->{$b{$bkey}};
	  }

	}

      }

    }

    if(!$indbal){
      $indbal = 'NA';
    }

    if($freq{"$anns[41]\t$anns[42]"}->{"infoGT"}){
      $indbgt_all = $freq{"$anns[41]\t$anns[42]"}->{"infoGT"};
    }else{
      $indbgt_all = "NA";
    }

    if($freq{"$anns[41]\t$anns[42]"}->{"infoAL"}){
      $indbaf_all = $freq{"$anns[41]\t$anns[42]"}->{"infoAF"};
    }else{
      $indbaf_all = "NA";
    }

    if($freq{"$anns[41]\t$anns[42]"}->{"filter"}){
      $indb_filter = $freq{"$anns[41]\t$anns[42]"}->{"filter"};
    }else{
      $indb_filter = "NA";
    }

#    splice(@anns, 5,0,"$indbal\t$indbgt\t$indbal_all\t$indbgt_all\t$indb_filter");
#    $string = join("\t", @anns);

    # VCF Chr - 32
    # VCF Start - 33
    # VCF Ref - 35
    # VCF Alt - 36
    # Func.refGene - 6
    # Gene.refGene - 7
    # ExonicFunc.refGene - 8
    # AAChange.refGene - 9
    # esp6500si_all - 12
    # 1000g2012apr_all - 13
    # intDb_alleleFrequency(132)	
    # intDb_genotypeFrequency(66)	
    # intDb_filter	
    # snp137 - 14
    # VCF_QUAL - 37
    # VCF_FILTER - 38
    # VCF_GT_genotype - 41-0
    # VCF_AD_AlleleDepth - 41-1
    # VCF_DP_depth - 41-2
    # avsift - 15
    # LJB2_SIFT - 16
    # LJB2_PolyPhen2_HDIV - 17
    # LJB2_LRT - 21
    # LJB2_MutationTaster - 23
    # LJB_MutationAssessor - 25
    # LJB2_FATHMM - 27
    # LJB2_GERP++ - 28
    # LJB2_PhyloP - 29
    # LJB2_SiPhy - 30
    # repeatMasker - 5
    # phastConsElements46way - 10
    # VCF_GQ_genotypeQuality - 41-3
    # VCF_PL_genotypeProbability - 41-4
    # VCF_Info - 39

    print OUT "$anns[41]\t$anns[42]\t$anns[44]\t$anns[45]\t$anns[6]\t$anns[7]\t$anns[8]\t$anns[9]\t$anns[12]\t$anns[13]\t$indbal\t$indbgt\t$indb_filter\t$anns[34]\t$anns[35]\t$anns[36]\t$anns[37]\t$anns[38]\t$anns[39]\t$anns[31]\t$anns[14]\t$anns[46]\t$anns[47]\t$anns[40]-$g\t", (split /:/, $anns[50])[1], "\t", (split /:/, $anns[50])[2], "\t$anns[32]\t$anns[33]\t$anns[15]\t$anns[16]\t$anns[17]\t$anns[19]\t$anns[21]\t$anns[23]\t$anns[25]\t$anns[27]\t$anns[28]\t$anns[29]\t$anns[30]\t$anns[5]\t$anns[10]\t", (split /:/, $anns[50])[3], "\t", (split /:/, $anns[50])[4], "\t$anns[48]\n";

  }

}
close ANN;
close OUT;
