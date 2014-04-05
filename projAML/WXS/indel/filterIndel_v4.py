#!/usr/bin/python
#J.HE
#Desp.: given the first filtered , snpeff annotated vcf, furthere filtering
#input: given three vcf files for one patients, normal, tumor, relpase, and gene
# annotation file(tss, tse), return indels 1. pass maf filterint, 2. not germline.
# 3. occured in transcription region.

from generalUtils import *
import sys,getopt
import re
from collections import defaultdict, Iterable

argv = sys.argv[1:]
input = ''
output = ''
usage = 'python " + sys.argv[0] + " -i <input>  -o <output>'
example = 'python " + sys.argv[0] + " -i <input>  -o <output>'
try:
    opts,args = getopt.getopt(argv,"hn:t:r:a:o:",["ifile=","ofile="])
except getopt.GetoptError:
    print usage + "\n" + example 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usage + "\n" + example 
        sys.exit()
    elif opt in ("-n","--normal"):
        nf = arg
    elif opt in ("-t","--tumor"):
        tf = arg
    elif opt in ("-r","--relapse"):
        rf = arg
    elif opt in ("-a","--ganno"):
        ganno = arg
    elif opt in ("-o","--ofile"):
        output = arg
        outputCount = output + ".countIntersection"
print('Script path:\t'+ sys.argv[0])
print('Input file:\t' +nf + "\t" + tf + "\t" + rf)
print('Output file:\t'+ output)

## load gene annotation
gAnno = defaultdict(list)
with open(ganno) as f:
    line = f.readline()
    while line:
        if not re.findall("gene|barcode",line):
            gene, chrom, tss, tse, strand = line.strip().split("\t")
            gObj = GeneCoord(gene,chrom,tss)
            gObj.tse = tse
            gObj.strand = strand 
            gAnno[chrom].append(gObj)
        line = f.readline()

def sortTss(list):
    if len(list) > 1:
        list = sorted(list, key=lambda x:x.tss)
    return list

for chr, gObj in  gAnno.items():
    gAnno[chr] = sorted(gAnno[chr], key = lambda x: x.tss)

print reduce(lambda x,y: x + y, [len(v) for v in gAnno.values()])

def annoMut(mut,gAnnolist):
    out = []
    findflag = 0 
    # if g.chr != gAnnolist[0].chr:
    for g in gAnnolist:
        if g.chr != mut.chr:
            break
        if  mut.ps >= g.tss and mut.pe <= g.tse:
            out.append(g.name)
            findflag = 1 
        elif mut.ps > g.tss and mut.pe > g.tse:
            break
        else:
            continue
    if findflag == 1:
        return(";".join(list(set(out))))
    else:
        return out 
def info2dict(x):
    out = {}
    xx = x.split(";")
    for xxx in xx :
       temp = xxx.split("=")
       out.update({temp[0]:temp[1]})
    return out

