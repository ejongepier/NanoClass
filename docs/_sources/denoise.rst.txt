Quality control and feature tabulation
##########################################

There are many ways in which to enter the QIIME2 workflow. Which one to use depends mostly on whether your data has been preprocessed in any way.
In our case, sequences were already demultiplexed by the sequencing facility, such that we have two files for each of the samples: 
one containing the forward read "R1" and one with the reverse "R2".
We can import all these sequence files into QIIME2 in one go using a manifest file.

See the QIIME2 `Importing data <https://docs.qiime2.org/2020.8/tutorials/importing/>`_ tutorial information on how to import different input data formats.

Prepping the manifest file
=======================================

The manifest file includes the sample ids, the path to where each fastq.gz file is stored, and its orientation.
Because we have paired-end data and thus two files for each sample, we will list each sample twice, once for the forward and once for the reverse orientation.
This is what the first few lines of the manifest file look like (or run ``head data/MANIFEST.csv``): 

.. code-block:: bash

   sample-id,absolute-filepath,direction
   DUMMY10,$PWD/data/Sample-DUMMY10_R1.fastq.gz,forward
   DUMMY10,$PWD/data/Sample-DUMMY10_R2.fastq.gz,reverse
   DUMMY11,$PWD/data/Sample-DUMMY11_R1.fastq.gz,forward
   DUMMY11,$PWD/data/Sample-DUMMY11_R2.fastq.gz,reverse
   ...

You can find the manifest file under data/MANIFEST.csv as a comma-separated file.


Importing data
=======================================

.. important::

   Don't forget to activate your conda environment before running any QIIME2 command.
   Just run: ``conda activate qiime2-2021.2``.


We can use the manifest file to import the data into QIIME2. 
I already selected the appropriate data type and input format, so just run:

.. code-block:: bash

   mkdir -p prep
   qiime tools import \
     --type 'SampleData[PairedEndSequencesWithQuality]' \
     --input-path data/MANIFEST.csv \
     --input-format PairedEndFastqManifestPhred33 \
     --output-path prep/demux-seqs.qza

This will create a special data object called an 'artifact' which is a zip archive with a '.qza' (QIIME zipped artifact) extension. 
Artifacts are the main file type used in QIIME2 analyses.
In addition to the actual data, in this case the fastq.gz files,
artifacts contain metadata such as file format, relevant citations and the data provenance. 

If you quickly want to see what sort of artifact it is, run

.. code-block:: bash

   qiime tools peek prep/demux-seqs.qza

From the demultiplexed artifact we can create an interactive summary of the sequences.
This summary includes the number of sequences that were obtained per sample and the distribution of sequence quality scores at each position.

.. code-block:: bash

   qiime demux summarize \
     --i-data prep/demux-seqs.qza \
     --o-visualization prep/demux-seqs.qzv

The result is the other main object in QIIME2: a 'vizualisation', which is a zip archive with '.qzv' (QIIME zipped vizualisation) extension.
Unlike artifacts, **vizualisations cannot be used as input for further analyses in QIIME2**.
They are only ment for display, for instance using the ``qiime tools view`` utility.

.. code-block:: bash

   qiime tools view prep/demux-seqs.qzv

Alternatively, we can view it online: https://view.qiime2.org/. 
This online utility is also handy to share QIIME2 results with collaborators that do not have QIIME2 installed.

.. admonition:: Question 1

   Check out the interactive quality plots. What could cause the 'drop' in quality at the 5-prime end of your sequences? 

Primer removal
=======================================

The next step is to remove any primer sequences. We will use the cutadapt QIIME2 plugin for that. 
Because we have paired-end data, there is a forward and reverse primer, referenced by the parameters ``--p-front-f`` and ``--p-front-r`` in below command.
These are already the correct primer sequences used for your data.

.. Tip:: 

   Some steps in the QIIME2 workflow can take quite some time. 
   We can speed things up by running certain processes using more than one cpu. 
   Exactly how many cpus you can select mainly depends on how many you have available on your computer.

