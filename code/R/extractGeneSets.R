#### Function to extract gene sets from ENRICHR  source files ####
## It is assumed your working directory is where this file

### Clear R console screen output
cat("\014") 

## Load required libraries
library(CovariateAnalysis)
library(data.table)
library(tidyr)
library(plyr)
library(dplyr)
library(stringr)

library(synapseClient)
library(knitr)
library(githubr)

library(parallel)
library(doParallel)
library(foreach)

cl = makeCluster(detectCores() - 2)
registerDoParallel(cl)

synapseLogin()

#### Synapse specific parameters ####
parentId = 'syn5570248';
activityName = 'Extract Genesets';
activityDescription = 'Extract genesets from enrichr';

# Github link
thisRepo <- getRepo(repository = "blogsdon/Brain_Reg_Net", ref="branch", refName='geneSetCuration')
thisFile <- getPermlink(repository = thisRepo, repositoryPath='code/R/extractGeneSets.R')

#### Query Synapse for source files ####
all.files = synQuery('select id,name from file where parentId == "syn4598359"')

GeneSets = plyr::dlply(all.files, .(file.id), .fun = function(y){
  print(paste('Started',y$file.name))
  tmp = readLines(synGet(y$file.id)@filePath)
  
  internal <- function(x){
      tmp2 = strsplit(x,'\t')[[1]]
      tmp3 = tmp2[-c(1:2)]
      set1 = list()
      set1$genes <- tmp3
      set1$name <- tmp2[1]
      return(set1)
  }
  tmp1 = lapply(tmp,internal)
  tmp2 = lapply(tmp1,function(x) x$genes)
  tmp3 = lapply(tmp1,function(x) x$name)
  names(tmp2) <- tmp3
  print(paste('Completed',y$file.name))
  return(tmp2)
}, .progress = 'text')
names(GeneSets) = gsub('.txt','',all.files$file.name)
save(list = 'GeneSets', file = 'allEnrichrGeneSets.RData')
stopCluster(cl)

#### Store in synapse ####
obj = File('allEnrichrGeneSets.RData', name = 'Gene Sets in RList Format ', parentId = 'syn4867780')
obj = synStore(obj, used = all.files$file.id, activityName = activityName, 
               executed = thisFile, activityDescription = activityDescription)