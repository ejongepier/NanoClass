# conda create -n R-4.0-conda-only r-essentials r-base
# conda activate R-4.0-conda-only
# conda install -y -c conda-forge r=4.0
# conda install -y -c bioconda bioconductor-dada2 r-seqinr bioconductor-phyloseq
# conda install -y -c r r-ggplot2
# conda install -y -c bioconda bioconductor-decipher
# conda install -y -c conda-forge r-vroom


## create conda environment.yaml with the two NanoClass dependencies: snakemake and singularity
#conda create -y --prefix envs/snakemake-env2
#conda activate /project/202005_minion_16s_peterkuperus/20200820_mock-caulerpa-smk/run-20200914/envs/snakemake-env2
#conda install -y -c conda-forge singularity
#conda install -y -c conda-forge mamba
#conda install -y -c conda-forge -c bioconda snakemake
#conda env export -p /project/202005_minion_16s_peterkuperus/20200820_mock-caulerpa-smk/run-20200914/envs/smk-env > envs/smk-env.yml

## build conda environment with the two NanoClass dependencies: snakemake and singularity
conda env create -f ./envs/smk-env.yml -p ./envs/smk-env
conda activate ./envs/smk-env
