#!/usr/bin/env Rscript

rm(list=ls())

suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(seqinr))

args = commandArgs(trailingOnly=TRUE)
threads = as.numeric(args[4])

query <- read.fasta(args[2], as.string = T, forceDNAtolower = F, set.attributes = F)

set.seed(100)
taxann <- assignTaxonomy(seqs =  unlist(query), refFasta = args[1], tryRC = T, outputBootstraps=F, minBoot=0, multithread = threads, verbose = T)

# remove lengthy seqs from row names
queryid <- names(strsplit(rownames(taxann), " "))
taxodf <- as.data.frame(taxann)
names(taxodf)[1] <- "Domain"
taxodf$"#readid" <- queryid
write.table(taxodf[,c(7,1:6)], file = args[3], row.names=F, col.names=T, quote=F, sep='\t')