dataBychr = defaultdict(list)
def getMut(filename, geneAnno):
    data = defaultdict(list)
    cnt = 0 
    cntk = 0
    with open(filename) as f:
        line = f.readline()
        while line:
            if re.findall("^#|CHROM",line):
                pass
            else :
                flag = 1 
                # CHROM   POS     ID      REF     ALT     QUAL    FILTER SNPEFF_GENE_NAME        SNPEFF_FUNCTIONAL_CLASS SNPEFF_EFFECT SNPEFF_IMPACT   SNPEFF_AMINO_ACID_CHANGE        SNPEFF_EXON
                # 1       17496   .       AC      A       84.0    PASS    WASH7P .       SPLICE_SITE_DONOR       HIGH    .       5       .  DP=23;NF=3;NR=3;NRS=7;NFS=13;HP=5;EFF=DOWNSTREAM(MO
                tempChrom, tempPos, _, tempref,tempalt, _, _, tGene, \
                tFunc, tEff, tImpt, _, _,_, tempInfo, format, sample \
                        = line.strip().split("\t")
                tempMut = Mutation(tempChrom,tempPos) 
                infos = info2dict(tempInfo) 
                try: 
                    dp = int( infos['DP'] )
                    alt = int(infos['NF']) + int( infos['NR'])
                    maf = round(float(alt) / dp, 4)

                    ##----filter maf and dp
                    if len(tempref) > 15 or len(tempalt) > 15:
                        flag = 0
                    if dp >= 100 and maf < 0.02:
                        flag = 0
                        print "dp :\t" + dp  + " fiailed"
                    if dp < 100 and dp > 20 and alt < 2:
                        flag = 0
                        print "dp :\t" + dp  + " fiailed"
                    if dp <= 20:
                        flag = 0
                        print "dp :\t" + dp  + " fiailed"
                except TypeError:
                    pass
                ##----filter tss-tse
                if tEff == "INTERGENIC" or tEff == "INTRON":
                    flag = 0
                if flag == 1:
                    tempMut.gene = tGene
                    tempMut.maf = maf
                    tempMut.dp = dp
                    tempMut.alt = alt
                    tempMut.eff = tEff 
                    tempMut.func = tFunc 
                    tempMut.imp = tImpt
                    cntk = cntk + 1 
                    data[tempChrom].append(tempMut) 
                else:
                    pass
            cnt = cnt + 1
            line = f.readline()
    print "mutations kept:\t" , cntk
    return data

tumor   = getMut(tf, gAnno)
normal  = getMut(nf, gAnno)
relapse = getMut(rf, gAnno)
allDict = {}

# cntN = 0
for key, mutList in normal.items(): 
    for mut in mutList:
        # cntN = cntN + 1
        allDict[(mut.chr,mut.ps)] = 1
print len(allDict)

# cntT = 0 
for key, mutList in tumor.items() :
    for mut in mutList:
        # cntT = cntT + 1 
        if allDict.get((mut.chr,mut.ps),0):
            allDict[(mut.chr,mut.ps)] = allDict[(mut.chr,mut.ps)] + 2
        else:
            allDict[(mut.chr,mut.ps)] = 2
# cntR = 0 
for key, mutList in relapse.items() :
    # cntR = cntR + 1
    for mut in mutList:
        if allDict.get((mut.chr,mut.ps),0):
            allDict[(mut.chr,mut.ps)] = allDict[(mut.chr,mut.ps)] + 4
        else:
            allDict[(mut.chr,mut.ps)] = 4

cnt1 = 0; cnt2 = 0; cnt3 = 0; 
cnt4 = 0; cnt5 = 0; cnt6 = 0; 
cnt7 = 0; 
outputH = open(output + ".relapse",'w') 
outputCountH = open(outputCount, 'w')

for k, v in allDict.items():
    if v == 1:
        cnt1 = cnt1 + 1
    elif v == 2:
        cnt2 = cnt2 + 1
    elif v == 3:
        cnt3 = cnt3 + 1
    elif v == 4:
        cnt4 = cnt4 + 1
        try:
            mut = [m for m in relapse[k[0]] if (m.chr, m.ps) == k]
            mut = mut[0]
            outRec = "\t".join(map(str, list(k) + [mut.gene, mut.dp, mut.alt, mut.maf, mut.func, mut.eff, mut.imp ])) 
            outputH.write(outRec + "\n")
        except IndexError:
            print k, v 
    elif v == 5:
        cnt5 = cnt5 + 1
    elif v == 6:
        cnt6 = cnt6 + 1
    elif v == 7:
        cnt7 = cnt7 + 1
    else:
        pass

outputCountH.write("\t".join(["category", "normTotal", "tumTotal", \
                              "relapseTotal", "norm_tum", "norm_relapse", \
                              "tum_relapse", "tum_relapse", "norm_only", \
                              "tumor_only", "relaspe_only"]) + "\n")  
outputCountH.write("mutationNum\t" + "\t".join(map(str,[cnt1+cnt3+cnt5+cnt7, cnt2+cnt3+cnt6+cnt7,\
                                      cnt4+cnt5+cnt6+cnt7, cnt3+cnt7, cnt5+cnt7, \
                                      cnt6+cnt7, cnt1, cnt2, cnt4])) + "\n") 

outputCountH.close()
outputH.close()