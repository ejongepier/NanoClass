Metabarcoding analyses on Crunchomics
################################################

This tutorial will walk you though ASV abundance table construction and taxonomic classification using QIIME2 on the Crunchomics cluster.
It only contains information relevant for cluster usage. For detailed desciption of the workflow see the previous tutorials.


Some preparatory steps
=============================================

Before getting started, lets collect the data. 
There is a copy on the amplicomics group share which you can use, for instance by creating a link to your current directory on the Crunchomics cluster, like so:

.. code-block:: bash

   ln -s /zfs/omics/projects/amplicomics/demodata/metabarcoding-qiime2-datapackage-v2021.06/data ./


Setup your environment
---------------------------------------------

As an amplicomics group member, you can use the existing QIIME2 version 2021.2 installation.
Make sure your ``~/.condarc`` contains the path to the miniconda environments on the amplicomics project space and activate the QIIME2 environment, like so:

.. code-block:: bash

   conda config --add envs_dirs /zfs/omics/projects/amplicomics/miniconda3/envs/
   conda activate qiime2-2021.2


Define global variables
---------------------------------------------

Lets define some variables upfront such that we can easily reuse the rest of the script when parameter values change.
We define them as global variables using ``export`` to make sure they are defined also when we send certain jobs to the Slurm cluster management and job scheduling system.

First define the path to the MANIFEST and META file. Note that the MANIFEST file contains paths to the actual input fastq.gz data, so we do not need to define those here.

.. code-block:: bash

   export MANIFEST="data/MANIFEST.csv"
   export META="data/META.tsv"

Now the primer sequences that were used, which we will use for primer trimming as well as for extracting fragments of the reference database.
Defining the here makes it easier to use re-use your script when you use other primers.

.. code-block:: bash

   export PRIMFWD="GTGYCAGCMGCCGCGGTAA"
   export PRIMREV="CCGYCAATTYMTTTRAGTTT"


The trim and trunk lengths used by deblur-denoise and DADA2-denoise:

.. code-block:: bash

   export TRIMLENG=370
   export TRUNKFWD=230
   export TRUNKREV=220

And finally the path to the SILVA database on the amplicomics group share. There is no need for each user to have a private copy of common databases, which is why it is better to share these.
If you like to add another database or a new release, just contact `Evelien Jongepier <mailto:e.jongepier@uva.nl>`_. 
 
.. code-block:: bash

   export DBSEQ="/zfs/omics/projects/amplicomics/databases/SILVA/SILVA_138_QIIME/data/silva-138-99-seqs.qza"
   export DBTAX="/zfs/omics/projects/amplicomics/databases/SILVA/SILVA_138_QIIME/data/silva-138-99-tax.qza"
   export DBPREFIX="SILVA_138_99_16S"

Now that we have defined all these variables, we can simply refer to them using the $ notation. To print the value of DBPREFIX:

.. code-block:: bash

   echo $DBPREFIX
 

Setup your working directory
---------------------------------------------

Now, lets create the directories where your results are written to. Make sure you are in the same directory where the "data" subdirectory is.

.. code-block:: bash

   mkdir -p logs
   mkdir -p prep
   mkdir -p deblur
   mkdir -p dada2
   mkdir -p db
   mkdir -p taxonomy



Importing data
===================================================

Lets submit the following ``qiime tools import``-command to Slurm, using the ``srun``-command.
``n`` and ``cpus-per-task`` are ``srun`` parameters that define what resources you require.
Here, your specify your job consists of 1 task (``-n``) that needs to be run on 1 cpu (``--cpus-per-task``).
For more ``srun`` parameters and options check out the help function (``srun --help``) or the manual (``man srun``).

.. code-block:: bash

   srun -n 1 --cpus-per-task 1 qiime tools import \
     --type 'SampleData[PairedEndSequencesWithQuality]' \
     --input-path $MANIFEST \
     --input-format PairedEndFastqManifestPhred33 \
     --output-path prep/demux-seqs.qza


When running such a ``srun``-command, 3 things will happen:

   1. The job scheduler adds your job to the queue.

   2. Once the requested resources are found (here, 1 cpu), they will be allocated to your job.

   3. Once the resources are allocated, your job will start.

Now, let create the vizualisation:

.. code-block:: bash

   srun -n 1 --cpus-per-task 1 qiime demux summarize \
     --i-data prep/demux-seqs.qza \
     --o-visualization prep/demux-seqs.qzv

Viewing vizualisations can better be done on your local laptop or computer.
The following command gives you instructions how to do that.

.. code-block:: bash

   how-to-view-this-qzv prep/demux-seqs.qzv


Primer removal
===================================================

Using 2 cpus, this takes ca. 3m26.193s. On a larger data set you may want to use more ``cpus-per-task``.
Of course you need to increase the number of cpus by changing both the ``cpus-per-task`` parameter of the
``srun``-command and the ``p-cores`` parameter of the ``qiime cutadapt trim-paired``-command. The reason is that
``cpus-per-task`` merely specifies the number of cores you reserve for this job, while ``p-cores`` defines how many are actually used.
The latter may be differently defined, depending on which command you run. Check out the help functions to find out more.

