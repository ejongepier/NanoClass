.. NanoClass documentation master file, created by
   sphinx-quickstart on Thu Sep 24 16:24:49 2020.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

NanoClass
==================

NanoClass is a taxonomic meta-classifier for meta-barcoding sequencing data generated with the Oxford Nanopore Technology. 
With a single command, this Snakemake pipeline installs all programs and databases and runs and evaluates 10 popular taxonomic classification tools.

Quick start
-------------------

Simply clone NanoClass

.. code-block:: bash

   git clone https://github.com/ejongepier/NanoClass

Or download and extract the zip archive from https://github.com/ejongepier/NanoClass.

NanoClass is immediately ready for use.

Enter your samples and the paths to your fastq.gz files in the sample.csv. Sample labels should be unique. Both sample and run labels should contain letters and numbers only. 
Barcode column should be left empty for the time being, meaning your input files should already be demultiplexed. For an example see the sample.csv file.

The entire pipeline can be run with a single command:

.. code-block:: bash

   snakemake --use-conda --cores <ncores>

Where --cores are the number of CPU cores/jobs that can be run in parallel on your system.





Documentation
==================
.. toctree::
   :maxdepth: 2
   :caption: Contents:

   objectives
   getting_started
   typical_run
   databases.rst
   parameter_ref



Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
