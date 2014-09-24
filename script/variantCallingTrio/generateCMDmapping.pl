#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/lib/";
use Config::IniFiles;

# This script will generate a mapping command file for running alignment


print "\n\n#######################\n\n\nThe script you are running now is only for Research purpose and for no other purpose.\n\n\n#######################\n\n\n";

print "\nPlease specify how will you do alignment, \"condor\" or \"else\"? \n\nIf you choose \"condor\", Please copy all the fastq files from run folder to /condor_sh/projects; the folder structure should be the same as the original run folder, e.g. Project_excap/Sample_excap1/*.fastq.gz\n\n2, Log into Tor as root,\n\nchange the permission by:\nchmod -R 777 Project_excap\n\nchange owner, group as SBSUser by:\nchown -R SBSUser:SBSUser Project_excap\n\n3, log out from root\n\nIf you haven't done the above, you can stop this script now and run it again when it is ready, otherwise press return \n\nIf you choose \"else\", Please copy all the fastq files from run folder to anywhere you want; the folder structure should be the same as the original run folder, e.g. Project_excap/Sample_excap1/*.fastq.gz\n\n";

my $mappingLoc = <>;
chomp $mappingLoc;

my $mappingDir;
if($mappingLoc eq 'condor'){
  $mappingDir = "/condor_sh/projects";
}elsif($mappingLoc eq 'else'){
  print "\nPlease specify absolute path to where you put the Project directory\n\n";
  $mappingDir = <>;
  chomp $mappingDir;
}else{
  die "You put wrong input, you can only choose condor or else\n";
}

##### Get information to find files on the condor

print "After all the files have been transferred, Input the project name, in this case - Project_excap\n\n";
my $project = <>;
chomp $project;

print "\nInput the run name: \n\n"; # in case the run ID is not in the name of the QC report
my $runName = <>;
chomp $runName;

my $condorCommandPre = "/data/condor_scripts/submit_align_nsc_V2.1 -r -p -n -q $project"; 

# print "Please input the absolute path to condor_sh/projects\n\n";

# my $condor_sh = <>;
# chomp $condor_sh;

chdir("$mappingDir/$project");

my @sampleFolders = glob "Sample*";

print "\nMaking the folder structure in the condor required data structure and generate mapping commands (saved in commandMapping.bash under each sample/data) ......\n\nA sample configuration file (sampleMac.conf) is also generated in the same folder to start further analysis after alignment\nA group configuration file (groupMac.conf) is generated under the Project folder, which can be used for running analysis on a batch of samples\n\n";

##### Get information to find path for tools and necessary files for analysis

print "\nPlease input the full path to the researchBundle, the default is \"/Volumes/data.odin/ying/researchBundle\" if you just press return\n\n";
my $researchBundle = <>;
chomp $researchBundle;
if(!$researchBundle){
  $researchBundle = "/Volumes/data.odin/ying/researchBundle";
}

print "\nPlease input the full path to the dataDistro, the default is \"$researchBundle/refData/dataDistro_r01_d01\" if you just press return\n\n";
my $dataDistro = <>;
chomp $dataDistro;
if(!$dataDistro){
  $dataDistro = "$researchBundle/refData/dataDistro_r01_d01";
}

print "\nPlease input the full path to the script folder (git local copy), the default is \"$FindBin::Bin\" if you just press return\n\n";
my $scriptDistro = <>;
chomp $scriptDistro;
if(!$scriptDistro){
  $scriptDistro = "$FindBin::Bin";
}


