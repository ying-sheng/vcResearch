#!/usr/bin/perl -w
use strict;


my ($annFile, $vcfFile, $freqFile, $outputFile, $hideMessage, $transcriptFile) = @ARGV;

if(!$hideMessage){

  print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

}


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
  my $string;

  if($ann =~ /Chr/){

    my @vcfItems = qw(VCF_CHR VCF_POS VCF_ID VCF_REF VCF_ALT VCF_QUAL VCF_FILTER VCF_INFO VCF_FORMAT VCF_SAMPLE);

    my @allHeader = (@anns, @vcfItems);

    for(my $i = 0; $i < scalar(@allHeader); $i ++){

      print "$i\t$allHeader[$i]\n";

    }

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

    print OUT "$allHeader[32]\t$allHeader[33]\t$allHeader[35]\t$allHeader[36]\t$allHeader[6]\t$allHeader[7]\t$allHeader[8]\t$allHeader[9]\t$allHeader[12]\t$allHeader[13]\tintDb_alleleFrequency(",$totalSampleNo*2,")\tintDb_genotypeFrequency($totalSampleNo)\tintDb_filter\t$allHeader[14]\t$allHeader[37]\t$allHeader[38]\tVCF_GT_genotype\tVCF_AD_AlleleDepth\tVCF_DP_depth\t$allHeader[15]\t$allHeader[16]\t$allHeader[17]\t$allHeader[19]\t$allHeader[21]\t$allHeader[23]\t$allHeader[25]\t$allHeader[27]\t$allHeader[28]\t$allHeader[29]\t$allHeader[30]\trepeatMasker\t$allHeader[10]\tVCF_GQ_genotypeQuality\tVCF_PL_genotypeProbability\t$allHeader[39]\n";

#    splice(@anns, 5,0,"in-dbAL","in-dbGT","in-dbAL_all","in-dbGT_all","in-dbFilter");
#    $string = join("\t", @anns);
#    print "$string\n";

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

    my $annRef = $anns[35];
    my $annAlt = $anns[36];

    my $annAltCom;
    if($alt{"$anns[32]\t$anns[33]"}){
      $annAltCom = $alt{"$anns[32]\t$anns[33]"};
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

    if($freq{"$anns[32]\t$anns[33]"}->{$ngt}){
      $indbgt = $freq{"$anns[32]\t$anns[33]"}->{$ngt};
    }else{
      $indbgt = "NA";
    }

    foreach my $bkey (keys %b){

      if($bkey != 0){

	if($freq{"$anns[32]\t$anns[33]"}->{$b{$bkey}}){
	  
	  if(!$indbal){
	    $indbal = $freq{"$anns[32]\t$anns[33]"}->{$b{$bkey}};
	  }else{
	    $indbal = join ',', $indbal, $freq{"$anns[32]\t$anns[33]"}->{$b{$bkey}};
	  }

	}

      }

    }

    if(!$indbal){
      $indbal = 'NA';
    }

    if($freq{"$anns[32]\t$anns[33]"}->{"infoGT"}){
      $indbgt_all = $freq{"$anns[32]\t$anns[33]"}->{"infoGT"};
    }else{
      $indbgt_all = "NA";
    }

    if($freq{"$anns[32]\t$anns[33]"}->{"infoAL"}){
      $indbaf_all = $freq{"$anns[32]\t$anns[33]"}->{"infoAF"};
    }else{
      $indbaf_all = "NA";
    }

    if($freq{"$anns[32]\t$anns[33]"}->{"filter"}){
      $indb_filter = $freq{"$anns[32]\t$anns[33]"}->{"filter"};
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

    print OUT "$anns[32]\t$anns[33]\t$anns[35]\t$anns[36]\t$anns[6]\t$anns[7]\t$anns[8]\t$anns[9]\t$anns[12]\t$anns[13]\t$indbal\t$indbgt\t$indb_filter\t$anns[14]\t$anns[37]\t$anns[38]\t$anns[31]-$g\t", (split /:/, $anns[41])[1], "\t", (split /:/, $anns[41])[2], "\t$anns[15]\t$anns[16]\t$anns[17]\t$anns[19]\t$anns[21]\t$anns[23]\t$anns[25]\t$anns[27]\t$anns[28]\t$anns[29]\t$anns[30]\t$anns[5]\t$anns[10]\t", (split /:/, $anns[41])[3], "\t", (split /:/, $anns[41])[4], "\t$anns[39]\n";

#"$anns[6]\t$anns[7]\t$anns[8]\t$anns[9]\t$anns[12]\t$anns[13]\tintDb_alleleFrequency(88)\tintDb_genotypeFrequency(44)\tintDb_filter\t$anns[14]\tQUAL\tFILTER\tGT_genotype\tAD_AlleleDepth\tDP_depth\tChr\tStart\tRef\tAlt\t$anns[15]\t$anns[16]\t$anns[18]\t$anns[20]\t$anns[22]\t$anns[24]\t$anns[26]\trepeatMasker\t$anns[11]\t$anns[10]\tGQ_genotypeQuality\tPL_genotypeProbability\tvcfInfo\n";


  #  print "$anns[6]\t$anns[7]\t";

  }

#  my @test = split /\t/, $string;
#  if(scalar(@test) != 44){
#    print "$string\n";
#  }
  

#  print "$string\n";

}
close ANN;
close OUT;
