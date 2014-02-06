#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/lib/";
use Config::IniFiles;

print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";


print "\n1, Please copy all the fastq files from run folder to /condor_sh/projects; the folder structure should be the same as the original run folder, e.g. Project_excap/Sample_excap1/*.fastq.gz\n\n2, Log into Tor as root,\n\nchange the permission by:\nchmod -R 777 Project_excap\n\nchange owner, group as SBSUser by:\nchown -R SBSUser:SBSUser Project_excap\n\n3, log out from root\n\nIf you haven't done the above, you can stop this script now and run it again when it is ready, otherwise press return \n\n";

<>;

print "After all the files have been transferred, Input the project name, in this case - Project_excap\n\n";

##### Get information to find files on the condor

my $project = <>;
chomp $project;

print "\nInput the run name: \n\n";

my $runName = <>;
chomp $runName;

my $commandPre = "/data/condor_scripts/submit_align_nsc_V2.1 -r -p -n -q $project"; 

chdir("/condor_sh/projects/$project");

my @sampleFolders = glob "Sample*";

print "\nMaking the folder structure in the condor required data structure and generate mapping commands (saved in commandMapping.bash under each sample/data) ......\n\nA sample configuration file (sampleMac.conf) is also generated in the same folder to start further analysis after alignment\nA group configuration file (groupMac.conf) is generated under the Project folder, which can be used for running analysis on a batch of samples\n\n";

##### Get information to find path for tools and necessary files for analysis

print "\nPlease input the full path to the diagnosticBundle, the default is \"/Volumes/data.odin/diagnosticBundle\" if you just press return\n\n";
my $diagBundle = <>;
chomp $diagBundle;
if(!$diagBundle){
  $diagBundle = "/Volumes/data.odin/diagnosticBundle";
}

print "\nPlease input the full path to the dataDistro, the default is \"$diagBundle/refData/dataDistro_r01_d01_diag\" if you just press return\n\n";
my $dataDistro = <>;
chomp $dataDistro;
if(!$dataDistro){
  $dataDistro = "$diagBundle/refData/dataDistro_r01_d01_diag";
}

print "\nPlease input the full path to the script folder (git local copy), the default is \"$FindBin::Bin\" if you just press return\n\n";
my $scriptDistro = <>;
chomp $scriptDistro;
if(!$scriptDistro){
  $scriptDistro = "$FindBin::Bin";
}


print "Please input the full path to the software folder, the default is \"$diagBundle/tools\" if you just press return\n\n";
my $softDistro = <>;
chomp $softDistro;
if(!$softDistro){
  $softDistro = "$diagBundle/tools";
}


##### Generate configuraiton file for each sample

open GPROFILE, ">group.conf" or die;

