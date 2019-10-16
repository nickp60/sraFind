args = commandArgs(T)

# test args
# args=c("./tmp5/")
# setwd("~/GitHub/sraFind")

print('USAGE: Rscript get_accs.R  /path/to/output/dir/')
if (!dir.exists(args[1])) dir.create(args[1])

destfile="prokaryotes.txt"
if(!file.exists(destfile)){
  print("Downloading GENOME REPOSRT's prokaryotes.txt")
  system("wget ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt")
}

print("Reading prokaryotes.txt ")
raw <- read.csv(destfile, header=T, sep="\t", stringsAsFactors=FALSE)

ncbi_dir <- file.path(args[1], "ncbi_dump")
dir.create(ncbi_dir)
fetch_cmds <- paste0(
  "if [ ! -d ",  file.path(ncbi_dir, raw$BioSample.Accession), " ]; then mkdir ", file.path(ncbi_dir, raw$BioSample.Accession), "; fi ;",
  "if [ ! -f ", file.path(ncbi_dir, raw$BioSample.Accession, "masterrec"), " ] ; then ",
  "esearch -db biosample -query ", raw$BioSample.Accession, 
  #" | elink -target assembly | elink -target nuccore | esummary  |xtract -pattern DocumentSummary -element Caption | sort | head -n 1 > ",  file.path(ncbi_dir, raw$BioSample.Accession, "masterrec"),  " ; fi",
  " | elink -target nuccore | esummary  |xtract -pattern DocumentSummary -element Caption | sort | head -n 1 > ",  file.path(ncbi_dir, raw$BioSample.Accession, "masterrec"),  " ; fi ; ",
  "if [ ! -f ", file.path(ncbi_dir, raw$BioSample.Accession,  raw$BioSample.Accession), " ]; then ",
  'esearch -db biosample -query ',  raw$BioSample.Accession, ' | ', # get the biosample record
  'elink -target sra | ',  # link it to the SRA database (or try to, it usually fails)
  'efilter -query "WGS[STRATEGY] AND Genomic[SOURCE]" |', # select only WGS datasets, to avoid transcriptomics
  'efetch -format docsum > ', file.path(ncbi_dir,raw$BioSample.Accession,  raw$BioSample.Accession), " ; fi") # get the summary as XML

# fetch_cmds <- paste0(
#   "if [ ! -f ", file.path(ncbi_dir, raw$BioSample.Accession, "masterrrec"), paste0("*_", raw$BioSample.Accession)), " ] ; then ",
# "masterrec=`esearch -db biosample -query ", raw$BioSample.Accession, " | elink -target assembly | elink -target nuccore | esummary  |xtract -pattern DocumentSummary -element Caption | sort | head -n 1`;",
# 'esearch -db biosample -query ',  raw$BioSample.Accession, ' | ', # get the biosample record
# 'elink -target sra | ',  # link it to the SRA database (or try to, it usually fails)
# 'efilter -query "WGS[STRATEGY] AND Genomic[SOURCE]" |', # select only WGS datasets, to avoid transcriptomics
# 'efetch -format docsum > ', file.path(ncbi_dir, paste0("${masterrec}_", raw$BioSample.Accession)), " ; fi") # get the summary as XML
# 

fetch_cmds_path <- file.path(args[1], "sraFind-fetch-cmds.txt")
print("Writing out fetching commands")
write.table(row.names = F, col.names = F, fetch_cmds, quote = F,
            file = fetch_cmds_path)

# stop()
# print(paste0("Running fetch commands using ", cores, " cores"))
# system(paste0("parallel -j ", cores, " --progress :::: ", fetch_cmds_path))
