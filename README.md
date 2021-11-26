# NanoClass

[![Snakemake](https://img.shields.io/badge/snakemake-≥5.7.4-brightgreen.svg)](https://snakemake.bitbucket.io)

NanoClass is a taxonomic meta-classifier for 16S/18S amplicon sequencing data generated with the Oxford Nanopore MinION.
With a single command, you can run ten popular classification tools on multiple samples in parallel, including BLASTN, Centrifuge, Kraken2, IDTAXA, MegaBLAST, dcMegaBLAST, Minimap2, Mothur, QIIME2, RDP and SPINGO.
Optional read preparation steps, such as quality trimming, length filtering and sub-sampling, are an integral part of the pipeline.

NanoClass automatically installs all software packages and dependencies, downloads and builds required taxonomic databases and runs the analysis on your samples.

## Getting started

### Requirements

The entire NanoClass workflow can be run on a powerfull desktop computer, but for many applications a laptop will do. 
Most classification tools implemented in NanoClass run in a matter of minutes to hours. 
Prerequisites are [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html) 
and [Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html). 

NanoClass automatically installs all other software packages and dependencies.

### Installation

You can either clone NanoClass, like so:

    git clone https://github.com/ejongepier/NanoClass.git

Or download and extract the zip archive from https://github.com/ejongepier/NanoClass.

NanoClass is immediately ready for use.
See also the [Documentation](see https://ejongepier.github.io/NanoClass).

## Usage 

### Quick start

Enter your samples and the paths to your fastq.gz files in the sample.csv. 
Sample labels should be unique. Both sample and run labels should contain letters and numbers only.
Barcode column should be left empty, meaning your input files should already be demultiplexed.
For an example see the sample.csv file.

After editing the samples.csv, the entire pipeline can be run with a single command:

    snakemake --use-conda --cores <ncores>

Where `--cores` are the number of CPU cores/jobs that can be run in parallel on your system.

### Customizing

You can customize the pipeline through the config.yaml,
e.g. by running only a subset of the reads or classification tools, or by changing the default Silva 16S taxonomic database.  
For details on how to customize NanoClass, see the [Documentation](https://ejongepier.github.io/NanoClass).

### Report

After successful execution, you can create an interactive HTML report with:

    snakemake --report report/NanoClass.zip


## Authors

* Evelien Jongepier (e.jongepier@uva.nl)


