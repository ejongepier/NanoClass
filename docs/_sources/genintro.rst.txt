General Introduction
######################################

This workshop will introduce you to analysis of DNA metabarcoding sequencing data using the command line tool QIIME2.
QIIME2™ is a next-generation microbiome bioinformatics platform that is extensible, free, open source, and community developed (`Bolyen et al. 2019 <https://pubmed.ncbi.nlm.nih.gov/31341288/>`_).


Objectives
===========================================

At the end of the two-day Metabarcoding - QIIME2 workshop, you are able to 

   1. **Perform quality control and produce an ASV abundance table from raw amplicon sequences.** These can be used for downstream analyses like community profiling or diversity analyses, although this is not part of the workshop.

   2. **Perform taxonomic classification and generate interactive** `taxonomic barplots <https://view.qiime2.org/visualization/?type=html&src=https%3A%2F%2Fdocs.qiime2.org%2F2020.6%2Fdata%2Ftutorials%2Fmoving-pictures%2Ftaxa-bar-plots.qzv>`_  **of bacterial and archeal communities** using the SILVA 16S database. These skills can be readily applied to other taxonomic groups such as animals, plants and fungi, using other marker genes and databases (e.g. 18S/SILVA, ITS/UNITE or CO1/BOLD).

   3. **Run these analyses on the Crunchomics cluster**\*, such that you have access to sufficient computational power to analyse your own amplicon sequencing data set.

\* *Only possible for participants from SILS or IBED that have access to the Crunchomics cluster.*



Time and place
===========================================

The workshop will be held through Zoom.
To join, just follow `this link <https://uva-live.zoom.us/j/85878918578>`_.

.. list-table:: Schedule QIIME2 workshop June 2021
   :widths: 25 25 50
   :header-rows: 1

   * - Day
     - Time
     - Topic
   * - Mon June 28th
     - 09:00 - 12:30
     - Quality control and ASV table construction
   * - 
     - 13:30 - 17:00
     - OPTIONAL: Running analyses on Crunchomics\* 
   * - Tue June 29th
     - 09:00 - 12:30
     - Taxonomic classification using the SILVA 16S database
   * -
     - 13:30 - 17:00
     - OPTIONAL: Running analyses on Crunchomics\*

\* *Only possible for participants from SILS or IBED that have access to the Crunchomics cluster.*


How to prepare?
===========================================

Install QIIME2 version 2021.2
---------------------------------------------

Please install QIIME2 version 2021.2 on your laptop or desktop computer following `these installation instructions <https://docs.qiime2.org/2021.2/install/native/>`_.
Windows users will first need to setup `Windows subsystem for Linux <https://docs.qiime2.org/2021.2/install/virtual/wsl/>`_.
This may take some time, so please do so well in advance.

.. note::

   QIIME2 version 2021.2 is not the latest version of QIIME2, but is is the version you will need for this workshop.
   The reason is that you may not be able to skip computationally intensive steps if you use a different version of QIIME2.



Familiarize yourself with UNIX
---------------------------------------------

The emphasis of this workshop lies on getting hands-on experience with data analyses.
No prior experience in bioinformatics is needed, but some basic knowledge of the UNIX operating system will come in handy.
Check out for instance `these tutorials <http://www.ee.surrey.ac.uk/Teaching/Unix/>`_ in preparation for the workshop, in particular Tutorial 
`1 <http://www.ee.surrey.ac.uk/Teaching/Unix/unix1.html>`_, 
`2 <http://www.ee.surrey.ac.uk/Teaching/Unix/unix2.html>`_ and 
`3 <http://www.ee.surrey.ac.uk/Teaching/Unix/unix3.html>`_.


OPTIONAL: Sign up for the Crunchomics cluster
-------------------------------------------------

`Crunchomics <https://crunchomics-documentation.readthedocs.io/en/latest/>`_ is the genomics compute environment for SILS and IBED.
It is only accessible for participants with an UvA netID that have pre-registered for an account. 
To register, please send an email including your UvA netID to the Crunchomics system administrator `Wim de Leeuw <mailto:w.c.deleeuw@uva.nl>`_.
Once you have an account you should `login to Crunchomics <https://crunchomics-documentation.readthedocs.io/en/latest/intro_crunchomics.html>`_ 
and `install miniconda <https://crunchomics-documentation.readthedocs.io/en/latest/miniconda.html>`_.


OPTIONAL: Become a member of the amplicomics group
-------------------------------------------------------

During the optional Crunchomics module (and afterwards when working on your own data), you can use pre-installed programs and databases available only to amplicomics group members.
To become a member, send an email including your UvA netID to `Evelien Jongepier <mailto:e.jongepier@uva.nl>`_. 

.. warning::

   Membership of the amplicomics group goes through the faculty ICTS department so may take several days to arrange.
   Please contact `Evelien Jongepier <mailto:e.jongepier@uva.nl>`_ well in advance if you like to participate in the optional Crunchomics module of the workshop.

