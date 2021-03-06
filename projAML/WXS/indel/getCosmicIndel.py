#!/usr/bin/python
#J.HE
## only look at positiion, not pattern

import sys,getopt
import generalUtils as gu
import re
from collections import defaultdict

argv = sys.argv[1:]
input = ''
output = ''
usage = 'python " + sys.argv[0] + " -i <input>  -o <output>'
example = 'python " + sys.argv[0] + " -i <input>  -o <output>'
try:
    opts,args = getopt.getopt(argv,"hi:c:o:")
except getopt.GetoptError:
    print usage + "\n" + example 
    sys.exit(2)
for opt, arg in opts:
    if opt == '-h':
        print usage + "\n" + example 
        sys.exit()
    elif opt in ("-i"):
        input = arg
    elif opt in ("-c"):
        cosmic = arg
    elif opt in ("-o"):
        output = arg
print('Script path:\t"'+ sys.argv[0])
print('Input file:\t' + input)
print('cosmic file:\t' + cosmic)
print('Output file:\t'+ output)

cnt = 0
with(open(cosmic)) as f:
    line = f.readline()
    cosmicDict = defaultdict(list)
    while line:
        if not re.match("^Mutation", line):
            tchrom, tps, tpe, tgene, ttype = line.strip().split("\t",4)
            tmut = gu.Mutation(tchrom, tps)
            tmut.pe = int(tpe)
            tmut.gene = tgene 
            try :
                tidx = re.search(r'ins|del|A|T|G|C|>',ttype)
                if tidx:
                    tidx = tidx.start()
                    tmut.type = ttype[tidx:]
            except AttributeError:
                continue 
            cosmicDict[tchrom].append(tmut) 
            cnt = cnt + 1
        line = f.readline()
print "cosmic mutation number\t", cnt 
outputH = open(output,'w')

cnt = 0
cntk = 0
with(open(input)) as f:
    line = f.readline()
    while line:
        if not re.match("^#",line):
            tchr, tps, _, _, _, _, _, _, _,=\
                    line.strip().split("\t")
            crtmut = gu.Mutation(tchr, tps)
            if  [x for x in cosmicDict[tchr] if x.ps == crtmut.ps ]:
                outputH.write(line)
                cntk = cntk + 1
            else:
                pass
        elif re.match("^#CHROM",line):
            outputH.write(line)
        else:
            pass
        cnt = cnt + 1
        line = f.readline()
print  "total mutation\t" + str(cnt) 
print  "cosmic mutation\t" + str(cntk) 

outputH.close()
