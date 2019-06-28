#!/bin/bash

echo "raw hits processed: `ls output/ncbi_dump/ | wc -l`"
echo "copying results for archive"
cp -r  output/ncbi_dump/ output/ncbi_dump_clean/
echo "removing empty files"
find ./output/ncbi_dump_clean/ -empty -type f -delete
nfiles=$(ls output/ncbi_dump_clean/ | wc -l)
echo "non-empty files in output/ncbi_dump: $nfiles"

echo "removing old tar"
rm ./compressed_ncbi_dump.tar.gz
echo "creating new tar"
tar czf ./compressed_ncbi_dump.tar.gz ./output/ncbi_dump_clean/
git add ./compressed_ncbi_dump.tar.gz
git commit -m "total of $nfiles files in dump"

