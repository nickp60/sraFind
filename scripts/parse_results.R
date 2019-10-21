library(dplyr)
DEBUG <- F
if (DEBUG){
  args=c("./output/ncbi_dump_clean")
} else {
  args = commandArgs(T)
}
all_statuses <- c("Complete", "Draft", "All")
if( length(args) != 1 ){
  stop('USAGE: Rscript parse_results.R /path/to/ncbi_dump/')
}
db_path <- args[1]
results_path = file.path(dirname(db_path), "parsed")
if (!dir.exists(db_path)) stop(paste0("datababse directory ", db_path, " not found!"))
if (length(dir(db_path)) == 0) stop(paste0("datababse directory ", db_path, " is empty!"))
dir.create(results_path)

destfile <-  "prokaryotes.txt"
if(!file.exists(destfile)){
  system("wget ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt")
}

print("reading prokaryotes.txt")
raw <- read.csv(destfile, header=T, sep="\t", stringsAsFactors=FALSE)

db <- raw

# here we select out the first record for each replicon.  We dont' really care if there are multiple chromosome, as they would all come from the same sequencing run/bioproject

# if debugging, add this column for easy viewing of greped vs raw
#raw$chrom_pre <-raw$Replicons
#raw$chrom_all <- gsub("chromosome.*?:", "", raw$Replicons)
print("parsing first chromosome accession")
db[, "nuccore_first_chrom"] <- ifelse(
  grepl("[cC]hromosome.*?:", db$Replicons),
  gsub("(.*?)[/;](.*)", "\\1", gsub("[cC]hromosome.*?:", "", db$Replicons)),
  "")
# raw$firstchrom <- ifelse(grepl("chromosome:", raw$Replicons),
#                          gsub("(.*?)[/;](.*)", "\\1", gsub("chromosome:", "", raw$Replicons)),
#                          "")
# should we decide to go the multiple chromosomes route in the future, here is the start of the greps from hell
# raw$addn_chroms <- ifelse(grepl("chromosome ", raw$Replicons),
#                           gsub("(chromosome\\s.:)","\\1", raw$Replicons),
#                           "")
# raw$addn_no_plasmids <- gsub("plasmid.*$", "",  raw$addn_chroms)
# # this one could be reopeated with a strip to keep selecting the last of them. You run into issues with CM008567.1-CM008588.1, cause some people just gotta be special
# raw$addn_last <- gsub(".*chromosome .+?:(.*?)[/.*?;$]", "\\1",  raw$addn_no_plasmids[60])

ncbi_columns = c("Biosample", "Id", "Title", "Platform", "@instrument_model",  
                 "Study@acc", "Organism@ScientificName", "Organism@taxid", "Bioproject", 
                 "CreateDate", "UpdateDate", "Run@acc", "Run@total_bases", "Run@is_public")
nice_column_no_run_headers = c("biosample",  "id", "title", "platform",  "instrument_model", 
                               "study_acc", "organism_ScientificName", "organism_taxid", "bioproject",
                               "runCreateDate", "runUpdateDate")

print("determining which biosamples have hits in the DB")
db_files_with_sras <- dir(db_path)
biosample_hits <- file.path(results_path, "hits.txt")

print(paste("Of the", nrow(db), " prokaryotes, ", length(db_files_with_sras),
            "have SRA links" ))

if (file.exists(biosample_hits) & ! DEBUG){
  print("removing old hits file")
  file.remove(biosample_hits)
}

print("creating Entrez parsing cmds")
cmds <- c()
parse_cmds <- paste0('cat ',  file.path(db_path, db_files_with_sras), ' | xtract ',  # use NCBI's tool get tabular data from XML, such as the following colimns
                     ' -pattern DocumentSummary -element ', paste(ncbi_columns, collapse=" "),
                     ' >> ' , biosample_hits)
# this makes the run data comma-sparated
parse_cmds <- gsub('Run@acc', '-sep "," -element Run@acc', parse_cmds, fixed=T)
print("executing Entrez commands to extract relavant info from database")
if (DEBUG){
  ncmds = 200
} else{
  ncmds <- length(parse_cmds)
}
  
for (i in 1:ncmds){
    if (i %% 1000 == 0 ){print(paste("running cmd", i, "of", ncmds))}
    if (DEBUG) cat(parse_cmds[i], sep = "\n")
    system(parse_cmds[i])
}
print("reading hits file")

hits <- read.csv2(
  biosample_hits, sep="\t", header=F, fill = T, 
  col.names  = c(nice_column_no_run_headers,
                 "run_SRAs", "run_sizes", "run_publicities"), 
  stringsAsFactors = F)

print("checking for missing fields")
####  here we desal with issues where the organisms scientific name was mangled/missing, 
####  resulting in a missing column.  Luckily, this only happens in a few cases, but 
####  we do need to bump these out a row.  We can (semi) easily detect them by their 
####  scientific name being numeric
hits$exclusion <- ifelse(
  !startsWith(x =  hits$biosample, "SAM"), "malformed biosample",
  #remove those with bad biosample names, starting with digits
  ifelse(startsWith(x = hits$organism_taxid, "PRJ"), "malformed organism",  ""))

table(hits$exclusion)

#remove those from the full dataset
good_sci_names <- hits[hits$exclusion == "", ]
bad_sci_names <- hits[hits$exclusion == "malformed organism", ]
# put this back together with "unknown" as sci name
bad_sci_names <- cbind(bad_sci_names[, c(1:6)], rep("Unknown", nrow(bad_sci_names)), bad_sci_names[, c(7:14), ])
# fix borked col names
colnames(bad_sci_names) <- c(nice_column_no_run_headers, "run_SRAs", "run_sizes","run_publicities", "exclusion")
# put humpty back together
pre_fixedhits <- rbind(good_sci_names, bad_sci_names)

# did we miss any?
bad_hits <- rbind(
  pre_fixedhits[!grepl("^PRJ.*$", pre_fixedhits$bioproject), ],
  hits[hits$exclusion == "malformed biosample", ]
)
pre_fixedhits$exclusion <- NULL

fixedhits <-  pre_fixedhits[grepl("^PRJ.*$", pre_fixedhits$bioproject), ]
print(paste("writing", nrow(bad_hits),  "dodgy rows to parsing_errors.txt"))

# add in accession name
write.table(row.names = F, col.names = T, bad_hits, sep = "\t",
            file = file.path(results_path, paste0("parsing_errors.txt")))


all_biosamples <- merge(db[, c("BioSample.Accession", "Assembly.Accession", "Status", "nuccore_first_chrom", "WGS", "Release.Date", "Modify.Date")], 
                        fixedhits, by.x="BioSample.Accession", by.y="biosample", 
                        all.x = T)
print("writing out parsed")
# order them to make diffing easier
write.table(row.names = F, col.names = T, all_biosamples[order(all_biosamples$BioSample.Accession), ], sep = "\t",
            file = "sraFind.tab")
