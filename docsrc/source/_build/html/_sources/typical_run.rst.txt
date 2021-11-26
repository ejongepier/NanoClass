Two tools in one
========================

Assuming you have no preference or prior knowledge of which tool performs best on your specific data, you may first want to assess tool performance.
This can be quite time consuming if you would run all 10 tools on all of your data.
Luckily tests on data sets of variable complexity has shown that a small subset of data is enough to assess tool performance.
Once you have decided which tool or tools to use you can run these tools on your entire dataset.

Stage 1 - Tool selection
----------------------------

To run all 10 tools on a small subset of your data, you can specify how many reads and samples to consider.
Tests showed that 100 reads for 3 representative samples each works for most datasets.

Subset the number of reads
.............................

In the `config.yaml` you can whether you like to subset the number of reads and how many reads per sample you like to include:

.. code-block:: bash

   subsample:
      skip:                          false
      samplesize:                    100 

In above example subsample is enabled and 100 random reads per sample will be included in the analyses.
Mind that no tabs are allowed in the `config.yaml`, only spaces.

Subset the number of samples
.............................

In the `samples.csv` you can enter the sample labels and the paths to the input files. If you only want to use a small subset of your samples in this initial stage, simply list only those samples.
If you expect the community structure and composition to differ between treatments, it is recommended to include a sample from each of tese treatments at this stage.

.. code-block:: bash

   run,sample,barcode,path
   stage1,MockZymo,,input/barcode06.passed.fastq.gz
   stage1,MockATCC,,input/barcode09.fastq.gz

In this example only two samples are used to test the performance of all 10 tools. 
The first line is an obligatory header.
The next lines are a comma separated list of:

- `run` - The run ID used as a label in NanoClass output and reports. It is recommended to list the same run ID for each of your samples. You can use any label as long as it consists of only letters and numbers.
- `sample` - The sample IDs used as labels in NanoClass output and reports. Sample labels should be unique so if your have multiple files per sample you should first concatenate them, e.g. using the `cat` function. You can use any label independent of how your files are named, as long as you only use number and letters.
- `barcode` - The barcode column should remain empty as NanoClass currently only accepts demultiplexed data.
- `path` - The path to the MinION Nanopore sequences in fastq.gz format. In this example the files are stored in an `input` subdirectory within the NanoClass directory.
 

 
Run NanoClass stage 1
.............................

You are now all set to run nanoClass tool seletion on your subset of data. Make sure you are in the NanoClass directory and run:

.. code-block:: bash

   Snakemake --use-conda --cores <ncores>

Where ncores is the number of cores available on your system.


Assess tool performance NanoClass stage 1
...........................................

Once NanoClass finished, you can generate a report:

.. code-block:: bash

   snakemake --report report/NanoClass-stage1.zip

Unzip it and view the NanoClass-stage1/report.html.
Three results in particular can help decide on which tool te continue with in the next stage of the analysis:

- Classification - Set of taxonomic bar plots of the abundances at different taxonomic levels. May help to decide which tools best fit your expectations if you already have prior knowledge of the composition of your samples.
- Precision: Precision plot with information on how much the taxonomic classification of each tool deviates from the majority consensus classification at each taxonomic level. Note that precision is not the same as accuracy, because for accuracy you would need to know the exact composition of the subsample of your data, which is typically unknown. 
- Runtime: Runtime plots showing how long it took for each of the 10 tools to run. This may be a decisive factor in your choice of tools if multiple tools show similar performace based on classification or precision, or if you are looking at a deadline. 

For detailed information on the content of the report see the report documentation.

Stage 2 - Taxonomic classification
------------------------------------
 
Once you decided on which tool or tools to continue with, you can run NanoClass using only that tool / those tools on your complete dataset.

Select a tool(s)
...........................

At the top of the `config.yaml` file you can limit the number of tools. By default all 10 tools are listed, but you can remove those you sre not interested in:

.. code-block:: bash

   methods:                           ["megablast","minimap"]

In this example only minimap2 and megablast are used.


Include all reads per sample
..............................

In the `config.yaml` you can now disable subsampling using skip true.

.. code-block:: bash

   subsample:
      skip:                          true
      samplesize:                    100

In this example the sample size is ignored because subsampling is skipped.
Mind that no tabs are allowed in the `config.yaml`, only spaces.

Of course you can still opt to subsample your complete dataset, for instance when the number of reads vary between samples or when more data was generated then needed to characterize your community.
In that case, set skip to false and just increase the sample size.


Include all samples
.............................

To run NanoClass on all of your samples simply complement the `samples.csv` with your remaining samples and change the run ID, e.g. to stage2.

.. warning ...

   Mind that NanoClass automatically checks which results are already present. 
   If you use the same run id in stage 1 and 2, the samples included in stage 1 will be automatically skipped by NanoClass during the stage 2 run.
   This means that the final results for those samples will be based on only the subset of the reads specified in stage 1.
   To prevent this just use a new run ID. 


Run NanoClass stage 2
.............................

You can run NanoClass stage 2 the same way as for stage 1. 
NanoClass will automatically use the new settings you provided in the `config.yaml` and all the samples in the `sample.cvs`

.. code-block:: bash

   Snakemake --use-conda --cores <ncores>

Where ncores is the number of cores available on your system.


Assess classification NanoClass stage 2
...........................................

Once NanoClass finished, you can generate a report again:

.. code-block:: bash

   snakemake --report report/NanoClass-stage2.zip


Assess classification NanoClass stage 2
...........................................

Unzip it and view the NanoClass-stage2/report.html.
Which again contain the classification barplots and run time.
Mind that precision is missing if you run fewer then 3 tools because the consensus taxonomy based on few tools is not particularly informative.

For detailed information on the content of the report see the report documentation.


In addition to the report, you can access the following raw data tables for downstream analyses.

Abundance table
^^^^^^^^^^^^^^^^^^^^^^^^

The abundance tables contain the absolute abundances for each taxonomic classification.
A separate table is generated for each run, tool and sample: `classification/<run>/<tool>/<sample>.<tool>.otumat`
To join the tables from different samples into one abundance table, you could try the R function merge.

Taxonomy table
^^^^^^^^^^^^^^^^^^^^^^^^

The taxonomy table contains the classifications for 6 levels: Domain, Phylum, Class, Order, Family and Genus.
A separate table is generated for each run, tool and sample: `classification/<run>/<tool>/<sample>.<tool>.taxmat`

Taxonomy list
^^^^^^^^^^^^^^^^^^^^^^^^

The taxonomy list gives the 6-level taxonomic classification for each of your reads.
A separate table is generated for each run, tool and sample: `classification/<run>/<tool>/<sample>.<tool>.taxlist`


