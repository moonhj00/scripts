##status: under work
rm(list=ls())

setRootd  = function(){
  sysInfo = Sys.info()
  if(sysInfo['sysname']=="Darwin" ){
    print("working from MacOS")
    rootd = "/Volumes/ifs/home/c2b2/ac_lab/jh3283/"
  }else if(sysInfo['sysname']=="Linux" ){
    print("working from Linux")
    rootd = "/ifs/home/c2b2/ac_lab/jh3283/"
  }
  return(rootd)
}
rootd     = setRootd()

figd = paste(rootd, "/DATA/projFocus/report/Aug2014/fig",sep="")

source(paste(rootd,"/scripts/projFocus/ceRNA/projFocusCernaFunctions.R",sep=""))
source(paste(rootd,"/scripts/myR/jingGraphic.R",sep=""))


#----getting command line parameters
#--getting arguments
args = getArgs()

if(length(args) < 1 || is.null(args)){
    print(paste(usage,example,sep="\n"))
  print(args)
    stop(paste(error,"wrong input parameter!"))
}

setwd(system("pwd",intern=T))
tgene    = args[['ctar']]
# imputfile = 
nboot	 = as.integer(args[['nboot']])
output   = args[['out']]
###----func-------
formatTestOut = function(test_aov){
  Res.DF_cnv_all = paste(test_aov$Res.Df, collapse="/")
  RSS_cnv_all = paste(round(test_aov$RSS,digits=2),collapse="/")  
  result = c(Res.DF_cnv_all= Res.DF_cnv_all, RSS_cnv_all= RSS_cnv_all, round(unlist(data.frame(test_aov)[2,3:6]),5))
  return(result)
}

orderSampleLable = function(dataExp){
  dataExp$sample <- as.character(dataExp$sample)
  #Then turn it back into an ordered factor
  dataExp$sample <- factor(dataExp$sample, levels=unique(dataExp$sample))
  return(dataExp)
}

