#!/bin/bash
set -euo pipefail
set -x
# make sure output dir variable is not empty or pointing to exsting dir
if [[ "$2" == "" ]]
then
    echo "empty"
fi

if [ -d "$2" ]
then
    echo "$2 already exists"
fi


mkdir $2

get_accs_dir=$2/get_accs/

case "$1" in
    All)
    # get complete and draft
	echo "all"
	Rscript scripts/get_accs.R $1 $get_accs_dir
	;;

    "Complete Genome")
	echo "comp"
	Rscript scripts/get_accs.R "Complete Genome" $get_accs_dir
	;;

    Chromosome)
	echo "chrom"
	Rscript scripts/get_accs.R $1 $get_accs_dir
	;;
    Scaffold)
	echo "scaf"
	Rscript scripts/get_accs.R $1 $get_accs_dir
	;;
    Config)
	echo "contig"
	Rscript scripts/get_accs.R $1 $get_accs_dir
	;;
    *)
	echo $"Usage: $0 {Chromosome|Complete Genome|Contig|Scaffold|All} output/dir/"
	exit 1

esac

echo "updating sraFind!"
echo "This could take a while, depending on your network speed. Coffee Time?"
