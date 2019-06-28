#!/bin/bash
#$ -cwd
#$ -j yes
#$ -V
#$ -N sraFind
#$ -pe mpi 4
#$ -l h_vmem=1G

# source activate sraFind
#cd ~/GitHub/sraFind/
#Rscript ./scripts/get_accs.R ./output/
NCBI_API_KEY="faa98b27e18f68ed1375e4514ac0ebe56d08"
parallel -j 4 --progress :::: ~/GitHub/sraFind/output/sraFind-fetch-cmds.txt
