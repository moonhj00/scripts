#!/bin/bash
### input: working directory, <.var.vcf file from samtools > <bam file which generateed the vcf file>
### output: <var.vcf.gatk.vcf> 
##Desp.: GATK annotation
##input: splitted bam file folder; subBam full path

##---setting parameters-
sh /ifs/home/c2b2/ac_lab/jh3283/scripts/projFocus/ceRNA/varcall/global_setting_projFocueCeRNA.sh 
REGIONFILE=/ifs/data/c2b2/ac_lab/jh3283/projFocus/data/02042014/wgs/humanGenome_hg19_regions104.bed
srcDIR=/ifs/home/c2b2/ac_lab/jh3283/scripts/projFocus/ceRNA/varcall
outputDir=/ifs/data/c2b2/ac_lab/jh3283/projFocus/result/02022014/wgsVars/rawVars/
tempDir=$1
subVCF=$2
subBAM=$3
ERR="[ERR:]"
MSG="[MSG:]"
DONE="[DONE:]"
rootd=`pwd`

subBamName=`echo $subBAM|awk 'BEGIN{FS="/"}{print $NF}'`
cnt=`echo $subBamName|awk -F. '{gsub("split_","",$1);print $1} '`
pid=`echo $subBamName|awk 'BEGIN{FS="."}{split($2,a,"-");print a[3]} '`
# echo $cnt
# echo $pid
###-----check dir setting-----
if [ ! -d $tempDir ]; then 
  echo -e $ERR"temp dir not there!" 
  exit
fi
  
if [ ! -d $tempDir/log ]; then 
  echo -e $ERR"log dir not there!" 
  exit
fi

cwd=$tempDir
logDir=$cwd/log

echo -e "calling on \t $subBAM"   
echo -e "current working dir\t $cwd"

###----annotating var.vcf 
cd $cwd
echo "$srcDIR/gatkAnno.sh $subVCF $subBAM" |qsub -N a_${pid}_$cnt -e $logDir -o $logDir -l mem=4G,time=40:: -cwd >>$cwd/qsubAnno.log
tail -1 $cwd/qsubAnno.log

##-----invoke step-4 to integrate VCFs
if [ -f $cwd/Moniter.txt ] ;then
  echo "Moniter file exisit!" 
else
  echo "Moniter var.vcf.gatk.vcf"  > $tempDir/Moniter.txt
  echo "$srcDir/step-4_mergeVCF.sh $tempDir $outputDir" | qsub -l mem=4g,time=140:: -e $logDir/ -o $logDir/ -cwd -N mergeVCF > $tempDir/qsubMerge.log
  cat $tempDir/qsubMerge.log
fi 
