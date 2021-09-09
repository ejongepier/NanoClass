#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(phyloseq))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(vroom))
suppressPackageStartupMessages(library(tidyr))

args = commandArgs(trailingOnly=TRUE)

taxmat <- as.data.frame(unique(vroom(delim = '\t', args)))
taxmat <- taxmat[!is.na(taxmat$Domain),]

taxmat <- unique(taxmat)
names(taxmat)[1] <- "taxid"

rownames(taxmat) <- taxmat$taxid
taxmat$taxid <- NULL
taxmat <- as.matrix(taxmat)

file <- gsub(".taxmat$", ".otumat", args)
sam <- data.frame(run = rep(NA, length(file)), sample = rep(NA, length(file)), method = rep(NA, length(file)))

for (i in 1:length(file)){
  otumatje <- read.table(file[i], header = T, sep = '\t', comment = "")
  names(otumatje)[1] <- "taxid"
  ifelse (i == 1, otumat <- otumatje, otumat <- merge(otumat, otumatje, all=TRUE))

  lab = strsplit(file[i], "/")[[1]][4]
  sam$run[i] = strsplit(file[i], "/")[[1]][2]
  sam$sample[i] = strsplit(lab, "[.]")[[1]][1]
  sam$method[i] = strsplit(lab, "[.]")[[1]][2]
} 

otumat[is.na(otumat)] <- 0

## for some custom DB like BOLD local copy, the same taxonomic lineage may occur 2x.
## This causes an error when they are used as rownames, which should be unique --> fix: aggregate
otumat <- aggregate(otumat[2:length(otumat)], by=list(otumat$taxid), sum)
rownames(otumat) <- otumat$Group.1
otumat$Group.1 <- NULL
otumat <- as.matrix(otumat)
rownames(sam) <- colnames(otumat)

OTU = otu_table(otumat, taxa_are_rows = TRUE)
TAX = tax_table(taxmat)
SAM = sample_data(sam)

physeq = phyloseq(OTU, TAX, SAM)
pphyseq  = transform_sample_counts(physeq, function(x) x / sum(x) )

theme_set(theme_bw())


for (level in colnames(taxmat)){
    top.taxa <- tax_glom(physeq, level)
    TopNOTUs <- names(sort(taxa_sums(top.taxa), TRUE)[1:20])
    ent10   <- prune_taxa(TopNOTUs, top.taxa)

    p1 = plot_bar(ent10, x="method", fill=level,
        facet_grid=paste0("Run: ", run) ~
                   paste0("", sample))
    p1 = p1 + labs(x = "Method", y = "Absolute abundance")
    ggsave(paste0("plots/aabund-", level, "-by-sample.pdf"), plot=p1, device="pdf")

    p2 = plot_bar(ent10, x="sample", fill=level,
        facet_grid=paste0("Run: ", run) ~
                   paste0("", method))
    p2 = p2 + labs(x = "Sample", y = "Absolute abundance")
    ggsave(paste0("plots/aabund-", level, "-by-method.pdf"), plot=p2, device="pdf")
}


for (level in colnames(taxmat)){
    top.taxa <- tax_glom(pphyseq, level)
    TopNOTUs <- names(sort(taxa_sums(top.taxa), TRUE)[1:20])
    ent10   <- prune_taxa(TopNOTUs, top.taxa)

    q1 = plot_bar(ent10, x="method", fill=level,
        facet_grid=paste0("Run: ", run) ~
                   paste0("", sample))
    q1 = q1 + labs(x = "Method", y = "Relative abundance")
    ggsave(paste0("plots/rabund-", level, "-by-sample.pdf"), plot=q1, device="pdf")

    q2 = plot_bar(ent10, x="sample", fill=level,
        facet_grid=paste0("Run: ", run) ~
                   paste0("", method))
    q2 = q2 + labs(x = "Sample", y = "Relative abundance")
    ggsave(paste0("plots/rabund-", level, "-by-method.pdf"), plot=q2, device="pdf")
}
