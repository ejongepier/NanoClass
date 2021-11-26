Getting Started
===============

NanoClass can be run on a powerfull desktop computer.
Most classification tools implemented in NanoClass will run in a matter of minutes to hours. 

The only requirements are the package manager Conda and workflow management system Snakemake. 
If you already have these installed, you can skipp the next sections and move directly to the NanoClass installation.



Install Conda
----------------------

Detailed installation instructions for Conda can be found `here <https://docs.conda.io/projects/conda/en/latest/user-guide/install/>`_.
On Linux, you can download and install miniconda3, like so:

.. code-block:: bash

  cd && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
  bash Miniconda3-latest-Linux-x86_64.sh && rm Miniconda3-latest-Linux-x86_64.sh

The installation manager will ask you a few questions which you can answer with "yes".
When finished, you prompt should start with `(base)`, if not just run

.. code-block:: bash

  source ~/.bashrc

and update conda:

.. code-block:: bash

  conda update -y conda



Install Snakemake
----------------------

Snakemake can be installed via Conda (see also `this link <https://snakemake.readthedocs.io/en/stable/getting_started/installation.html>`_).
Because the default Conda solver is a bit slow, Mamba is recommended as a drop-in replacement, like so:

.. code-block:: bash

  conda install -c conda-forge mamba
  mamba create -c conda-forge -c bioconda -n snakemake snakemake=6.8.0



Install NanoClass
------------------------

You can either clone NanoClass, like so:

.. code-block:: bash

   git clone https://github.com/ejongepier/NanoClass

or download and extract the zip archive from https://github.com/ejongepier/NanoClass.

NanoClass is immediately ready for use.