noseHeatmap = function(inputfile){
#   inputfile = paste(inputDir, "/input_", tgene, sep="")
  tgene = tail(unlist(strsplit(inputfile,"_")),1)
  data = read.csv2(inputfile, sep="\t", header=T,stringsAsFactors=F)
  data = data[order(as.numeric(as.character(data$cTarExp))),]
  allSmp = data$X; rownames(data) <- allSmp
  data = data[,colSums(data!=0)!=0]
  
  allFeatures = colnames(data)
  data$sample = rownames(data)
  ftr.cRegExp = allFeatures[grep("cRegExp", allFeatures)]
  ftr.cRegCNV = allFeatures[grep("cRegCNV", allFeatures)]
  ftr.cRegTFmut = allFeatures[grep("cRegTFmut", allFeatures)]
  data[,c('cTarExp', ftr.cRegExp, ftr.cRegCNV, ftr.cRegTFmut)] = apply(data[,c('cTarExp', ftr.cRegExp, ftr.cRegCNV, ftr.cRegTFmut)],2,as.numeric)
  
  library(reshape); library(ggplot2) ;library(scales);library(RCurl);  library (grid)
  
  ####---underDevelopment
  
  ### ceRNA target expression
  data.cTarExp = data[,c('sample', 'cTarExp')]
  data.cTarExp$variable = rep("   cTarExp ",NROW(data)); colnames(data.cTarExp) = c("sample", 'value', 'variable')
  data.cTarExp$value <- as.numeric(as.character(data.cTarExp$value))
  data.cTarExp <- orderSampleLable(data.cTarExp)
  data.cTarExp$rescale <- rescale(data.cTarExp$value,to=c(-1,1))
  head(data.cTarExp)
  
  ### ceRNA regulator expression
  data.cRegExp = data[,c('sample', ftr.cRegExp)]
  if (length(ftr.cRegExp) > 1){
    data.cRegExp[, ftr.cRegExp] = apply(data.cRegExp[,ftr.cRegExp],2, function(x){rescale(x,to=c(-1,1))})
  }else if (length(ftr.cRegExp) == 1){
    data.cRegExp[, ftr.cRegExp] = rescale( data.cRegExp[, ftr.cRegExp], to = c(-1,1))
  }else {
    print("no cRegExpression information!")
    return(0)
  }
  data.cRegExp.m <- melt(data.cRegExp, id.vars='sample')
  head(data.cRegExp.m) 
  data.cRegExp.m <- orderSampleLable(data.cRegExp.m)
  head(data.cRegExp.m)

  
  ## ceRNA regulator's CNV 
  data.cRegCNV = data[,c('sample', ftr.cRegCNV)]
  data.cRegCNV = melt(data.cRegCNV, id.vars='sample')
  data.cRegCNV$value <- factor(sign(as.numeric(as.character(data.cRegCNV$value))), levels = c(-1,0,1))
  data.cRegCNV <- orderSampleLable(data.cRegCNV)
  head(data.cRegCNV)
  
  ## ceRNA regulator's TF mutation profile (collapsed)
  data.cRegTFmut  = data[,c('sample',ftr.cRegTFmut)]; data.cRegTFmut[,ftr.cRegTFmut] <- sign(data.cRegTFmut[,ftr.cRegTFmut])
  data.cRegTFmut.m = melt(data.cRegTFmut,id.vars='sample')
  data.cRegTFmut.m$value <- factor(data.cRegTFmut.m$value, levels=c(0,1))
  data.cRegTFmut.m <- orderSampleLable(data.cRegTFmut.m)
  
  head(data.cRegTFmut.m)
  
  ### ploting
    base_size <- 6
    p <- ggplot(data.cTarExp, aes(variable, sample) )+ geom_tile(aes(fill = rescale), color = 'white') 
    p1 <- p + scale_fill_gradient2(low='green',mid='white',high='orange') + 
          theme_grey(base_size = base_size) + theme(axis.title=element_blank(), 
              axis.text.y = element_blank(),
#               axis.text.x = element_blank(),            
              legend.position="none",
#               axis.title.x = element_text(face="bold", colour="#990000", size=16), axis.text.x  = element_text(angle=90, vjust=0.5, size=16),
              axis.title.x = element_text(face="bold", colour="#990000", size=16), axis.text.x  = element_text(angle=90, vjust=0.5, size=16))


    p <- ggplot(data.cRegExp.m, aes(variable, sample)) +   geom_tile(aes(fill = value), color = 'white')
    p2 <- p + scale_fill_gradient2(low='green',mid='white',high='orange') + 
            theme_grey(base_size = base_size) +  theme(axis.title=element_blank(), 
            axis.text.y = element_blank(),
#             axis.text.x = element_blank(), 
            legend.position="none" ,
#             axis.title.x = element_text(face="bold", colour="#990000", size=16),axis.text.x  = element_text(angle=90, vjust=0.5, size=16),
            axis.title.x = element_text(face="bold", colour="#990000", size=6), axis.text.x  = element_text(angle=90, vjust=0.5, size=6))
        
    p <- ggplot(data.cRegCNV, aes(variable, sample)) +   geom_tile(aes(fill = value), color = 'white')
    p3 <- p + scale_fill_manual(values=c("lightblue","white",colors()[119])) +  
#           theme_grey(base_size = base_size) +   
            theme(axis.title=element_blank(), 
                  axis.text.y = element_blank(),
                    legend.position="none", 
#                     axis.title.x = element_text(face="bold", colour="#990000", size=16),axis.text.x  = element_text(angle=90, vjust=0.5, size=16),
            axis.title.x = element_text(face="bold", colour="#990000", size=6), axis.text.x  = element_text(angle=90, vjust=0.5, size=6))
      
    p <- ggplot(data.cRegTFmut.m, aes(variable, sample)) +  geom_tile(aes(fill = value), colour =   "white") 
    p4 <- p + scale_fill_manual(values=c('white',"red")) + 
            theme(axis.title=element_blank(),  
                  axis.text.y = element_blank(), 
                    legend.position="none",
#             axis.title.x = element_text(face="bold", colour="#990000", size=16),axis.text.x  = element_text(angle=90, vjust=0.5, size=16),
            axis.title.x = element_text(face="bold", colour="#990000", size=6), axis.text.x  = element_text(angle=90, vjust=0.5, size=6))
    
     
  len1 = length(unique(data.cTarExp$variable)); len2 = length(unique(data.cRegExp.m$variable)); len3= length(unique(data.cRegCNV$variable)); len4=length(unique(data.cRegTFmut.m$variable)); 
  lensum = len2 + len3 + len4
  pdf(paste(figd,"/heatmap_diagnois_regCerna_Aug17_",tgene, ".pdf",sep=""),width=15,height=18)
  layt<-grid.layout(nrow=1,ncol=4,widths=c(1/20,len2/lensum * 19/20,len3/lensum * 19/20,len4/lensum * 19/20))
  
  layt<-grid.layout(nrow=1,ncol=4,widths=c(1/15,3/10,3/10,3/10))
  
  #   grid.show.layout(layt)
  grid.newpage()
  pushViewport(viewport(layout=layt))
  print(p1,  vp = viewport(layout.pos.row=1,layout.pos.col=1))
  print(p2, vp = viewport(layout.pos.row=1,layout.pos.col=2))
  print(p3, vp = viewport(layout.pos.row=1,layout.pos.col=3))
  print(p4, vp = viewport(layout.pos.row=1,layout.pos.col=4))
  dev.off()

}

