#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(ggplot2))

args = commandArgs(trailingOnly=TRUE)

dl = list()
for (i in 1:length(args)){
  # Get metadata
  lab = strsplit(args[i], "/")[[1]][2]
  run = strsplit(lab, "[_]")[[1]][3]
  sample = strsplit(strsplit(lab, "[_]")[[1]][4], "[.]")[[1]][1]
  method = strsplit(lab, "[_]")[[1]][1]
  # Read data
  dt <- as.data.frame(read.table(args[i], header = T, sep = '\t', 
                    comment = "")[,1])
  # Add meta data columns
  dt$run <- rep(run, nrow(dt))
  dt$sample <- rep(sample, nrow(dt))
  dt$method <- rep(method, nrow(dt))
  # Add to list
  dl[[i]] <- dt
}

df <- do.call(rbind, dl)
names(df)[1] <- "s"

theme_set(theme_bw())

p = ggplot(df, aes(x = method, y = s, fill=method)) +
    geom_bar(stat="identity", color="black") +
    labs(x = "", y = "Runtime (s)") +
    theme(axis.text.x = element_text(
        angle = 90, vjust = 0.5, hjust=1))
p = p + facet_grid(paste0("Run: ",run) ~
                   paste0("Sample: ",sample))
p = p + theme(legend.position="none")
ggsave("plots/runtime.pdf", plot=p, device="pdf")

q = ggplot(df, aes(x = method, y = s, fill=method)) +
    geom_bar(stat="identity", color="black") +
    scale_y_continuous(trans = "log10") +
    labs(x = "", y = "Runtime (s)") +
    theme(axis.text.x = element_text(
        angle = 90, vjust = 0.5, hjust=1))
q = q + facet_grid(paste0("Run: ",run) ~
                   paste0("Sample: ",sample))
q = q + theme(legend.position="none")
ggsave("plots/runtime_log.pdf", plot=q, device="pdf")