.. code-block:: bash

   srun -n 1 --cpus-per-task 2 qiime cutadapt trim-paired \
     --i-demultiplexed-sequences prep/demux-seqs.qza \
     --p-front-f $PRIMFWD \
     --p-front-r $PRIMREV \
     --p-error-rate 0 \
     --o-trimmed-sequences prep/trimmed-seqs.qza \
     --p-cores 2 \
     --verbose \
     2>&1 | tee logs/qiime-cutadapt-trim-paired.log

   srun -n 1 --cpus-per-task 1 qiime demux summarize \
     --i-data prep/trimmed-seqs.qza \
     --o-visualization prep/trimmed-seqs.qzv

This last task typically takes only a few seconds, so it can also be run on the head node of Crunchomics (i.e. no need to submit to Slurm).
For the rest of this workflow, we will not use ``srun`` for these quick jobs anymore because resource allocation takes a disproportionate amount of time.
Please mind though that to avoid overloading the head node you should never run larger jobs there.

And again check out instructions how to transfer and view the vizualisation:

.. code-block:: bash

   how-to-view-this-qzv prep/trimmed-seqs.qzv


Feature table construction
=============================================

Deblur denoise
---------------------------------------------

Step 1. Joining read pairs
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Using 2 cpus, this takes ca. 3m1.940s. On a larger data set you may want to use more ``cpus-per-task``.
Note that for the ``qiime cutadapt trim-paired``-command you used ``p-cores`` while here you need ``p-threads``.
Pretty annoying that this is not consistent, but that simply is the way the developers defined their parameters
which often differs. Check-out the help function of the command you like to run to learn more.

.. code-block:: bash

   srun -n 1 --cpus-per-task 2 qiime vsearch join-pairs \
     --i-demultiplexed-seqs prep/trimmed-seqs.qza \
     --o-joined-sequences deblur/joined-seqs.qza \
     --p-threads 2 \
     --verbose \
     2>&1 | tee logs/qiime-vsearch-join-pairs.log

   qiime demux summarize \
     --i-data deblur/joined-seqs.qza \
     --o-visualization deblur/joined-seqs.qzv

   how-to-view-this-qzv deblur/joined-seqs.qzv



Step 2. Quality filter
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This task takes ca. 9m15.097s but cannot be sped up because the ``qiime quality-filter q-score``-command
does not have an option to use multiple cpus (see ``qiime quality-filter q-score --help``).

.. code-block:: bash

   srun -n 1 --cpus-per-task 1 qiime quality-filter q-score \
     --i-demux deblur/joined-seqs.qza \
     --o-filtered-sequences deblur/filt-seqs.qza \
     --o-filter-stats deblur/filt-stats.qza \
     --verbose \
     2>&1 | tee logs/qiime-quality-filter-q-score.log

You can ignore the ``YAMLLoadWarning``.

.. code-block:: bash

   qiime demux summarize \
     --i-data deblur/filt-seqs.qza \
     --o-visualization deblur/filt-seqs.qzv

   qiime metadata tabulate \
     --m-input-file deblur/filt-stats.qza \
     --o-visualization deblur/filt-stats.qzv

   how-to-view-this-qzv deblur/filt-seqs.qzv
   how-to-view-this-qzv deblur/filt-stats.qzv


Step 3. Denoise
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

With 8 cpus the following takes ca. 6m56.972s. You may want to increase the no. cpus on larger data sets.
Also note I now explicitely defined a memory allocation of 16GB. This is the total amount of RAM
you expect to need for this job (+ a bit more to be on the safe side). How much you need is not
always easy to predict and requires some experience/trial and error.
As a rule of thumb: if you get an ``Out Of Memory`` error, double it and try again.
Note that you can also define ``mem-per-cpu``, which may be easier to work with if you often change the
number of cpus between analyses.

.. code-block:: bash

   srun -n 1 --cpus-per-task 8 --mem=16GB qiime deblur denoise-16S \
     --i-demultiplexed-seqs deblur/filt-seqs.qza \
     --p-trim-length $TRIMLENG \
     --o-representative-sequences deblur/deblur-reprseqs.qza \
     --o-table deblur/deblur-table.qza \
     --p-sample-stats \
     --o-stats deblur/deblur-stats.qza \
     --p-jobs-to-start 8 \
     --verbose \
     2>&1 | tee logs/qiime-deblur-denoise-16S.log

   cat deblur.log >> logs/qiime_deblur_denoise-16S.log && rm deblur.log

   qiime deblur visualize-stats \
     --i-deblur-stats deblur/deblur-stats.qza \
     --o-visualization deblur/deblur-stats.qzv

   qiime feature-table summarize \
     --i-table deblur/deblur-table.qza \
     --o-visualization deblur/deblur-table.qzv

   qiime feature-table tabulate-seqs \
     --i-data deblur/deblur-reprseqs.qza \
     --o-visualization deblur/deblur-reprseqs.qzv

   how-to-view-this-qzv deblur/deblur-stats.qzv
   how-to-view-this-qzv deblur/deblur-table.qzv
   how-to-view-this-qzv deblur/deblur-reprseqs.qzv


