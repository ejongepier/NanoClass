################################
Parameter reference
################################

The config yaml
********************************

Parameter setting can be customized using the `config.yaml`.
Parameters that are commonly altered are listed in the `config.yaml` in the NanoClass directory, which looks like this:

.. code-block:: bash

   samples:                           "samples.csv"
   methods:                           ["blastn","centrifuge","dcmegablast","idtaxa","kraken","megablast","minimap","mothur","qiime","rdp","spingo"]

   porechop:
       checkreads:                    20000 

   nanofilt:
       minlen:                        1400
       maxlen:                        1600
       quality:                       10

   subsample:
       skip:                          false
       samplesize:                    100

   common:
       dburl:                         "https://www.arb-silva.de/fileadmin/silva_databases/qiime/Silva_132_release.zip"
       ssu:                           "16S" #16S or 18S
       group-by:                      sample

   blastn:
       lcaconsensus:                  0.5
       evalue:                        0.00001
       pctidentity:                   80
       alnlength:                     100
       ntargetseqs:                   50

   dcmegablast:
       lcaconsensus:                  0.5
       evalue:                        0.00001
       pctidentity:                   80
       alnlength:                     100
       ntargetseqs:                   50

   centrifuge:
       taxmapurl:                     "https://www.arb-silva.de/fileadmin/silva_databases/release_132/Exports/taxonomy/taxmap_embl_ssu_ref_nr99_132.txt.gz"
       sequrl:                        "https://www.arb-silva.de/fileadmin/silva_databases/release_132/Exports/SILVA_132_SSURef_Nr99_tax_silva.fasta.gz"

   idtaxa:
       pctthreshold:                  60

   kraken:
       dbtype:                        "silva"

   megablast:
       lcaconsensus:                  0.5
       evalue:                        0.00001
       pctidentity:                   80
       alnlength:                     100
       ntargetseqs:                   50

   minimap:
       lcaconsensus:                  0.5
       ntargetseqs:                   10


The indentation in the config.yaml is important. Note that tabs are not allowed, only spaces.

Here is a description of all tunable parameters, including more advanced usage:

All parameters in NanoClass
*********************************


*samples* [string] (default: samples.csv)
    Comma separated file with run label, sample label and path to input file in fastq.gz format.
    File should be stored in the NanoClass directory.
    Each sample should have a unique sample id.
    If there are multiple fastq.gz files per sample they should first be concatenated and added as a single line in the sample.csv.
    All samples analyzed together should have the same run ID.
    Sample names can differ from fastq.gz file names.
    Only numbers and letters are allowed for sample and run labels.
    The barcode column should be left empty as NanClass can only take demultiplexed input data.

*methods* [array] (default: ["blastn","centrifuge","dcmegablast","idtaxa","kraken","mapseq","megablast","minimap","mothur","qiime","rdp","spingo"])
    Array of tools used in NanoClass run.
    Notation should be ["toolname"], including square brackets, even if only a single tool is selected. 


porechop
^^^^^^^^^^^^^^^^^^^