svReg = function(inputfile) {
  # tgene = tail(unlist(strsplit(inputfile,"_")),1)
 
  data = read.csv2(inputfile, sep="\t", header=T,stringsAsFactors=F)
  data = data[order(as.numeric(as.character(data$cTarExp))),]
  allSmp = data$X; rownames(data) <- allSmp
  
  ### bootstrapping 
  allSmp = sample(allSmp, replace = T)
  data = data[allSmp, ] 
  
  data = data[,colSums(data!=0)!=0]
  
  allFeatures = colnames(data)
  ftr.cTarExp = allFeatures[grep("cTarExp", allFeatures)]
  ftr.cTarCNV = allFeatures[grep("cTarCNV", allFeatures)]
  ftr.cRegExp = allFeatures[grep("cRegExp", allFeatures)]
  ftr.cRegCNV = allFeatures[grep("cRegCNV", allFeatures)]
  ftr.cRegTFmut = allFeatures[grep("cRegTFmut", allFeatures)]
  
  if (length(ftr.cRegTFmut) == 0 ){
    return(c(tgene, length(ftr.cRegCNV), 0, NROW(data), NA, NA))
  }
  
  data[,c(ftr.cRegTFmut, ftr.cTarCNV, ftr.cRegCNV)] <- sign(apply(data[,c(ftr.cRegTFmut,ftr.cTarCNV, ftr.cRegCNV)],2, as.numeric))
  data[,c(ftr.cTarExp, ftr.cRegExp)] <- apply(data[,c(ftr.cTarExp, ftr.cRegExp)], 2, as.numeric)
  
  data.mod1 = as.matrix(data[,c(ftr.cTarExp, ftr.cTarCNV)])
  data.mod2 = as.matrix(data[,c(ftr.cTarExp, ftr.cTarCNV, ftr.cRegCNV)])
  data.mod3 = as.matrix(data[,c(ftr.cTarExp, ftr.cTarCNV, ftr.cRegCNV, ftr.cRegTFmut)])
  
  require(e1071)
  cost1 = 1; cost2 = 100 ; cost3 = 1000; gamma = 0.001
  mod1 = svm(data.mod1[,ftr.cTarExp] ~ ., data = data.frame(data.mod1), type="eps-regression",  kernel = "polynomial", cost = cost1, gamma = gamma, cross = 10)
  mod2 = svm(data.mod2[,ftr.cTarExp] ~ ., data = data.frame(data.mod2), type="eps-regression",  kernel = "polynomial", cost = cost2, gamma = gamma, cross = 10)
  mod3 = svm(data.mod3[,ftr.cTarExp] ~ ., data = data.frame(data.mod3), type="eps-regression",  kernel = "polynomial", cost = cost3, gamma = gamma, cross = 10)
  
  rss1 = sum(mod1$residuals)^2 ; rss2 = sum(mod2$residuals)^2; rss3 = sum(mod3$residuals)^2; 
  p1 = NCOL(data.mod1) -1 ; p2 = NCOL(data.mod2) -1 ; p3 = NCOL(data.mod3) - 1
  n = length(allSmp)
  
  ##alternative hypo: mod2 is bettern than mod1, rss1 is smaller than rss2
  out = c(tgene, mod1.mse=mod1$tot.MSE, mod1.r2 = mod1$scorrcoeff,
          mod2.mse=mod2$tot.MSE, mod2.r2=mod2$scorrcoeff,
          mod3.mse=mod3$tot.MSE, mod3.r2 = mod3$scorrcoeff,
          rss1=rss1, rss2=rss2, rss3 = rss3,
          cntSelfCNV = p1, cntCregCNV=p2 - p1, cntMut=p3-p2,  cntSmp=n)
  # cat(sprintf("cv.svm> mse, r2 = %5.3f %5.3f\n", mod1$tot.MSE, mod1$scorrcoeff, mod2$tot.MSE, mod2$scorrcoeff))

  return(out)

}

####---test----
# nboot=1000
# tgene = 'EN2'
###----main-------
require(scales)
inputDir = paste(rootd, "/DATA/projFocus/result/07152014/reg/tfCerna/data" , sep="")
# inputfileLst = paste(inputDir, "/", list.files(inputDir), sep="")

