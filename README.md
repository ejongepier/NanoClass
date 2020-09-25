# NanoClass

[![Snakemake](https://img.shields.io/badge/snakemake-≥5.7.4-brightgreen.svg)](https://snakemake.bitbucket.io)

NanoClass is a taxonomic meta-classification tool for 16S/18S amplicon sequencing data generated with the Nanopore MiniION.
With a single command, you can run up to eleven popular classification tools on multiple samples in parallel.
These include BLASTN, Centrifuge, Kraken2, IDTAXA, MAPseq, MegaBLAST, Minimap2, Mothur, QIIME2, RDP and SPINGO.
Optional read preparation steps, such as demultiplexing, adaptor trimming, length filtering and sub-sampling, are an integral part of the pipeline.
In addition to taxonomic barplots, NanoClass computes and vizualizes precision and runtime to compare the performance of each taxonomic classification tool on your data.

NanoClass automatically installs all software packages and dependencies, downloads and builds required taxonomic databases and runs the analysis on your samples.

## Getting started

### Requirements

NanoClass can be run on a powerfull desktop computer. All classification tools implemented in NanoClass will run in a matter of minutes to hours, with the exception of QIIME2.
Prerequisites are [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html), [Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) 
and [Singularity](https://singularity.lbl.gov/). The latter two can be conveniently installed using the included recipe (see NanoClass/envs/README.md).

NanoClass automatically installs all other software packages and dependencies, with the exception of MAPseq as it is not implemented in conda.
To facilitate the use of MAPseq, you can easily build it from included singularity recipe (see NanoClass/containers/README.md). 

### Installation

You can either clone NanoClass, like so:

    git clone https://github.com/ejongepier/NanoClass

Or download and extract the zip archive from https://github.com/ejongepier/NanoClass.

NanoClass is immediately ready for use.

## Usage 

### Quick start

Copy your Nanopore MinION sequencing files to path: NanoClass/data/<runID>/basecalled/<sampleID>.passed.fastq.gz,
where <runID> and <sampleID> are the labels you should provide in the file NanoClass/samples.csv as a comma separated table with runID,sampleID,barcode.

The entire pipeline can then be run with a single command:

    snakemake --use-conda --cores <ncores>

Where `--cores` are the number of CPU cores/jobs that can be run in parallel on your system.

### Customizing

You can opt to customize the pipeline through the config.yaml,
e.g. by running only a subset of the 11 classsification tools or by changing the default Silva 16S taxonomic database.  
For details on how to customize NanoClass, see the Documentation.

### Report

After successful execution, you can create an interactive HTML report with:

    snakemake --report report/NanoClass.zip


## Roadmap

- [x] Implement demultiplexing, adaptor trimming, length filtering and subsampling.
- [x] Implement 11 popular clasification tools in snakemake pipeline.
- [x] Implement analyses of multiple samples in parallel.
- [x] Implement analyses of multiple runs in parallel.
- [x] Implement automatic download and build of all reference databases upon first run of NanoClass.
- [x] Make custom Singularity container for `blastn`, `centrifuge`, `kraken2`, `idtaxa`, `mapseq` ,`megablast` , `minimap2`, `rdp` and `spingo`
- [x] Implement Singularity using docker hub for `mothur` and `qiime2`.
- [x] Implement schema's to check validity of user input data before running pipeline.
- [x] Write tomat: a tool that converts the various type's of outputs to taxonomy and "OTU/ASV"-style tables.
- [x] Implement taxonomic barplot to compare across tools and samples.
- [x] Write toconsensus: a tool that assigns consensus and majority classifications, based on the combined results of the individual tools.
- [x] Implement precision plots for all samples, methods and taxonomic levels
- [x] Implement runtim plots per method and sample.
- [x] Assess small subsample representativeness.
- [x] Implement archiving of analyses for pubication of data + pipeline on e.g. Zenodo
- [x] Implement reporting including workflow, stats, config, and results.
- [x] Initiate git version control
- [x] Write README.md
- [x] Push to git
- [x] Remove redundance / increase consistency of db use.
- [x] Compartmentalize environments / containers
- [x] Replace non-conda programs in singularity container
- [ ] Implement optional comparison to known composition of samples from mock communities.
- [ ] Benchmark, optimize resource allocation
- [ ] Write documentation and import in read the docs.
- [ ] Implement use of alternative db such as 18S, ITS, NCBI COI, ...


## Advanced

The following recipe provides established best practices for running and extending this workflow in a reproducible way.

1. [Fork](https://help.github.com/en/articles/fork-a-repo) the repo to a personal or lab account.
2. [Clone](https://help.github.com/en/articles/cloning-a-repository) the fork to the desired working directory for the concrete project/run on your machine.
3. [Create a new branch](https://git-scm.com/docs/gittutorial#_managing_branches) (the project-branch) within the clone and switch to it. The branch will contain any project-specific modifications (e.g. to conf$
4. Modify the config, and any necessary sheets (and probably the workflow) as needed.
5. Commit any changes and push the project-branch to your fork on github.
6. Run the analysis.
7. Optional: Merge back any valuable and generalizable changes to the [upstream repo](https://github.com/snakemake-workflows/qiime2-caulerpa-test) via a [**pull request**](https://help.github.com/en/articles/cr$
8. Optional: Push results (plots/tables) to the remote branch on your fork.
9. Optional: Create a self-contained workflow archive for publication along with the paper (snakemake --archive).
10. Optional: Delete the local clone/workdir to free space.


<!-- ## Testing

Tests cases are in the subfolder `.test`. They are automtically executed via continuous integration with Travis CI. -->

## Authors

* Evelien Jongepier (e.jongepier@uva.nl)


