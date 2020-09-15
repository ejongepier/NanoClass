#to create containers (sif) from conda enviornments, first link or copy ../envs/*.yml here, make sure there is a name: <env name> line in the yml and build:
sudo singularity build conda-R4.0.sif Singularity-R4.0

#to create container (simg) from singularity recipe, just:
sudo singularity build minion-16S-20200831.simg Singularity-main

#to create container from docker site:
#sudo singularity build conda-qiime_2.sif docker://qiime2/core:2020.8
#sudo singularity build conda-mothur_2.sif docker://biocontainers/mothur:v1.41.21-1-deb_cv1