print "Please input the full path to the software folder, the default is \"$researchBundle/tools\" if you just press return\n\n";
my $softDistro = <>;
chomp $softDistro;
if(!$softDistro){
  $softDistro = "$researchBundle/tools";
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

#    my $runName = `ls *Read1.qc.pdf`;
#    chomp $runName;
#    $runName = (split /\./, $runName)[0];

    chdir("data");

    my @info = split /-/, $eachSample;

    my $captureKit = $info[-1];
    print "Does the capture kits is $captureKit (y or n) ?\n\n";
    my $captureKitRes = <>;
    chomp $captureKitRes;

    if($captureKitRes eq 'n'){
      print "Please print the capture kit (Av5)\n\n";
      $captureKit = <>;
      chomp $captureKit;
    }

    ##### Generate sample configuration file
    
    open PROFILE, ">sample.conf" or die;

    ## General information about the sample
    print PROFILE "[Sample]\n";
    print PROFILE "runID = $runName\n";
    print PROFILE "project = $project\n";
    print PROFILE "sampleID = $eachSample\n";

#    my @scriptPath = split /\//, $scriptDistro;
#    pop @scriptPath;
#    pop @scriptPath;
#    pop @scriptPath;
#    my $amgPath = join '/', @scriptPath;

    if($captureKit eq 'Av5'){

      if(-d "$dataDistro/b37/captureKits/wex_Agilent_SureSelect_v05_b37"){
	print PROFILE "captureKit = $dataDistro/b37/captureKits/wex_Agilent_SureSelect_v05_b37\n";
      }else{
	print "Can not find $dataDistro/b37/captureKits/wex_Agilent_SureSelect_v05_b37 for captureKit\n";
      }

    }

    ## variant calling pipeline version
    print PROFILE "\n[Version]\n";

#    my $tempDir = `pwd`;
#    chomp $tempDir;
#    chdir($amgPath);

#    my $vcVersion = `git describe --tag`;
#    chomp $vcVersion;
#    $vcVersion =~ s/(.*20\d\d)-.*/$1/;

#    my $currentTagCommit = `git rev-parse $vcVersion`;
#    chomp $currentTagCommit;

#    my $currentHeadCommit = `git rev-parse HEAD`;
#    chomp $currentHeadCommit;

#   if($currentTagCommit eq $currentHeadCommit){
#      print PROFILE "variantCallingPipelineVersion = $vcVersion\n";
#    }else{
#      print "Please check the version of pipeline!!\n\nCurrent Commit $currentHeadCommit\nCurrent Version Commit $vcVersion\n";
#      exit;
#    }

#    print PROFILE "variantCallingPipelineVersion = $currentHeadCommit\n";
#    print PROFILE "variantCallingPipelineVersion = $vcVersion\n";

#    chdir($tempDir);

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

    $softwareName = "novoalign"; 
    $softwarePath = $softwareConfiguration->val("all","novoalignLinux");
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

    $dataName = "novoalignRef"; 
    $dataPath = $dataConfiguration->val("genomic","genomeB37DecoyNovoalign3index");
    if(-e "$dataDistro/$dataPath"){
      print PROFILE "$dataName = $dataDistro/$dataPath\n";
    }else{
      print "Can not find $dataDistro/$dataPath for $dataName";
    }

    $dataName = "wesCoverageRegion"; 
    $dataPath = "$researchBundle/refData/wesCoverage/cdExon.ucsc.refGene.knowGene.unique.geneName.flanking2bp.bed";
    if(-e "$dataPath"){
      print PROFILE "$dataName = $dataPath\n";
    }else{
      print "Can not find $dataPath for $dataName";
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

#    my $inhouseDB = glob "$researchBundle/refData/inHouseDB/current/*AFandGF.txt";
    print PROFILE "inhDB = $researchBundle/refData/inHouseDB/current/variant.combine.filter.20140204.AFandGF.txt\n";
#    print PROFILE "snpFingerPrintingRegion = $amgPath/snpFingerPrinting/intervals/snpFingerPrintingPos.interval_list\n";

    ## Script information
    print PROFILE "\n[Script]\n";
    print PROFILE "scriptPath = $scriptDistro\n";

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

      my $command;

      if($mappingLoc eq 'condor'){
	$command = join ' ', $condorCommandPre, "-s $eachSample -i $runName $currDir/$fastqR1 $currDir/$fastqR2";
      }elsif($mappingLoc eq 'else'){
	system "mkdir -p ../mapping_folder/logs";
	system "mkdir -p ../mapping_folder/results";

	$command = ""
	
      }
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

