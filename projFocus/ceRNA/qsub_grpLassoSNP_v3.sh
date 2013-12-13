#!/bin/bash
#By: J.He
#TODO: using parameters to get command line arguments 
#input: <1. full path of snp.mat file>
#	<2. full path of exp.mat file>
#	<3. full path of cnv.mat file>
#output: <1. regression file>
#	 <2. if 1, plot pdf file>
#Desp.: compared to v1,this version use grpLassoSNP_v3_cnv.r as core code

expFile=$1
snpFile=$2
cnvFile=$3
#geneNumber=$4
cwd=`pwd`
if [ ! -d log ]; then mkdir log ; fi 
if [ ! -d temp ]; then mkdir temp ; fi 

echo -e "working directory:\t"$cwd
echo -e "expression file:\t"$expFile 
echo -e "snp file:\t"$snpFile 
echo -e "cnv file:\t"$cnvFile
echo -e "current working directory:\t"$cwd
echo -e "log directory:\t"$cwd"/log"
echo -e "temp directory:\t"$cwd"/temp"
logdir=$cwd"/log"
tempdir=$cwd"/temp"

##------------get all genes in exp.mat file
echo "getting gene list....."

#sort the expression mat 
#/ifs/scratch/c2b2/ac_lab/jh3283/projFocus/ceRNA/result/exp/brca_exp_l3_731_DEG.mat.singleTSS.anno|(read -r; printf "%s\n" "$REPLY"; sort -k 2 -n )
chr=`echo $snpFile | awk 'BEGIN{FS="/"}{split($NF,a,"_");gsub(/chr/,"",a[4]);print a[4]}'`
genelistFile=$tempdir"/geneList_chr"$chr".temp"

if [ ! -f ${genelistFile} ]; then  
  awk -v chr=$chr '$2==chr{print $1}' ${expFile}|sort|uniq > ${genelistFile} 
fi
numGene=`awk 'END{print NR}' ${genelistFile}` 

echo -e "Number of genes:\t"$numGene
echo -e "chromosome:\t"$chr
echo -e "genelist file:\t"$genelistFile
echo -e "Total number of genes in chr: "$chr"\tis\t"$numGene
##----------------qsub one job for each gene
script="/ifs/home/c2b2/ac_lab/jh3283/scripts/projFocus/ceRNA/grpLassoSNP_v3_cnv.r" 
Rscript="/ifs/home/c2b2/ac_lab/jh3283/tools/R/R-3-02/bin/Rscript"
cntGene=0

#for gene in `head -5 ${genelistFile}` 
for gene in `cat ${genelistFile}` 
do
  let "cntGene++"
  echo -e "processing gene:\t"$cntGene
  ##prepare input files
  genesnpFile=$tempdir"/input_snp_"${gene} 
  geneexpFile=$tempdir"/input_exp_"${gene} 
  genecnvFile=$tempdir"/input_cnv_"${gene} 

  awk -v gene=$gene 'NR==1||$1==gene{print $0}' ${expFile}  > $geneexpFile 
  awk -v gene=$gene 'NR==1||$1==gene{print $0}' ${cnvFile}  > $genecnvFile 
  awk -v gene=$gene 'NR==1||$1==gene{print $0}' ${snpFile}  > $genesnpFile 

  cmd="${Rscript} ${script} ${genesnpFile} ${geneexpFile} ${genecnvFile} 0" 
  #echo $cmd
  echo $cmd |qsub -l mem=4g,time=8:: -N "cnv_chr"${chr}_${gene} -e ${logdir} -o ${logdir} -cwd >> ${logdir}"/qsub_log"
  #$cmd
  tail -1 ${cwd}/log/qsub_log 
done

echo -e "job submitted:\t"$cntGene
echo "#---------END-------"
