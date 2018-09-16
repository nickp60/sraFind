args = commandArgs(T)

# test args
# args=list("Chromosome", "./")
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
fetch_cmds <- paste0("if [ ! -f ", file.path(ncbi_dir, raw$BioSample.Accession), " ] ; then ",
  'esearch -db biosample -query ',  raw$BioSample.Accession, ' | ', # get the biosample record
  'elink -target sra | ',  # link it to the SRA database (or try to, it usually fails)
  'efetch -format docsum > ', file.path(ncbi_dir, raw$BioSample.Accession), " ; fi") # get the summary as XML


fetch_cmds_path <- file.path(args[1], "sraFind-fetch-cmds.txt")
print("Writing out fetching commands")
write.table(row.names = F, col.names = F, fetch_cmds, quote = F,
            file = fetch_cmds_path)

# stop()
# print(paste0("Running fetch commands using ", cores, " cores"))
# system(paste0("parallel -j ", cores, " --progress :::: ", fetch_cmds_path))




