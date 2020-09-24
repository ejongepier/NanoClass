#to create containers from conda enviornments, first link or copy ../envs/*.yml here, make sure there is a name: <env name> line in the yml and build:
sudo singularity build R4.0.simg Singularity-R4.0

#to create container (simg) from singularity recipe, just:
sudo singularity build spingo.simg Singularity-spingo
sudo singularity build centrifuge.simg Singularity-centrifuge
sudo singularity build mapseq.simg Singularity-mapseq
sudo singularity build kraken.simg Singularity-kraken
sudo singularity build preprocess.simg Singularity-preprocess
sudo singularity build common.simg Singularity-common