For the following command, I used ``--p-cores 8`` (but please adjust the number of cpus based on how many you have available!).

.. code-block:: bash

   qiime cutadapt trim-paired \
     --i-demultiplexed-sequences prep/demux-seqs.qza \
     --p-front-f GTGYCAGCMGCCGCGGTAA \
     --p-front-r CCGYCAATTYMTTTRAGTTT \
     --p-error-rate 0 \
     --o-trimmed-sequences prep/trimmed-seqs.qza \
     --p-cores 1 \
     --verbose

The output written to the screen shows the commands that are run, as well as some info on the number of reads that are processed and trimmed.

The actual result is not written to the screen but saved as another QIIME2 artifact, which contains the trimmed sequences. 
Like with prep/demux-seqs.qza from the previous step, we can create a summary vizualisation and view it like so:

.. code-block:: bash

   qiime demux summarize \
     --i-data prep/trimmed-seqs.qza \
     --o-visualization prep/trimmed-seqs.qzv

   qiime tools view prep/trimmed-seqs.qzv


Compare the summary vizualisations of your demux and trimmed sequences.

.. admonition:: Question 2

   | What is the effect on the 5-prime quality score? 
   | What is the effect on the sequence length summary?


Feature table construction
=======================================

Sequences were traditionally clustered into operational taxonomic units based on a fixed similarity threshold, typically 97% 
(`Rideout et al. 2014 <https://pubmed.ncbi.nlm.nih.gov/25177538/>`_). 
Such OTU clustering methods have been largely replaced now by denoise algorithms, which correct amplicon sequence errors and 
produce high-resolution amplicon sequence variants that resolve differences of as little as one nucleotide 
(`Callahan et al. 2017 <https://www.nature.com/articles/ismej2017119>`_).

Two denoisers are implemented in QIIME2: deblur-denoise and DADA2-denoise.
Their performance is quite similar so which one you use in the end depends largely on taste 
(`Nearing et al. 2018 <https://pubmed.ncbi.nlm.nih.gov/30123705/>`_, 
`Caruso et al. 2019 <https://msystems.asm.org/content/4/1/e00163-18>`_). 
In the following sections you will run both.

See `Estaki et al. 2020 <https://currentprotocols.onlinelibrary.wiley.com/doi/full/10.1002/cpbi.100>`_ for further details on the denoising workflow.

Deblur denoise
------------------------------------------

The Deblur-denoising procedure is split up in 3 steps.

Step 1. Join read pairs 
........................................ 

First, join the forward and reverse reads into a single sequence spanning the entire target region.
This joining is based on the overlap between the forward and reverse reads.

Lets first do some math:

.. admonition:: Question 3

   | a. What is the length of your trimmed forward and reverse reads? (Tip: check out the length of the primer sequences used in the ``qiime cutadapt trim-paired`` command)
   | b. What is the length of the fragment that was sequenced? (Tip: the primers that were used were 515F-926R)
   | c. What was the length of the primer trimmed fragment (i.e. target region)?
   | d. Given the above, how much overlap do we have between your forward and reverse reads?
   | e. Can you confirm the numbers in question a-b by viewing the appropriate vizualisations?

Now that you have checked whether there is enough overlap to reliably join your forward and reverse reads, lets do the joining.
Note that I used `--p-threads 8`, but you need to decide for yourself how many cpus you have available.

.. code-block:: bash

   mkdir -p deblur
   qiime vsearch join-pairs \
     --i-demultiplexed-seqs prep/trimmed-seqs.qza \
     --o-joined-sequences deblur/joined-seqs.qza \
     --p-threads 1 \
     --verbose

Lets summarize and view again:

.. code-block:: bash

   qiime demux summarize \
     --i-data deblur/joined-seqs.qza \
     --o-visualization deblur/joined-seqs.qzv

   qiime tools view deblur/joined-seqs.qzv


