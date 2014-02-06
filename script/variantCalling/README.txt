# How to use these scripts to do variant calling for diagnostic samples

##### Step 1: Generate condor alignment commands and profileFile for each samples

# can be run within any directory, need Project name and Run ID during
  running the script, please follow the instruction in the script
# the capture kit version is forced to use agilent version 5 in the script

perl generateCMDmappingCondor.pl 


##### Step 2: Running variant calling pipeline

for running one sample:

perl /Volumes/data.odin/script/amg/variantcalling/pipeline/pipeline_current/variantCallingPipeline.pl /PATH/TO/sample.conf

(the profileFile.txt is under condor_sh/project/Project_**/Sample_**/data)

or for running several samples linear:

perl /Volumes/data.odin/script/amg/variantcalling/pipeline/pipeline_current/runGroupPipeline.pl /PATH/TO/groupProfile.txt

(the groupProfile.txt is under condor_sh/projects/Project_**/)

##### Step 4: rename the files and remove intermediate files

# need to be run under the folder which contains sample result
  folders, e.g. Project_Diag-excap15-2013-06-07

perl /Volumes/data.odin/script/amg/variantcalling/pipeline/pipeline_current/postProcess.pl runID
