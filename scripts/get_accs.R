#library(DBI)
args = commandArgs(T)

# test args
# args=c("./output/")
# setwd("~/GitHub/sraFind")

print('USAGE: Rscript get_accs.R  /path/to/output/dir/')
db_path <- args[1]
if (!dir.exists(db_path)) dir.create(db_path)

destfile="prokaryotes.txt"
if(!file.exists(destfile)){
  print("Downloading GENOME REPOSRT's prokaryotes.txt")
  system("wget ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt")
}
# con = dbConnect(drv=RSQLite::SQLite(), dbname="sraFind.db")

#  One day, we may implement a sqlite based approach
# if (!"biosamples" %in% dbListTables(con)){
#   print("creating table")
#   dbExecute(con, "CREATE TABLE biosamples (biosample TEXT PRIMARY KEY, path TEXT)")
# }
# print("inserting data into table")
# 
# this_table <- dbReadTable(con, "biosamples") 
# diff_table <- files_present[!files_present$biosample %in%this_table$biosample, ]
# for(i in 1:nrow(diff_table)){
#   dbExecute(con, "INSERT OR IGNORE INTO biosamples VALUES (?, ?)", c(diff_table$biosample[i], diff_table$path[i]))
# }
# dbfiles <- dbGetQuery(con, "SELECT * FROM biosamples")
# dbDisconnect(con)
# unlink("sraFind.db")

print("Reading prokaryotes.txt ")
raw <- read.csv(destfile, header=T, sep="\t", stringsAsFactors=FALSE)

ncbi_dir <- file.path(args[1], "ncbi_dump")
dir.create(ncbi_dir, showWarnings = F)
files_present <-  data.frame(path=dir(ncbi_dir, full.names = T), stringsAsFactors = F)
files_present$biosample <- basename(files_present$path)

missing <- raw[!raw$BioSample.Accession %in% files_present$biosample, ]
fetch_cmds <- paste0(
  #"if [ ! -d ",  file.path(ncbi_dir, raw$BioSample.Accession), " ]; then mkdir ", file.path(ncbi_dir, raw$BioSample.Accession), "; fi ;",
  "if [ ! -f ", file.path(ncbi_dir, raw$BioSample.Accession, "masterrec"), " ] ; then ",
  #"esearch -db biosample -query ", raw$BioSample.Accession, 
  #" | elink -target nuccore | esummary  |xtract -pattern DocumentSummary -element Caption | sort | head -n 1 > ",  file.path(ncbi_dir, raw$BioSample.Accession, "masterrec"),  " ; fi ; ",
  'esearch -db biosample -query ',  missing$BioSample.Accession, ' | ', # get the biosample record
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
