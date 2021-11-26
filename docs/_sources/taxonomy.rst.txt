Taxonomic classification
####################################


In this second part of the workshop we will continue with the taxonomic classification of the representative sequences from the DADA2-denoising performed yesterday.

QIIME 2 provides several methods to predict the most likely taxonomic affiliation of your features, including both alignment-based consensus methods and Naive Bayes (and other machine-learning) methods. 

Here, we will use a Naive Bayes classifier, which must be trained on taxonomically defined reference sequences covering the target region of interest.
This tutorial addresses the following questions: 

#. How to import the SILVA 16S rRNA taxonomic database as a reference in QIIME2?

#. How to extract the fragments from the SILVA reference sequences corresponding to the primers that were used?

#. How to train a custom classifier on these particular fragments of the 16S rRNA gene?

#. How to use the trained classifier to get a taxonomic classification of the representative sequences?

#. How to vizualise the taxonomic classification as interactive barplots?
 

.. warning::
  
   Training a classifier takes up quite a bit of RAM and time.
   Therefore, I have pre-computed the classifier for you.
   I recommend you just look through the next steps in the analyses without actually running them. 

See the QIIME2 `Training feature classifiers with q2-feature-classifier <https://docs.qiime2.org/2020.8/tutorials/feature-classifier/>`_ tutorial further information. 

Importing the database
==========================

Two elements are required for training the classifier: the reference sequences and the corresponding taxonomic classifications.
In the db directory of your data package, you will find these two files for the 16S rRNA SILVA data base release version 138, at 99% sequence similarity cutoff.
We can import these files into QIIME2 as artifacts, similar to how you imported data yesterday:

.. code-block:: bash

   qiime tools import \
     --type "FeatureData[Sequence]" \
     --input-path db/SILVA_138_99_16S-ref-seqs.fna \
     --output-path db/SILVA_138_99_16S-ref-seqs.qza
   
.. code-block:: bash

   qiime tools import \
     --type "FeatureData[Taxonomy]" \
     --input-format HeaderlessTSVTaxonomyFormat \
     --input-path db/SILVA_138_99_16S-ref-taxonomy.txt \
     --output-path db/SILVA_138_99_16S-ref-taxonomy.qza

Lets have a look at the first entry in the database, like so:

.. code-block:: bash

   head -2 db/SILVA_138_99_16S-ref-seqs.fna

Which gives the following output:

.. code-block:: bash

   >CP013078.2406498.2408039
   AGAGATTGAACTGAAGAGTTTGATCCTGGCTCAGATTGAACGCTGGCGGGATGCTTTACACATGCAAGTCGGACGGCAGCACGGGCTTCGGCCTGGTGGCGAGTGGCGAACGGGTGAGTAATGTATCGGAACGTGCCCAGTAGCGGGGGATAACTACGCGAAAGCGTGGCTAATACCGCATACGCCCTACGGGGGAAAGCGGGGGACCTTCGGGCCTCGCACTATTGGAGCGGCCGATATCGGATTAGCTAGTTGGTGGGGTAACGGCCTACCAAGGCGACGATCCGTAGCTGGTTTGAGAGGACGACCAGCCACACTGGGACTGAGACACGGCCCAGACTCCTACGGGAGGCAGCAGTGGGGAATTTTGGACAATGGGGGCAACCCTGATCCAGCCATCCCGCGTGTGCGATGAAGGCCTTCGGGTTGTAAAGCACTTTTGGCAGGAAAGAAACGGCACGGGCTAATATCCTGTGCAACTGACGGTACCTGCAGAATAAGCACCGGCTAACTACGTGCCAGCAGCCGCGGTAATACGTAGGGTGCAAGCGTTAATCGGAATTACTGGGCGTAAAGCGTGCGCAGGCGGTTCGGAAAGAAAGATGTGAAATCCCAGGGCTTAACCTTGGAACTGCATTTTTAACTACCGGGCTAGAGTGTGTCAGAGGGAGGTGGAATTCCGCGTGTAGCAGTGAAATGCGTAGATATGCGGAGGAACACCGATGGCGAAGGCAGCCTCCTGGGATAACACTGACGCTCATGCACGAAAGTGTGGGGAGCAAACAGGATTAGATACCCTGGTAGTCCACGCCCTAAACGATGTCAACTAGCTGTTGGGGCCTTCGGGCCTTGGTAGCGCAGCTAACGCGTGAAGTTGACCGCCTGGGGAGTACGGTCGCAAGATTAAAACTCAAAGGAATTGACGGGGACCCGCACAAGCGGTGGATGATGTGGATTAATTCGATGCAACGCGAAAAACCTTACCTACCCTTGACATGTCTGGAATCCCGAAGAGATTTGGGAGTGCTCGCAAGAGAACCGGAACACAGGTGCTGCATGGCTGTCGTCAGCTCGTGTCGTGAGATGTTGGGTTAAGTCCCGCAACGAGCGCAACCCTTGTCATTAGTTGCTACGAAAGGGCACTCTAATGAGACTGCCGGTGACAAACCGGAGGAAGGTGGGGATGACGTCAAGTCCTCATGGCCCTTATGGGTAGGGCTTCACACGTCATACAATGGTCGGGACAGAGGGTTGCCAACCCGCGAGGGGGAGCCAATCCCAGAAACCCGGTCGTAGTCCGGATCGCAGTCTGCAACTCGACTGCGTGAAGTCGGAATCGCTAGTAATCGCGGATCAGCATGTCGCGGTGAATACGTTCCCGGGTCTTGTACACACCGCCCGTCACACCATGGGAGTGGGTTTTACCAGAAGTAGTTAGCCTAACCGCAAGGGGGGCGATTACCACGGTAGGATTCATGACTGGGGTGAAGTCGTAACAAGGTAGCCGTATCGGAAGGTGCGGCTGGATCACCTCCTTTAAGA
   
