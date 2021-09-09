#!/bin/bash

#SBATCH --job-name=nanoclass
#SBATCH --output=cluster/%x-%u-%A-%a.log
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=%u@uva.nl
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --time=120


start=`date "+%s"`
echo "$SLURM_JOB_NAME started at `date` on node $SLURM_NODEID using $SLURM_CPUS_ON_NODE cpus."


## Make sure to use programs on the amplicomics group share
export PATH=/zfs/omics/projects/amplicomics/miniconda3/bin/:$PATH
source /zfs/omics/projects/amplicomics/miniconda3/etc/profile.d/conda.sh
conda activate snakemake-ampl


## Run nanoclass
cmd="srun --cores $SLURM_CPUS_ON_NODE snakemake --use-conda --cores $SLURM_CPUS_ON_NODE"
echo "Running: $cmd"
eval $cmd


end=`date "+%s"`
runtime=$((end-start))
echo "$SLURM_JOB_NAME finished at `date` in $runtime seconds."