Porechop is a tool to find and remove adapters from Oxford Nanopore reads (https://github.com/rrwick/Porechop).
Adapters on the ends of reads are trimmed off, and when a read has an adapter in its middle, it is treated as chimeric and chopped into separate reads.
NanoClass runs Porechop on the raw read files provided by the user.

Porechop is implemented in NanoClass with the following flexible parameters for the user to change:

*checkreads* [integer] (default: 20000)
    The number of reads porechop should check to identify adapter sequences.
    The adapters identified based on this subset will trimmed from all sequences.

*environment* [string] (default: "../envs/preprocess.yml")
    The recipe for conda to create the preprocessing environment including all dependencies needed to run porechop.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*threads* [interger] (default: 16)
    The number of threads used per sample by porechop. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*memory* [integer] (default: 4000)
    Memory reserved for porechop per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.


nanofilt
^^^^^^^^^^^^^^^^^^^

Nanofilt is a tool to trim and filter Oxford Nanopore reads based on length and quality (https://github.com/wdecoster/nanofilt).
Length filtering can remove spurious sequences that strongly deviate from the expected length of the marker gene of interest.
NanoClass runs Nanofilt on the adapter filtered reads processed by Porechop.

Nanofilt is implemented in NanoClass with the following flexible parameters for the user to change:
 
*minlen* [integer] (default: 1)
    Reads that are shorter than *minlen* will be discarded by nanofilt. The default value of 1 disables filtering of short reads.
    Appropriate value depends on the length range of the marker gene of interest (for most 16S rRNA-based projects is 1400 reasonable).
    Users should carefully choose this value to prevent spurious sequences (if too low) or valid data loss (if too high).

*maxlen* [integer] (default: 10000)
    Reads that are longer than *maxlen* will be discarded by nanofilt. The default value of 10000 effectively disables filtering of long reads.
    Appropriate value depends on the length range of the marker gene of interest (for most 16S rRNA-based projects is 1600 reasonable).
    Users should carefully choose this value to prevent spurious sequences (if too high) or valid data loss (if too low).

*quality* [integer] (default: 0)
    Reads with an average read quality score below *quality* will be discarded. The default value of 0 disables quality filtering of reads.
    Increasing *quality* goes at the expense of the number of reads retained for downstream analyses.
    An appropriate value for a typical Oxford Nanopore MinION dataset is 9 or 10.

*environment* [string] (default: "../envs/preprocess.yml")
    The recipe for conda to create the preprocessing environment including all dependencies needed to run nanofilt.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*memory* [integer] (default: 2000)
    Memory reserved for nanofilt per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.

subsample
^^^^^^^^^^^^^^^^^^^^^^^

Subsampling can be usefull during tool selection (see typical workflow section of this documentation), when there is more data then necessary, or when the number of reads differs strongly between samples.
If enabled, NanoClass performs subsamplng on the reads that were filtered by Nanofilt.
Subsampling is implemented in NanoClass using seqtk (https://github.com/lh3/seqtk), with the following flexible parameters for the user to change:

*skip* [boolian] (default: false)
    Whether or not the sequence files should be subsampled. Subsampling of reads can substantially decrease runtime but of course only results in the analyses of a subset of the data. 

*samplesize* [integer] (default: 10000)
   The number of reads that will be subsampled. *samplesize* is ignored when *skip* is true. Subsampling is applied after filtering by nanofilt.
   For tool selection, a *samplesize* as small as 100 already produced representive tool performance statistics during tests on communities of variable complexity

*environment* [string] (default: "../envs/preprocess.yml")
    The recipe for conda to create the preprocessing environment including all dependencies needed to run subsample.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.


nanostats
^^^^^^^^^^^^^^^^^^^^^^^

Nanostat computes various statistics for Oxford Nanopore reads (https://github.com/wdecoster/nanostat)
NanoClass runs Nanostat on the filtered reads generated by Nanofilt. 
After running NanoClass, the Nanostat results can be found in stats/<run>/nanofilt/, where <run> is the run label provided by the user in the sample.csv.
Nanostat is implementen in NanoClass with the following flexible parameters for the user to change:

*environment* [string] (default: "../envs/preprocess.yml")
    The recipe for conda to create the preprocessing environment including all dependencies needed to run Nanostat.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*threads* [interger] (default: 2)
    The number of threads used per sample by nanostat. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*memory* [integer] (default: 8000)
    Memory reserved for nanostat per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.


nanoplot
^^^^^^^^^^^^^^^^^^^^

NanoClass uses pistes to generate quality plots of the Nanofilt-filtered reads (https://github.com/mbhall88/pistis).
These plots are included in the NanoClass report. Separate PDF's can also be found in plots/<run>/nanofilt/, , where <run> is the run label provided by the user in the sample.csv.
Nanoplot is implementen in NanoClass with the following flexible parameters for the user to change:

*downsample* [integer] (default: 0)
    Down-sample the sequence files used to generate quality plots to a given number of reads. Set to 0 for no down-sampling.
    Down-sampling may decrease runtime somewhat, but as this step does not take long in general it is probably not necessary for most users.

*environment* [string] (default: "../envs/preprocess.yml")
    The recipe for conda to create the preprocessing environment including all dependencies needed to run nanoplot.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*memory* [integer] (default: 4000)
    Memory reserved for nanoplot per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.

common
^^^^^^^^^^^^^^^^^^^^

The parameter settings listed under common are used by several different processes during a typical NanoClass run.
The following common parameter settings can be changed by the user:

*dburl* [string] (default:"https://www.arb-silva.de/fileadmin/silva_databases/qiime/Silva_132_release.zip)
    The URL to the database resources used by most taxonomic classification tools implemented in NanoClass.
    The default url can be used for the analyses of both 16S and 18S rRNA sequences.
    For further details on how to change and customize databases see the database section of this documentation.

*ssu* [string] (default: "16S")
    Which SILVA database to use. Allowed values: "16S" or "18S". For further details on how to change and customize databases see the database section of this documentation.

*group-by* [string] (default: "sample")
    Whether the taxonomic bar plots included in the report should be grouped by sample or by method (i.e. tool).
    For tool selection, choose "method" for classification enter "sample". See also the typical workflow section of this documentation.

*environment* [string] (default: "../envs/R4.0.yml")
    The recipe for conda to create the R4.0 environment including all dependencies needed to run common processes.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*dbmemory* [integer] (default: 4000)
    Memory reserved for building and downloading the common database in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.


blastn
^^^^^^^^^^^^^^^^^^^^

BLASTn is one of the 11 classification tools implemented in NanoClass.
BLASTn finds regions of similarity between the Nanofilt-filtered (and, if enabled, subsampled) reads and the entries in the database.
Typically, BLASTn finds multiple good hits to different taxa in the database.
To obtain a consensus classification, NanoClass uses a (LCA) Last Common Ancestor approach.

The following blastn parameter settings can be changed by the user:

*lcaconsensus* [float] (default: 0.5)
    Threshold for calling a consensus. Proportion of blastn hits with the same classification needed to return a consensus.
    Taxonomic classifications at each of the 6 taxonomic levels (Domain, Phylum, Class, Order, Family, Genus) will only be assigned if there is consensus at that level.
    Range: 0.5-0.99, where 0.5 indicates majority consensus and 0.99 indicates absolute consensus.

*evalue* [float] (default: 0.00001)
    Expectation value (E) threshold for saving blastn hits. Needs to be provided as decimal number, not in scientific notation!
    Decreasing the *evalue* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*pctidentity* [integer] (default: 80)
    Percent identity threshold for saving blastn hits. Range: 0-100.
    Increasing the *pctidentity* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*alnlength* [integer] (default: 100)
    Minimal absolute alignment length for saving blastn hits.
    Increasing the *alnlength* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*ntargetseqs* [integer] (Default: 50)
    Maximum number of aligned sequences to keep. Increasing the *ntargetseqs* increases runtime but may also result in more accurate classifications.

*environment* [string] (default: "../envs/blast.yml")
    The recipe for conda to create the blast environment including all dependencies needed to run blastn.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*threads* [interger] (default: 10)
    The number of threads used per sample by blastn. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*memory* [integer] (default: 500)
    Memory reserved for blastn per sample per thread in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.


dcmegablast
^^^^^^^^^^^^^^^^^^^^

dcMegablast is one of the 11 classification tools implemented in NanoClass.
dcMegablast finds regions of similarity between the Nanofilt-filtered (and, if enabled, subsampled) reads and the entries in the database.
Typically, dcMegablast finds multiple good hits to different taxonomic groups.
To obtain a consensus classification, NanoClass uses a Last Common Ancestor approach.

The following blastn parameter settings can be changed by the user:

*lcaconsensus* [float] (default: 0.5)
    Threshold for calling a consensus. Proportion of dcmegablast hits with the same classification needed to return a consensus.
    Taxonomic classifications at each of the 6 taxonomic levels (Domain, Phylum, Class, Order, Family, Genus) will only be assigned if there is consensus at that level.
    Range: 0.5-0.99, where 0.5 indicates majority consensus and 0.99 indicates absolute consensus.

*evalue* [float] (default: 0.00001)
    Expectation value (E) threshold for saving dcmegablast hits. Needs to be provided as decimal number, not in scientific notation!
    Decreasing the *evalue* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*pctidentity* [integer] (default: 80)
    Percent identity threshold for saving dcmegablast hits. Range: 0-100.
    Increasing the *pctidentity* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*alnlength* [integer] (default: 100)
    Minimal absolute alignment length for saving dcmegablast hits.
    Increasing the *alnlength* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*ntargetseqs* [integer] (Default: 50)
    Maximum number of aligned sequences to keep. Increasing the *ntargetseqs* increases runtime but may also result in more accurate classifications.

*environment* [string] (default: "../envs/blast.yml")
    The recipe for conda to create the blast environment including all dependencies needed to run dcmegablast.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*dbmemory* [integer] (default: 3000)
    Memory reserved to build the dcmegablast database in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.
    The same database is used by blastn and mageblast, if one is already present, it will not be build again.

*threads* [interger] (default: 16)
    The number of threads used per sample by dcmegablast. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*memory* [integer] (default: 50000)
    Memory reserved for dcmegablast per sample per thread in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.



centrifuge
^^^^^^^^^^^^^^^^

Centrifuge is one of the 11 classification tools implemented in NanoClass.
In addition to the common database, centrifuge requires mapping and sequence files which will be automatically downloaded by NanoClass using the following parameter settings.
Note that the Centrifuge SILVA version should correspond to the common SILVA version.

The following centrifuge parameter settings can be changed by the user:

*taxmapurl* [string] (default: "https://www.arb-silva.de/fileadmin/silva_databases/release_132/Exports/taxonomy/taxmap_embl_ssu_ref_nr99_132.txt.gz")
    URL to SILVA taxmap. If changed make sure it corresponds to the database provided under common.

*sequrl* [string]: (default: "https://www.arb-silva.de/fileadmin/silva_databases/release_132/Exports/SILVA_132_SSURef_Nr99_tax_silva.fasta.gz")
    URL to SILVA sequences. If changed make sure it corresponds to the database provided under common.

*environment* [string] (default: "../envs/centrifuge.yml")
    The recipe for conda to create the centrifuge environment including all dependencies needed to run centrifuge.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*dbthreads* [interger] (default: 4)
    The number of threads used by centrifuge to download and build the centrifuge database.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

*dbmemory* [integer] (default: 500)
    Memory reserved to download and build the centrifuge database in Mb. 
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

*threads* [interger] (default: 1)
    The number of threads used per sample by centrifuge. Centrifuge is super fast so there is no need to increase *threads*.

*memory* [integer] (default: 16000)
    Memory reserved for centrifuge per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.

idtaxa
^^^^^^^^^^^^^^^^^^

IDtaxa is one of the 11 classification tools implemented in NanoClass (https://rdrr.io/bioc/DECIPHER/man/IdTaxa.html).
IDtaxa is implemented in the DECIPHER R package and classifies sequences by assigning a confidence to taxonomic labels for each taxonomic level.
The training set used by IDtaxa is produced by learntaxa.

The following idtaxa parameter settings can be changed by the user:

*pctthreshold* [integer] (default: 60)
    The confidence at which to truncate the output taxonomic classifications. Lower values of *threshold* will classify deeper into the taxonomic tree at the expense of accuracy.
    Test runs showed that idtaxa failed to produce any taxonomic classifications at the default *pctthreshold*. Lowering *pctthreshold* resulted in many spurious classifications.

*environment* [string] (default: "../envs/R4.0.yml")
    The recipe for conda to create R4.0 environment including all dependencies needed to run idtaxa.
    If not already present, the environment will be automatically be installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*dbmemory* [integer] (default: 3000)
    Memory reserved to train the classifier using learntaxa in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

*threads* [interger] (default: 8)
    The number of threads used per sample by idtaxa. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*memory* [integer] (default: 10000)
    Memory reserved for idtaxa per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.


kraken
^^^^^^^^^^^^^^^^^^

Kraken2 is one of the 11 classification tools implemented in NanoClass (https://github.com/DerrickWood/kraken2/wiki/Manual).
Unlike the other tools, Kraken2 is a k-mer based classifier with an integrated lowest common ancestor (LCA) approach and is super fast.

The following kraken parameter settings can be changed by the user:

*dbtype* [string] (default: "silva")
    Kraken supports 16S rRNA databases not based on NCBI's taxonomy, including Greengenes, SILVA, and RDP. Only SILVA was tested to use within NanoClass.

*environment* [string] (default: "../envs/kraken2.yml")
    The recipe for conda to create the kraken2 environment including all dependencies needed to run kraken.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*dbthreads* [interger] (default: 8)
    The number of threads used by kraken to download and build the kraken database.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

*dbmemory* [integer] (default: 1000)
    Memory reserved to download and build the kraken database in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

*threads* [interger] (default: 16)
    The number of threads used per sample by kraken. 

*memory* [integer] (default: 500)
    Memory reserved for kraken per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.


megablast
^^^^^^^^^^^^^^^^^^^^

Megablast is one of the 11 classification tools implemented in NanoClass.
Megablast finds regions of similarity between the Nanofilt-filtered (and, if enabled, subsampled) reads and the entries in the database.
Typically, Megablast finds multiple good hits to different taxonomic groups.
To obtain a consensus classification, NanoClass uses a Last Common Ancestor approach.

The following blastn parameter settings can be changed by the user:

*lcaconsensus* [float] (default: 0.5)
    Threshold for calling a consensus. Proportion of megablast hits with the same classification needed to return a consensus.
    Taxonomic classifications at each of the 6 taxonomic levels (Domain, Phylum, Class, Order, Family, Genus) will only be assigned if there is consensus at that level.
    Range: 0.5-0.99, where 0.5 indicates majority consensus and 0.99 indicates absolute consensus.

*evalue* [float] (default: 0.00001)
    Expectation value (E) threshold for saving megablast hits. Needs to be provided as decimal number, not in scientific notation!
    Decreasing the *evalue* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*pctidentity* [integer] (default: 80)
    Percent identity threshold for saving megablast hits. Range: 0-100.
    Increasing the *pctidentity* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*alnlength* [integer] (default: 100)
    Minimal absolute alignment length for saving megablast hits.
    Increasing the *alnlength* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organisms that are poorly represented in the database.

*ntargetseqs* [integer] (Default: 50)
    Maximum number of aligned sequences to keep. Increasing the *ntargetseqs* increases runtime but may also result in more accurate classifications.

*environment* [string] (default: "../envs/blast.yml")
    The recipe for conda to create the blast environment including all dependencies needed to run megablast.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*dbmemory* [integer] (default: 3000)
    Memory reserved to build the megablast database in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.
    The same database is used by blastn and mageblast, if one is already present, it will not be build again.

*threads* [interger] (default: 16)
    The number of threads used per sample by megablast. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*memory* [integer] (default: 50000)
    Memory reserved for megablast per sample per thread in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.


minimap
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Minimap2 is one of the 11 classification tools implemented in NanoClass.
Minimap2 is a fast sequence alignment program used to align noisy Oxfort Nanopore MinION reads against a reference database (https://github.com/lh3/minimap2).
In NanoClass, Minimap2 aligns Nanofilt-filtered (and, if enabled, subsampled) reads against the reference database, where the user can determine how many seconday alignments to consider.
To obtain a consensus classification of the primary and seconday alignments, NanoClass uses a Last Common Ancestor approach

The following minimap parameter settings can be changed by the user:

*lcaconsensus* [float] (default: 0.5)
    Threshold for calling a consensus. Proportion of minimap primary and secondary alignments with the same classification needed to return a consensus.
    Taxonomic classifications at each of the 6 taxonomic levels (Domain, Phylum, Class, Order, Family, Genus) will only be assigned if there is consensus at that level.
    Range: 0.5-0.99, where 0.5 indicates majority consensus and 0.99 indicates absolute consensus.

*ntargetseqs* [integer] (default: 10)
    Number of secondary alignments to save and consider when computing LCA.

*environment* [string] (default: "../envs/minimap2.yml")
    The recipe for conda to create the minimap2 environment including all dependencies needed to run minimap.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*memory* [integer] (default: 3000)
    Memory reserved for minimap per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.

*threads* [interger] (default: 16)
    The number of threads used per sample by minimap. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.


mothur
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Mothur is one of the 11 classification tools implemented in NanoClass.
In NanoClass, Mother aligns the Nanofilt-filtered (and, if enabled, subsampled) reads against the reference database 
using the align_seqs function with ksize=6 and align=needleman.

Because mothur saves the entire database in memory, the memory requirements are high which means it may not be able to run it on a standard desktop or laptop computer.
In that case, just skip mothur in the NanoClass run by removing it from the methods array at the top of the config.yaml.

The following mothur parameter settings can be changed by the user:

*environment* [string] (default: "../envs/mothur.yml")
    The recipe for conda to create the mothur environment including all dependencies needed to run mothur.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*memory* [integer] (default: 1000)
    Memory reserved for mothur per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.

*threads* [interger] (default: 8)
    The number of threads used per sample by mothur. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*dbmemory* [integer] (default: 5000)
    Memory reserved to build the mothur database in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.



qiime
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

QIIME2 is one of the 11 classification tools implemented in NanoClass.
NanoClass uses the QIIME2 feature-classifier classify-consensus-vsearch utility to classify the Nanofilt-filtered (and, if enabled, subsampled) reads using the reference database.

The following qiime parameter settings can be changed by the user:

*lcaconsensus* [float] (default: 0.51)
    Threshold for calling a consensus. Proportion of qiime hits with the same classification needed to return a consensus.
    Taxonomic classifications at each of the 6 taxonomic levels (Domain, Phylum, Class, Order, Family, Genus) will only be assigned if there is consensus at that level.
    Range: 0.51-1, where 0.51 indicates majority consensus and 1 indicates absolute consensus.

*pctidentity* [float] (default: 0.8)
    Proportion identity threshold for saving minimap hits. Range: 0-1. Should be given as a proportion, not a percentage.
    Increasing the *pctidentity* may result in more consensus classifications but could also reduce the likelyhood of finding any taxonomic classification, in particular for organism$

*ntargetseqs* [integer] (Default: 10)
    Maximum number of aligned sequences to keep. Increasing the *ntargetseqs* increases runtime but may also result in more accurate classifications.

*environment* [string] (default: "../envs/qiime2.yml")
    The recipe for conda to create the qiime2 environment including all dependencies needed to run qiime.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*memory* [integer] (default: 10000)
    Memory reserved for qiime per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.

*threads* [interger] (default: 16)
    The number of threads used per sample by qiime2. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*dbmemory* [integer] (default: 3000)
    Memory reserved to build the qiime database in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.


rdp
^^^^^^^^^^^^^^^^^^^^^^^^^

RDP is one of the 11 classification tools implemented in NanoClass.
NanoClass runs the assignTaxonomy utility of the DADA2 R package on the Nanofilt-filtered (and, if enabled, subsampled) reads using the reference database. 
It implements the RDP classifier algorithm with kmer size 8 and 100 bootstrap replicates and assignes taxonomy based on he minimum bootstrap confidence.

The following rdp parameter settings can be changed by the user:

*pctthreshold* [integer] (default: 60)
    The minimum bootstrap confidence at which to truncate the output taxonomic classifications.
    Lower values of *pctthreshold* will classify deeper into the taxonomic tree at the expense of accuracy.

*environment* [string] (default: "../envs/R4.0.yml")
    The recipe for conda to create the R4.0 environment including all dependencies needed to run rdp.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*memory* [integer] (default: 5000)
    Memory reserved for rdp per sample in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.

*threads* [interger] (default: 8)
    The number of threads used per sample by rdp. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*dbmemory* [integer] (default: 75000)
    Memory reserved to build the rdp database in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

spingo
^^^^^^^^^^^^^^^^^^^^^^^^^

Spingo is one of the 11 classification tools implemented in NanoClass (https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-015-0747-1).
NanoClass runs Spingo on the Nanofilt-filtered (and, if enabled, subsampled) reads using the reference database.

The following spingo parameter settings can be changed by the user:

*environment* [string] (default: "../envs/spingo.yml")
    The recipe for conda to create the spingo environment including all dependencies needed to run spingo.
    If not already present, the environment will be automatically installed by NanoClass when using the ``snakemake --use-conda`` option.
    Changes to the environment are not recommended unless you are an advanced user.

*dbthreads* [interger] (default: 16)
    The number of threads used to build the spingo database.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

*dbmemory* [integer] (default: 50000)
    Memory reserved to build the spingo database in Mb.
    This step is independent of the properties of the data to be analysed and therefore does not need to be changed.

*threads* [interger] (default: 16)
    The number of threads used per sample by spingo. Increasing the number of threads may speed up the analyses.
    NanoClass will automatically downgrade the number of threads when fewer cores are specified by the user in the ``snakemake --use-conda --cores <ncores>``
    command. It is therefore not necesary to change this value for a typical run of NanoClass.

*memory* [integer] (default: 50000)
    Memory reserved for spingo per sample per thread in Mb. If insufficient, NanoClass will automatically double the amount of memory and try again.
    Therefore, it is not necessary to change this value for a typical NanoClass run.