Lets also check the associated 7-level taxonomy for this database entry:

.. code-block:: bash

   grep CP013078.2406498.2408039 db/SILVA_138_99_16S-ref-taxonomy.txt

And the output:

.. code-block:: bash

   CP013078.2406498.2408039	D_0__Bacteria;D_1__Proteobacteria;D_2__Gammaproteobacteria;D_3__Burkholderiales;D_4__Alcaligenaceae;D_5__Bordetella;D_6__Bordetella pertussis


.. admonition:: Question 11

   How long was the target sequence again? How does that compare the the sequence length in the SILVA database?
   What are two major disadvantages of using full length 16S rRNA gene in your taxonomic classification?


Extract reference reads
===========================

The 16S rRNA gene is characterized by both hyper variable and very conserved regions.
Taxonomic classification accuracy of 16S rRNA gene sequences improves when a Naive Bayes classifier is trained 
on only the region of the target sequences that was sequenced 
(`Werner et al. 2012 <https://pubmed.ncbi.nlm.nih.gov/21716311/>`_). 

From the trimming step yesterday, we know which primer sequences were used.
We can now use these same sequences to extract the corresponding region of the 16S rRNA sequences from the SILVA database, like so:

Note, this takes a while even using 16 cpus like I did.

.. code-block:: bash

   qiime feature-classifier extract-reads \
     --i-sequences db/SILVA_138_99_16S-ref-seqs.qza \
     --p-f-primer GTGYCAGCMGCCGCGGTAA \
     --p-r-primer CCGYCAATTYMTTTRAGTTT \
     --o-reads db/SILVA_138_99_16S-ref-frags.qza \
     --p-n-jobs 16

Lets have a look at the result:

.. code-block:: bash

   qiime feature-table tabulate-seqs \
     --i-data db/SILVA_138_99_16S-ref-frags.qza \
     --o-visualization db/SILVA_138_99_16S-ref-frags.qzv

   qiime tools view db/SILVA_138_99_16S-ref-frags.qzv

.. admonition:: Question 12

   How does the sequence length distribution of the reference fragments compare to that of the representative sequences?


Train the classifier
=====================

In this step we use the reference fragments you just created to train your classifier specifically on your region of interest.

.. warning::

   You should only run this step if you have >32GB of RAM available!

.. code-block:: bash

   qiime feature-classifier fit-classifier-naive-bayes \
     --i-reference-reads db/SILVA_138_99_16S-ref-frags.qza \
     --i-reference-taxonomy db/SILVA_138_99_16S-ref-taxonomy.qza \
     --o-classifier db/SILVA_138_99_16S-ref-classifier.qza


