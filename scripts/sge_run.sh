#!/bin/bash
#$ -cwd

#$ -j yes
#$ -V
#$ -N sraFind
#$ -pe mpi 32
#$ -l h_vmem=1G

# source activate sraFind
cd ~/GitHub/sraFind/

# Rscript ./scripts/get_accs.R All ./output/ 32

parallel -j 32 --progress :::: ~/GitHub/sraFind/output/sraFind-fetch-cmds.txt
