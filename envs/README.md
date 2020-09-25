# Create a NanoClass environment

Apart from [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/linux.html), NanoClass has two dependencies: 
[Snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) and 
[Singularity](https://singularity.lbl.gov/).

You can choose to install them yourself, or simply use the NanoClass/envs/smk-env provided here.

To create the environment (you only have to do this once), navigate to the NanoClass directory and run:
 
    conda env create -f ./envs/smk-env.yml -p ./envs/smk-env

Every time you want to run NanoClass, make sure to activate the environment, like so:

    conda activate ./envs/smk-env

All other environment.yml files in this directory are automatically deployed when running NanoClass. 

#### Authors

Evelien Jongepier (e.jongepier@uva.nl)