DADA2-denoise
--------------------------------------------

DADA2 performs filtering, joining and denoising all with one single command, and therefor takes longer to run.
Here, it takes ca. 30m5.334s using 8 cpus. It is tempting to just increase the number of cpus when impatient,
but please note that not all commands are very efficient at running more jobs in parallel (i.e. on multiple cpus).
The reason often is that the rate-limiting step in the workflow is unable to use multiple cpus, so all but one are idle.

To make responsable use of the cluster, it is always good to keep an eye on how well runtime scales with ``cpus-per-task``.
You can easily time any command using the ``time``-command, like so:

.. code-block:: bash

   time srun -n 1 --cpus-per-task 8 --mem=32GB qiime dada2 denoise-paired \
     --i-demultiplexed-seqs prep/trimmed-seqs.qza \
     --p-trunc-len-f $TRUNKFWD \
     --p-trunc-len-r $TRUNKREV \
     --p-n-threads 8 \
     --o-table dada2/dada2-table.qza \
     --o-representative-sequences dada2/dada2-reprseqs.qza \
     --o-denoising-stats dada2/dada2-stats.qza \
     --verbose \
     2>&1 | tee logs/qiime-dada2-denoise-paired.log

   qiime metadata tabulate \
     --m-input-file dada2/dada2-stats.qza \
     --o-visualization dada2/dada2-stats.qzv

   qiime feature-table summarize \
     --i-table dada2/dada2-table.qza \
     --o-visualization dada2/dada2-table.qzv

   qiime feature-table tabulate-seqs \
     --i-data dada2/dada2-reprseqs.qza \
     --o-visualization dada2/dada2-reprseqs.qzv

   how-to-view-this-qzv dada2/dada2-stats.qzv
   how-to-view-this-qzv dada2/dada2-table.qzv
   how-to-view-this-qzv dada2/dada2-reprseqs.qzv


Taxonomic classification
===================================================

Extract reference reads
---------------------------------------------------

This takes ca. 6m20.559s on 8 cpus.

.. code-block:: bash

   time srun -n 1 --cpus-per-task 8 --mem=4GB qiime feature-classifier extract-reads \
     --i-sequences $DBSEQ \
     --p-f-primer $PRIMFWD \
     --p-r-primer $PRIMREV \
     --o-reads db/$DBPREFIX-ref-frags.qza \
     --p-n-jobs 8 \
     --verbose \
     2>&1 | tee logs/qiime-feature-classifier-extract-reads.log


Train the classifier
---------------------------------------------------

Training a classifier takes quite some time, especially because the ``qiime feature-classifier fit-classifier-naive-bayes``-
command cannot use multiple cpus in parallel (see ``qiime feature-classifier fit-classifier-naive-bayes --help``).
Here, it took ca. 145m56.836s. You can however often re-use your classifier, provided you used the same primers and db.

.. code-block:: bash

   time srun -n 1 --cpus-per-task 1 --mem=32GB qiime feature-classifier fit-classifier-naive-bayes \
     --i-reference-reads db/$DBPREFIX-ref-frags.qza \
     --i-reference-taxonomy $DBTAX \
     --o-classifier db/$DBPREFIX-ref-classifier.qza \
     --p-verbose \
     2>&1 | tee logs/qiime-feature-classifier-extract-reads.log



Taxonomic classification
---------------------------------------------------

The classifier takes up quite some disc space. If you 'just' run it you are likely to get a
``No space left on device``-error. You can avoid this by changing the directory where temporary
files are written to, but make sure you have sufficient space there as well of course.

Lets create a temporary directory in my current working directory called 'tmptmp'.
Then export this as ``TMPDIR``, which qiime will automatically recognize and use as the temporary directory.

.. code-block:: bash

   mkdir -p tmptmp
   export TMPDIR=$PWD/tmptmp/

You need quite a lot of RAM to run the classifier. Note that this means that is many of us do this in parallel,
you may end up in the queue. This took 14m13.817s to run:

.. code-block:: bash

   time srun -n 1 --cpus-per-task 32 --mem=160GB qiime feature-classifier classify-sklearn \
     --i-classifier db/$DBPREFIX-ref-classifier.qza \
     --i-reads dada2/dada2-reprseqs.qza \
     --o-classification taxonomy/dada2-$DBPREFIX-taxonomy.qza \
     --p-n-jobs 16 \
     --verbose \
     2>&1 | tee logs/qiime-feature-classifier-classify-sklearn.log

   rm -fr tmptmp ## clean up afterwards

   qiime metadata tabulate \
     --m-input-file taxonomy/dada2-$DBPREFIX-taxonomy.qza \
     --o-visualization taxonomy/dada2-$DBPREFIX-taxonomy.qzv

Taxonomic barplot
---------------------------------------------------

.. code-block:: bash

   qiime taxa barplot \
     --i-table dada2/dada2-table.qza \
     --i-taxonomy taxonomy/dada2-$DBPREFIX-taxonomy.qza \
     --m-metadata-file $META \
     --o-visualization taxonomy/dada2-$DBPREFIX-taxplot.qzv