.. admonition:: Question 4

   | Can you confirm the target region length you computed in question 3c.?
   | What happends to the quality in the middle of the joined reads and why?


Step 2. Quality filter
........................................

The fastq.gz files not only contain the DNA sequences but also a quality score for each of the nucleotides.
These quality scores are used by deblur-denoise to apply an initial quality filtering.

.. warning::

   With qiime2-2021.2, the following command will produce a ``YAMLLoadWarning`` warning, which you can ignore.

To perform quality filtering, just run:

.. code-block:: bash

   qiime quality-filter q-score \
     --i-demux deblur/joined-seqs.qza \
     --o-filtered-sequences deblur/filt-seqs.qza \
     --o-filter-stats deblur/filt-stats.qza \
     --verbose

View the summary of your joined and filtered sequences:

.. code-block:: bash

   qiime demux summarize \
     --i-data deblur/filt-seqs.qza \
     --o-visualization deblur/filt-seqs.qzv

   qiime tools view deblur/filt-seqs.qzv

These results actually look very, very similar to the summary vizualisation of the joined sequences.
In fact, when you look at the trimming stats, nothing really seems to have happened:

.. code-block:: bash

   qiime metadata tabulate \
      --m-input-file deblur/filt-stats.qza \
      --o-visualization deblur/filt-stats.qzv

   qiime tools view deblur/filt-stats.qzv

This is somewhat unusual but so is the quality of this particular data set. Just be prepared that your own data may be of lower quality.

.. admonition:: Question 5

   Have a look at the ``qiime quality-filter q-score`` help function and see if you can find an explanation why no quality filtering was performed:

   .. code-block:: bash

      qiime quality-filter q-score --help

Now lets prepare for the next step where the actual denoising is performed:

.. important::

   When we continue with deblur-denoise in the next step, you need to truncate your fragments such that they are all of the same length.
   The position at which sequences are truncated is specified by the ``--p-trim-length`` parameter.
   Any sequence that is shorter than this value will be lost from your analyses.
   Any sequence that is longer will be truncated at this position.


.. admonition:: Question 6

   | What happends to the quality of the fragments that are longer than the presumed fragment size? Why?
   | What is an appropriate value for ``--p-trim-length``?
   | What proportion of your fragments will be retained approximately using this value?
   | How many bases will be trimmed off from fragments of median length?



Step 3. Denoise
........................................

Run deblur-denoise on the joined and quality trimmed sequences.
I selected a ``--p-trim-length`` of 370, because that resulted in minimal data loss.
That is, only <9% of the reads were discarded for being too short, and only 4 bases were trimmed off from sequences of median length.
Again, I used 8 cpus here, but you may have to modify that (``--p-jobs-to-start 8``)

.. code-block:: bash

   qiime deblur denoise-16S \
     --i-demultiplexed-seqs deblur/filt-seqs.qza \
     --p-trim-length 370 \
     --o-representative-sequences deblur/deblur-reprseqs.qza \
     --o-table deblur/deblur-table.qza \
     --p-sample-stats \
     --o-stats deblur/deblur-stats.qza \
     --p-jobs-to-start 1 \
     --verbose

This command results in three output files: 

#. A feature table artifact with the frequencies per sample and feature.

#. A representative sequences artifact with one single fasta sequence for each of the features in the feature table.

#. A stats artifact with details of how many reads passed each filtering step of the deblur procedure.

Let start with converting the stats artifact into a vizualisations which we can then view again, like so:

.. code-block:: bash

   qiime deblur visualize-stats \
     --i-deblur-stats deblur/deblur-stats.qza \
     --o-visualization deblur/deblur-stats.qzv

   qiime tools view deblur/deblur-stats.qzv

The resulting table shows how many sequences per sample passed the deblur quality check, including the total number and the number of unique sequences.
Just hoover over the table headers to get more information. Note that artifact here is used in the traditional sense of the word. 
It has nothing to do with the file type 'artifact'.
 
