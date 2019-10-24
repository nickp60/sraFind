#!/bin/bash
 echo "counting raw hits"
nrawfiles=$(find ./output/ncbi_dump/ -type f | wc -l)
echo "raw hits processed: $nrawfiles; deleting empty files"
find ./output/ncbi_dump/ -empty -delete
nfiles=$(find ./output/ncbi_dump/  | wc -l)
echo "non-empty files in output/ncbi_dump: $nfiles"
echo "copying results for archive"
rsync --info=progress2 -a  output/ncbi_dump/ output/ncbi_dump_clean/

echo "removing old tar"
rm ./compressed_ncbi_dump.tar.gz 
echo "creating new tar"
tar czf ./compressed_ncbi_dump.tar.gz ./output/ncbi_dump_clean/
git add ./compressed_ncbi_dump.tar.gz
echo "Dump contains total of $nfiles files from $nrawfiles searches"
git commit -m "Dump contains total of $nfiles files from $nrawfiles searches"

