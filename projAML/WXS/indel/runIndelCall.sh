#!/bin/bash
#By: J.He
#TODO: 

CWD=/ifs/home/c2b2/ac_lab/jh3283/SCRATCH/projAML/WXS/indel
##--making bamlist files--------------------------------------------
###----------------make--input-list-file--end--------------------------

#-------function-to-submit---bam-file-list---------
qsubRun (){
  ##----input: bam file list with full path
  cnt=0
  while read line
  do
    let cnt=$cnt+1
    jobid=`echo $line|awk 'BEGIN{FS="/"}{split($13,a,"-");print a[3]"-"a[4]}'`"_$cnt"
    # echo $jobid
    echo "/ifs/home/c2b2/ac_lab/jh3283/scripts/projFocus/ceRNA/indelCall_v5.sh $outDir $line"|qsub -l mem=8g,time=160:: -N $jobid -cwd -o ./log -e ./log >>qsub.log
     tail -1 qsub.log
  done <$1
}

delBam() {
  bamlist=$1
  cnt=0
  for line in `ls *VCF.filtered.VCF`
  do
    bam=`echo $line|awk 'BEGIN{FS="_"}{print $1}'`
    pathBam=`grep $bam $bamlist`
    if [[ ! -z $pathBam ]]; then
      echo "deleting $pathBam"
      rm $pathBam 
      rm $pathBam.bai
      let cnt=$cnt+1
    fi
  done 

  echo -e "$cnt bam file deleted"
  echo "#----DONE----"
}

getInput(){
  pidlist=$1
  echo -n "" >$pidlist.inputBamlist
  while read pid
  do
    tempBamArray=( `ls ${dataDir}/${pid}*.bam ` )
    for i in ${tempBamArray[@]}
    do
      readlink -f $i >> $pidlist.inputBamlist
    done
  done < $pidlist
}

batchQsubRun(){
  for i in `seq 1 8`
  do
    qsubRun pid.txt.inputBamlist_$i 
    sleep 48hs 
  done
}


###-------function----end--------

#----data folder:
dataDir=/ifs/scratch/c2b2/ac_lab/jh3283/projAML/WXS/callVars/
outDir=$(pwd)
# getInput $CWD/pid.txt
# ~/bin/splitByN $CWD/pid.txt.inputBamlist 6
# qsubRun pid.txt.inputBamlist_2
qsubRun pid.txt.inputBamlist_3
qsubRun pid.txt.inputBamlist_4

###---------run-----using--input---file---list

# qsubRun input_indelCall_run1.txt_part1
# qsubRun input_indelCall_run1.txt_part2 
##------g

# touch input.bam.list.brca_wxsInwgsNotDone.bam.tumor_02022014.txt
# for inputlist in input.bam.list.4 input.bam.list.5 input.bam.list.6
# do
#   grep -f ../../data/sampleInfo/brca_wgs_bam_summary_02042014.tsv_TumorSample $inputlist >> input.bam.list.brca_wxsInwgsNotDone.bam.tumor_02022014.txt
# done 