To view the feature table summary statistics, just run:

.. code-block:: bash

   qiime feature-table summarize \
     --i-table deblur/deblur-table.qza \
     --o-visualization deblur/deblur-table.qzv

   qiime tools view deblur/deblur-table.qzv


Particularly interesting is the `Interactive sample detail page`.
This shows you the number of features per sample.
If there is large variation in this number between samples, it means it is difficult to directly compare samples. In that case it is often recommended to standardize your data by for instance rarefaction.
Rarefaction will not be treated in detail in the tutorial, but the idea is laid out below.

.. note::

   Rarefaction in a nut shell: for each sample you only include as many features as you have available for the smallest sample.
   Which features those are is determined by chance (i.e. subsample the features without replacement). 
   If your smallest sample has very few features, you need to discard a lot of features from the other samples, which is of course a pity.
   In such situations it may be better to just exclude the small sample entirely.

Use the sample depth slider to see the effect of rarefying the data up to a minimum sampling depth.

.. admonition:: Question 7

   | What would be the rarefaction depth if your want to retain all your samples?
   | How many features (ASVs) would you discard at this rarefaction depth?
   | Is there a better option given the data? What would then be the consequence for the number of features and samples retained? 


Lastly, lets check out the representative sequences:

.. code-block:: bash

   qiime feature-table tabulate-seqs \
     --i-data deblur/deblur-reprseqs.qza \
     --o-visualization deblur/deblur-reprseqs.qzv

   qiime tools view deblur/deblur-reprseqs.qzv

In addition to some summary statistics, this vizualization allows you to BLAST each representative sequence against the NCBI nt database.
Just click on the sequence and then the View report button.

.. important::

   Results of the “top hits” from a simple BLAST search such as this are known to be poor predictors of the true taxonomic affiliations of these features, 
   especially in cases where the closest reference sequence in the database is not very similar to the sequence that you are using as a query.
   Instead, use automated taxonomic classification (see tutorial for tomorrow).

.. admonition:: Question 8

   What is the best BLAST hit for the most abundant feature in the data set?



DADA2 denoise
-------------------------------

The DADA2-denoiser can be run using a single command because joining and filtering will be done automatically.
However, you need to decide on two important parameter values: ``--p-trunc-len-f`` and ``--p-trunc-len-r``.

.. admonition:: Question 9

   Check out the ``qiime dada2 denoise-paired`` help function to find out what ``--p-trunc-len-f`` and ``--p-trunc-len-r`` are.
   Which of the previous vizualisations can help you decide on appropriate values for these parameters? 
   What do you think happens if you set these values at, say, 185 each?

Lets run dada2, note that I used 16 cpus, which you may have to tune down a bit.

.. code-block:: bash

   qiime dada2 denoise-paired \
     --i-demultiplexed-seqs prep/trimmed-seqs.qza \
     --p-trim-left-f 0 \
     --p-trim-left-r 0 \
     --p-trunc-len-f 230 \
     --p-trunc-len-r 220 \
     --p-n-threads 1 \
     --o-table dada2/dada2-table.qza \
     --o-representative-sequences dada2/dada2-reprseqs.qza \
     --o-denoising-stats dada2/dada2-stats.qza \
     --verbose

This will take some time, so lets keep it running and pick this up again this afternoon or tomorrow morning.
Then create some vizualisations:

.. code-block:: bash

   qiime metadata tabulate \
     --m-input-file dada2/dada2-stats.qza \
     --o-visualization dada2/dada2-stats.qzv

   qiime feature-table summarize \
     --i-table dada2/dada2-table.qza \
     --o-visualization dada2/dada2-table.qzv

   qiime feature-table tabulate-seqs \
     --i-data dada2/dada2-reprseqs.qza \
     --o-visualization dada2/dada2-reprseqs.qzv

View and compare these results to the ones obtained with deblur-denoise.

.. admonition:: Question 10

   What method yields most features?
   Which method would you choose to continue with?