Please note that this classifier is not very specific with respect to which environment the samples come from,
because it assumes that all species in the reference database are equally likely to be observed in your samples 
(i.e., that sea-floor microbes are just as likely to be found in a stool sample as microbes usually associated with stool).

It is actually possible to incorporate environment-specific taxonomic abundance information to improve species inference. 
This bespoke method has been shown to improve classification accuracy when compared to traditional Naive Bayes classifiers 
(`Kaehler et al. 2019 <https://www.nature.com/articles/s41467-019-12669-6>`_).

To train a classifier using this bespoke method, we need to provide an additional file with taxonomic weigths
(see ``--i-class-weight`` in the ``qiime feature-classifier fit-classifier-naive-bayes`` help function)
Pre-assembled taxonomic weights can be found in the readytowear collection at https://github.com/BenKaehler/readytowear.
I cannot judge how well they fit your particular environment, so be very, very careful in using them unless you know what you are doing. 

Here, we will continue with the 'naive' Naive Bayes classifier we just created.

Taxonomic classification
==========================

So now we have a trained classifier and a set of representative sequences from your DADA2-denoise analyses.
Lets run it and find out which microbes were present in your samples.

.. warning::

   I ran this step on a computational cluster because it requires ~50 GB of RAM.
   Don't run this yourself unless you have lots of RAM on your system.

 
.. code-block:: bash

   qiime feature-classifier classify-sklearn \
     --i-classifier db/SILVA_138_99_16S-ref-classifier.qza \
     --p-n-jobs 16 \
     --i-reads dada2/dada2-reprseqs.qza \
     --o-classification taxonomy/dada2-SILVA_138_99_16S-taxonomy.qza

You can view the taxonomic annotation of each of the representative sequences like so:

.. code-block:: bash

   qiime metadata tabulate \
    --m-input-file taxonomy/dada2-SILVA_138_99_16S-taxonomy.qza \
    --o-visualization taxonomy/dada2-SILVA_138_99_16S-taxonomy.qzv

   qiime2 tools view taxonomy/dada2-SILVA_138_99_16S-taxonomy.qzv


Note that this also reports a confidence score ranging between 0.7 and 1.
The lower limit of 0.7 is the default value (see also the ``qiime feature-classifier classify-sklearn`` help function).
You can opt for a lower value to increase the number of features with a classification, but beware that that will also increase the risk of spurious classifcations!


Taxonomic barplot
=====================

In this final step we will create an interactive barplot, showing the relative abundances at different taxonomic levels for each of the samples.
Before running the command, we will need to prepair a metadata file.
This metadata file should contain information on the samples. For instance, at which depth was the sample taken, 
from which location does it come, was it subjected to experimental or control treatment etc. etc.
This information is of course very specific to the study design but at the very least it should look like this (see also ``data/META.tsv``):

.. code-block:: bash

   #SampleID
   #q2:types
   DUMMY1
   DUMMY10
   ...

but we can add any variables, like so:

.. code-block:: bash

   #SampleID    BarcodeSequence Location        depth	location	treatment	grainsize       flowrate        age
   #q2:types    categorical     categorical     categorical	catechorical	categorical	numeric	numeric	numeric
   <your data>

See the `Metadata in QIIME 2 <https://docs.qiime2.org/2020.8/tutorials/metadata/>`_ tutorial for further information.

I created a minimal example for your data here ``data/META.tsv``
Just complement it with the specific variables of your study or continue with this minimal example.
Then create and view the barplot vizualisation, like so:

.. code-block:: bash

   qiime taxa barplot \
     --i-table dada2/dada2-table.qza \
     --i-taxonomy taxonomy/dada2-SILVA_138_99_16S-taxonomy.qza \
     --m-metadata-file data/META.tsv \
     --o-visualization taxonomy/dada2-SILVA_138_99_16S-taxplot.qzv

   qiime tools view taxonomy/dada2-SILVA_138_99_16S-taxplot.qzv


.. admonition:: Question 13

   Which family is the most abundant in your samples, and which class?
   Can you see clear differences in relative abundances between your treatment/sample location/depth/...?
   ... <here is where you get to add your own questions>


Now that we have come to the end of this workshop, lets have a final look at the
metadata for the taxonomy analyses. Just go to https://view.qiime2.org/
and load your `artifact` taxonomy/dada2-SILVA_138_99_16S-taxonomy.qza.

  





