Getting started
###########################################


The data package
===========================================

You can download the data package used in this workshop from `Zenodo <https://zenodo.org/record/5025210#.YNResHUzZhE>`_, Please select versie 2021.06.2.
This data package contains the following:

* Raw sequencing data with quality scores as demultiplexed fastq.gz files.
* The SILVA 16S taxonomic database version 138.
* The taxonomic classifier, specifically pre-trained to use on this data set.
* All intermediate results, such that you can choose to skip very time consuming steps.


Windows subsystem for Linux - users
===========================================
   
In order to access the data package from within your Linux file system, copy your data package to your Linux home​.
Where is your Linux home?
In your Terminal, enter the following to view the current directory in Windows File Explorer​

.. code-block:: bash

   cd ~
   explorer.exe . ## don't forget the dot

How to use this tutorial?
===========================================

Where to start
-------------------------------------------
Assuming the data package archive (metabarcoding-qiime2-datapackage-v2021.06.2.tar.gz) is in your home directory, 
extract it and navigate into the metabarcoding-qiime2-datapackage-v2021.06.2 directory, like so:

.. code-block:: bash

   cd ~
   tar -xzvf metabarcoding-qiime2-datapackage-v2021.06.2.tar.gz
   cd metabarcoding-qiime2-datapackage-v2021.06.2
   ls

The last command shows you which files and subdirectories are in your current directory.
If it looks like this you are golden:

.. code-block:: bash

   dada2  data  db  deblur  exports  logs  prep  README.txt  taxonomy  WALKTHROUGH.sh


.. important::

   For the remainder of the tutorial, make sure you always run the commands from the metabarcoding-qiime2-datapackage-v2021.06.2 directory, otherwise you will get a ``No such file or directory`` error.

Activating your conda environment
-------------------------------------------
If you installed QIIME2 following the instruction in the General Information, all QIIME2 tools are inside a dedicated conda environment called qiime2-2021.2.
As long as you are outside this environment, you will not be able to use the QIIME2 commands. 
Before starting a session, make sure to activate the qiime2-2021.2 environment. 
You will know whether you are in the correct environment if your prompt starts with ``(qiime2-2021.2)``.

.. important::

   Before starting your analyses activate your conda environment:
   ``conda activate qiime2-2021.2``


Skipping steps
-------------------------------------------
It is not necessary for this workshop to have a very powerful computer.
You can run most of the analyses on a laptop, and if that does not work, 
you can skip that step and continue with the intermediate files in your data package.

.. tip::

   When you follow the steps in this tutorial, you will overwrite the pre-computed intermediate files present in your data package.
   Make sure to keep a copy of the original data package, such that you can always restore these pre-computed files when needed.


