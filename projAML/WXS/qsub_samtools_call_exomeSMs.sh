#!/bin/bash
#By: J.He
#TODO: 
#input: <file: full path of two bam files>
#output:<file: var.vcf file for each lines of input file>

wd=`pwd`
if [[ ! -d $wd ]]
then
  mkdir $wd/log
fi
logd=$wd/log
echo `date` >> $logd/qsub.log
echo "working director:"$wd >>$logd/qsub.log
echo "log director:"$logd >>$logd/qsub.log
while read line
do
  bam1=`echo $line|awk '{print $1}'`
  bam2=`echo $line|awk '{print $2}'`
  jname1=`echo $bam1|awk 'BEGIN{FS="/"}{split($NF,a,".");print a[1]}'` 
  jname2=`echo $bam2|awk 'BEGIN{FS="/"}{split($NF,a,".");print a[1]}'` 
  echo "/ifs/home/c2b2/ac_lab/jh3283/scripts/projAML/WXS/samtools_call_exomeSMs_update.sh $bam1 $bam2" |qsub -l mem=8g,time=24:: -N do_${jname1}"_"${jname2} -e ${logd} -o ${logd} -cwd >> $logd/qsub.log
  tail -1 $logd/qsub.log
done < $1
echo `date` >> $logd/qsub.log