foreach my $eachSample(@sampleFolders){

  if(-d $eachSample){

    chdir($eachSample);

    print "Working on sample $eachSample --- ";

    if(-d "data"){
      print "data folder is already existed, will not move the fastq files *****\n\n";
    }else{

      system "mkdir data";
      system "mv *.gz data";

    }

    chdir("data");

    my @info = split /-/, $eachSample;

    my $genePanel = $info[-3];
    my $captureKit = $info[-1];

    ##### Generate sample configuration file
    
    open PROFILE, ">sample.conf" or die;

    ## General information about the sample
    print PROFILE "[Sample]\n";
    print PROFILE "runID = $runName\n";
    print PROFILE "project = $project\n";
    print PROFILE "sampleID = $eachSample\n";
    my $genePanelFolderName = join '_', $genePanel, "OUS", "medGen", "v01", "b37"; 

    my @scriptPath = split /\//, $scriptDistro;
    pop @scriptPath;
    pop @scriptPath;
    pop @scriptPath;
    my $amgPath = join '/', @scriptPath;

    if(-d "$amgPath/clinicalGenePanels/$genePanelFolderName"){
      print PROFILE "genePanel = $amgPath/clinicalGenePanels/$genePanelFolderName\n";
    }else{
      print "Can not find $amgPath/clinicalGenePanels/$genePanelFolderName for genePanel\n";
    }

    if($captureKit eq 'Av5'){

      if(-d "$dataDistro/b37/captureKits/wex_Agilent_SureSelect_v05_b37"){
	print PROFILE "captureKit = $dataDistro/b37/captureKits/wex_Agilent_SureSelect_v05_b37\n";
      }else{
	print "Can not find $dataDistro/b37/captureKits/wex_Agilent_SureSelect_v05_b37 for captureKit\n";
      }

    }

    ## variant calling pipeline version
    print PROFILE "\n[Version]\n";
    my $tempCurrentDir = `pwd`;
    chomp $tempCurrentDir;
    chdir($amgPath);
    my $vcVersion = `git describe --tag`;
    chomp $vcVersion;
    $vcVersion =~ s/(.*20\d\d)-.*/$1/;

#    my $versionDiff = `diff $amgPath/.git/refs/tags/$vcVersion $amgPath/.git/refs/heads/dev`;
    my $versionDiff = `diff $amgPath/.git/refs/tags/$vcVersion $amgPath/.git/refs/heads/newVCpipelineDiag`;
    chdir($tempCurrentDir);

    if(!$versionDiff){
      $vcVersion =~ s/.*tags\/(.*)/$1/;
      print PROFILE "variantCallingPipelineVersion = $vcVersion\n";
    }else{
      print "Please check the version of pipeline!!\n\n$versionDiff\n";
      exit;
    }

    ## Software information
    print PROFILE "\n[Tool]\n";
    my $softwareConfiguration = Config::IniFiles->new(-file => "$softDistro/softwareRepo.conf") or die "Could not open $softDistro/softwareRepo.conf";
    my $softwareName = "picard"; 
    my $softwarePath = $softwareConfiguration->val("all","picard");

    if(-d "$softDistro/$softwarePath"){
      print PROFILE "$softwareName = $softDistro/$softwarePath\n";
    }else{
      print "Can not find $softDistro/$softwarePath for $softwareName\n";
    }
      
    $softwareName = "annovar"; 
    $softwarePath = $softwareConfiguration->val("all","annovar");
    if(-d "$softDistro/$softwarePath"){
      print PROFILE "$softwareName = $softDistro/$softwarePath\n";
    }else{
      print "Can not find $softDistro/$softwarePath for $softwareName\n";
    }

    $softwareName = "bedtools"; 
    if($softDistro =~ /Volumes/){
      $softwarePath = $softwareConfiguration->val("all","bedtoolsMac");
    }else{
      $softwarePath = $softwareConfiguration->val("all","bedtoolsLinux");
    }

    if(-d "$softDistro/$softwarePath"){
      print PROFILE "$softwareName = $softDistro/$softwarePath\n";
    }else{
      print "Can not find $softDistro/$softwarePath for $softwareName\n";
    }

    $softwareName = "gatk"; 
    $softwarePath = $softwareConfiguration->val("all","gatk");
    if(-d "$softDistro/$softwarePath"){
      print PROFILE "$softwareName = $softDistro/$softwarePath\n";
    }else{
      print "Can not find $softDistro/$softwarePath for $softwareName\n";
    }

    ## Data information
    print PROFILE "\n[Data]\n";
    my $dataConfiguration = Config::IniFiles->new(-file => "$dataDistro/dataRepo.conf") or die "Could not open $softDistro/softwareRepo.conf";
    my $dataName = "genomeB37DecoyFasta"; 
    my $dataPath = $dataConfiguration->val("genomic","genomeB37DecoyFasta");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

    $dataName = "omni"; 
    $dataPath = $dataConfiguration->val("variantDbs","omni");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

    $dataName = "dbSNP137"; 
    $dataPath = $dataConfiguration->val("variantDbs","dbSNP137");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

    $dataName = "hapmap3"; 
    $dataPath = $dataConfiguration->val("variantDbs","hapmap3");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

    $dataName = "kgIndels"; 
    $dataPath = $dataConfiguration->val("variantDbs","g1kIndels");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

    $dataName = "millsIndels"; 
    $dataPath = $dataConfiguration->val("variantDbs","millsIndels");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

    $dataName = "kgsnp"; 
    $dataPath = $dataConfiguration->val("variantDbs","g1kSnps");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

#    my $inhouseDB = glob "$diagBundle/refData/inHouseDB/current/*AFandGF.txt";
    print PROFILE "inhDB = $diagBundle/refData/inHouseDB/current/variant.combine.filter.20140204.AFandGF.txt\n";
    print PROFILE "snpFingerPrintingRegion = $amgPath/snpFingerPrinting/intervals/snpFingerPrintingPos.interval_list\n";

    ## Script information
    print PROFILE "\n[Script]\n";
    print PROFILE "scriptPath = $scriptDistro\n";
    print PROFILE "coveragePath = $amgPath/variantcalling/qc/coverage\n";

    close PROFILE;

    my $sampleProfile = `pwd`;
    chomp $sampleProfile;
    $sampleProfile = join '/', $sampleProfile, "sample.conf";
    print GPROFILE "$eachSample\t$sampleProfile\n";

    open OUT, ">commandMapping.bash" or die;
    my @fastqs = glob "*R1*.gz";

    foreach my $fastqR1(@fastqs){
      
      my $currDir = `pwd`;
      chomp $currDir;

      my $fastqR2 = $fastqR1;
      $fastqR2 =~ s/_R1_/_R2_/;

      my $command = join ' ', $commandPre, "-s $eachSample -i $runName $currDir/$fastqR1 $currDir/$fastqR2";
      print OUT "$command\n";

    }
    close OUT;

#    system "chmod 777 commandMapping.bash";

    print "Done!\n";
    chdir("../..");
    

  }

}

close GPROFILE;

print "Now you can go into tor and run each commandMapping.bash file\n\nGood Luck!\n\n";

