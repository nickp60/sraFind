#!/bin/bash
 echo "counting raw hits"
nrawfiles=$(find ./output/ncbi_dump/ -type d | wc -l)
echo "raw hits processed: $nrawfiles"
echo "copying results for archive"
rsync --info=progress2 -a --prune-empty-dirs  output/ncbi_dump/ output/ncbi_dump_clean/
echo "removing empty files and directories"
find ./output/ncbi_dump_clean/ -empty -type f -delete
nfiles=$(find ./output/ncbi_dump_clean/ -type f -name "SAM*" | wc -l)
echo "non-empty files in output/ncbi_dump: $nfiles"

echo "removing old tar"
rm ./compressed_ncbi_dump.tar.gz
echo "creating new tar"
tar czf ./compressed_ncbi_dump.tar.gz ./output/ncbi_dump_clean/
git add ./compressed_ncbi_dump.tar.gz
echo "Dump contains total of $nfiles files from $nrawfiles searches"
git commit -m "Dump contains total of $nfiles files from $nrawfiles searches"