# tgene ="MBNL3"
inputfile = paste(inputDir, '/', 'input_', tgene, sep="")
# output  = paste(rootd, "/DATA/projFocus/result/07152014/reg/tfCerna/result/runAug22/result_", sep="")

svReg_dev = function(inputfile){
  data = read.csv2(inputfile, sep="\t", header=T,stringsAsFactors=F)
  data = data[order(as.numeric(as.character(data$cTarExp))),]
  allSmp = data$X; rownames(data) <- allSmp
  
   ### bootstrapping 
  allSmp = sample(allSmp, replace = T)
  data = data[allSmp, ] 
  
  data = data[,colSums(data!=0)!=0]
  
  allFeatures = colnames(data)
  ftr.cTarExp = allFeatures[grep("cTarExp", allFeatures)]
  ftr.cTarCNV = allFeatures[grep("cTarCNV", allFeatures)]
  ftr.cRegExp = allFeatures[grep("cRegExp", allFeatures)]
  ftr.cRegCNV = allFeatures[grep("cRegCNV", allFeatures)]
  ftr.cRegTFmut = allFeatures[grep("cRegTFmut", allFeatures)]
  
  if (length(ftr.cRegTFmut) == 0 ){
    return(c(tgene, length(ftr.cRegCNV), 0, NROW(data), NA, NA))
  }
  
  data[,c(ftr.cRegTFmut, ftr.cTarCNV, ftr.cRegCNV)] <- sign(apply(data[,c(ftr.cRegTFmut,ftr.cTarCNV, ftr.cRegCNV)],2, as.numeric))
  data[,c(ftr.cTarExp, ftr.cRegExp)] <- apply(data[,c(ftr.cTarExp, ftr.cRegExp)], 2, as.numeric)
  
  
  data.mod1 = as.matrix(data[,c(ftr.cTarExp, ftr.cTarCNV)])
  data.mod2 = as.matrix(data[,c(ftr.cTarExp, ftr.cTarCNV, ftr.cRegCNV)])
  data.mod3 = as.matrix(data[,c(ftr.cTarExp, ftr.cTarCNV, ftr.cRegCNV, ftr.cRegTFmut)])
  
  require(e1071)
  cost1 = 1; cost2 = 100 ; cost3 = 1000; gamma = 0.001
  mod1 = svm(data.mod1[,ftr.cTarExp] ~ ., data = data.frame(data.mod1), type="eps-regression",  kernel = "polynomial", cost = cost1, gamma = gamma, cross = 10)
  mod2 = svm(data.mod2[,ftr.cTarExp] ~ ., data = data.frame(data.mod2), type="eps-regression",  kernel = "polynomial", cost = cost2, gamma = gamma, cross = 10)
  mod3 = svm(data.mod3[,ftr.cTarExp] ~ ., data = data.frame(data.mod2), type="eps-regression",  kernel = "polynomial", cost = cost3, gamma = gamma, cross = 10)
  
  rss1 = sum(mod1$residuals)^2 ; rss2 = sum(mod2$residuals)^2; rss3 = sum(mod3$residuals)^2; 
  p1 = NCOL(data.mod1) -1 ; p2 = NCOL(data.mod2) -1 ; p3 = NCOL(data.mod3) - 1
  n = length(unique(allSmp))
  
  ##alternative hypo: mod2 is bettern than mod1, rss1 is smaller than rss2
   out = c(tgene, mod1.mse=mod1$tot.MSE, mod1.r2 = mod1$scorrcoeff,
	  mod2.mse=mod2$tot.MSE, mod2.r2=mod2$scorrcoeff,
	  mod3.mse=mod3$tot.MSE, mod3.r2 = mod3$scorrcoeff,
	  rss1=rss1, rss2=rss2, rss3 = rss3,
	  cntSelfCNV = p1, cntCregCNV=p2 - p1, cntMut=p3-p2,  cntSmp=n)
  # print(out)
  cat(sprintf("cv.svm> mse, r2 = %5.3f %5.3f\n", mod1$tot.MSE, mod1$scorrcoeff, mod2$tot.MSE, mod2$scorrcoeff))
}

print(inputfile)
# resDF = sapply(inputfileLst,svReg)
resDF = sapply(rep(inputfile, nboot), svReg)
resDF = t(resDF)
rownames(resDF)  <- paste(tgene, 1:nboot, sep="_")

write.table(resDF, paste(output, tgene ,sep=""), col.names=F, quote=F, sep="\t" )

