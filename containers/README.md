# Build a MAPseq image

[MAPseq](https://github.com/jfmrod/MAPseq) is the only tool implemented in NanoClass that cannot be installed via conda.
To still include it in your analyses, I provide a Singularity recipe from which you can readily build a MAPseq image.
Singularity itself is part of the NanoClass/envs/NanoClass-env environment, which I assume you already created (see NanoClass/envs/README.md). 

Please note this is experimental and comes with no warranty!

Just navigate to the NanoClass directory, activate the NanoClass-env environment and build mapseq.simg, like so:

    conda activate ./envs/NanoClass-env
    sudo -E ./envs/NanoClass-env/bin/singularity build containers/mapseq.simg containers/Singularity-mapseq

This takes up 1.4G of disc space. Building the mapseq.simg may take a little while and results in lots of output which you can ignore.
NanoClass will then be able to run MAPseq as part of the regular pipeline, provided you use `--use-singularity`, like so:

    snakemake --use-singularity --use-conda --cores <ncores>

