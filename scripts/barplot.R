#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(phyloseq))
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(vroom))
suppressPackageStartupMessages(library(tidyr))


args = commandArgs(trailingOnly=TRUE)

taxmat <- as.data.frame(unique(vroom(args)))
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
rownames(otumat) <- otumat$taxid
otumat$taxid <- NULL
otumat <- as.matrix(otumat)
rownames(sam) <- colnames(otumat)

OTU = otu_table(otumat, taxa_are_rows = TRUE)
TAX = tax_table(taxmat)
SAM = sample_data(sam)

physeq = phyloseq(OTU, TAX, SAM)
#physeqr = transform_sample_counts(physeq, function(x) x / sum(x))

#physeqrF = filter_taxa(physeqr, function(x) mean(x) < .01,TRUE)
#rmtaxa = taxa_names(physeqrF)
#alltaxa = taxa_names(physeq)

#myTaxa = alltaxa[!alltaxa %in% rmtaxa]

#physeqaF <- prune_taxa(myTaxa,physeq)

TopNOTUs <- names(sort(taxa_sums(physeq), TRUE)[1:20])
ent10   <- prune_taxa(TopNOTUs, physeq)

theme_set(theme_bw())

for (level in colnames(taxmat)){
    p = plot_bar(ent10, x="method", fill=level, 
        facet_grid=paste0("Run: ", run) ~ 
                   paste0("Sample: ", sample))
    p = p + labs(x = "Method")
    ggsave(paste0("plots/", level, ".pdf"), plot=p, device="pdf")
}
