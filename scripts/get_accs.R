args = commandArgs(T)

# test args
# args=c("./tmp5/")
# setwd("~/GitHub/sraFind")

print('USAGE: Rscript get_accs.R  /path/to/output/dir/')
if (length(args) != 1)  stop('USAGE: Rscript get_accs.R  /path/to/output/dir/')
if (!dir.exists(args[1])) dir.create(args[1])

destfile="prokaryotes.txt"
if(!file.exists(destfile)){
  print("Downloading GENOME REPOSRT's prokaryotes.txt")
  system("wget ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt")
}

print("Reading prokaryotes.txt ")
raw <- read.csv(destfile, header=T, sep="\t", stringsAsFactors=FALSE)

rejects<- !grepl("^SAM", raw$BioSample.Accession)

reject_df  <- raw[rejects, ]
print("rejecting the following lines with non-standard biosample accessions")
print(reject_df)
raw <- raw[!rejects, ]

ncbi_dir <- file.path(args[1], "ncbi_dump")
dir.create(ncbi_dir)
fetch_cmds <- paste0(
  #"if [ ! -d ",  file.path(ncbi_dir, raw$BioSample.Accession), " ]; then mkdir ", file.path(ncbi_dir, raw$BioSample.Accession), "; fi ;",
  #"if [ ! -f ", file.path(ncbi_dir, raw$BioSample.Accession, "masterrec"), " ] ; then ",
  #"esearch -db biosample -query ", raw$BioSample.Accession, 
  #" | elink -target nuccore | esummary  |xtract -pattern DocumentSummary -element Caption | sort | head -n 1 > ",  file.path(ncbi_dir, raw$BioSample.Accession, "masterrec"),  " ; fi ; ",
# tried -s for empty files,but it adds  a lot of time to execution
"if [ ! -f ", file.path(ncbi_dir, raw$BioSample.Accession), " ]; then ",
  'esearch -db biosample -query ',  raw$BioSample.Accession, ' | ', # get the biosample record
  'elink -target sra | ',  # link it to the SRA database (or try to, it usually fails)
  'efilter -query "WGS[STRATEGY] AND Genomic[SOURCE]" |', # select only WGS datasets, to avoid transcriptomics
  'efetch -format docsum > ', file.path(ncbi_dir, raw$BioSample.Accession), " ; fi") # get the summary as XML


fetch_cmds_path <- file.path(args[1], "sraFind-fetch-cmds.txt")
print("Writing out fetching commands")
write.table(row.names = F, col.names = F, fetch_cmds, quote = F,
            file = fetch_cmds_path)

# stop()
# print(paste0("Running fetch commands using ", cores, " cores"))
# system(paste0("parallel -j ", cores, " --progress :::: ", fetch_cmds_path))
