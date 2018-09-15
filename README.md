# sraFind

sraFind is a tool to gauge the completeness of assembly and availaility of raw data from prokaryotic genomes.

In short it uses a list of biosample accessions from NCBI's `prokaryotes.txt` file that it perioidcally updates to run a whole bunch of entrez edirect searches, downloading the xml for hits where a link is found between the biosample and the SRA database.

We chose to include the results in the repo to allow for quicker rerunning. No empty files are commited, so it is important to run the following command prior to committing.  This is to avoid false negatives where a link may exist but was not downloaded due to network connectivity, etc.

```
find ./output/ncbi_dump/ -empty -type f -delete
```

# dependencies

- GNU parallel
- NCBI's entrez direct
- R

# Executing
## Fetching the Data
The main script for fetching data is `./scripts/get_accs.R`, which:

- orchestrates the downloading of a `prokaryotes.txt` file, if one is not found in the current working directory
- filtering by genome completeness
- writing out a file of all the commands to run
- calling those commands in parallel
- calling the commands to parse the hits
- merging together runs with multiple datasets
- saving the output

```
#$
#    USAGE: Rscript get_accs.R <"Chromosome|Complete Genome|Contig|Scaffold|All> output/dir/ n_cores_to_use
Rscript scripts/get_accs.R All ./output/ 16

```

## Plotting the data
Who are we kidding, you're probably not going to use /my/ plotting scripts are you?






# Caveats

Don't put too much faith in the nuccore first chromosome columns. This is created with a bunch of regexes of the "replicon" column, which is filled with bad metadata. This also ignores the genomes in the list where the chromosome is categorized as a plasmid; there are about 100 of these that list no chromosome, but a megabase-scale plasmid. If someone couldn't get that bit of metadata sorted out, I am hesitent to trust their sequence...
