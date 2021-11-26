#!/usr/bin/env bash

source ~/miniconda3/etc/profile.d/conda.sh
conda activate sphinx-new

##################
## REBUILD DOCS ##
##################

make clean
make github
cp -r source/_build/html/* ../docs/

################
## Update git ##
################

#git add .
#git commit -m "Updated index"
#git push -u origin main

