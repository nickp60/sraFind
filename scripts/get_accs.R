args = commandArgs(T)

# test args
# args=list("Chromosome", "./")
# setwd("~/GitHub/sraFind")

if (!dir.exists(args[2])) dir.create(args[2])
if(!args[1] %in% c("Chromosome", "Complete Genome", "Contig", "Scaffold", "All")){
  stop('USAGE: Rscript get_accs.R <"Chromosome|Complete Genome|Contig|Scaffold|All> output/dir/ n_cores_to_use')
} else{
  status = args[1]
}
cores = args[3]
if (cores == "") cores <- 1

destfile="prokaryotes.txt"
if(!file.exists(destfile)){
  system("wget ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt")
}


raw <- read.csv(destfile, header=T, sep="\t", stringsAsFactors=FALSE)

db <- raw

# here we select out the first record for each replicon.  We dont' really care if there are multiple chromosome, as they would all come from the same sequencing run/bioproject

# if debugging, add this column for easy viewing of greped vs raw
#raw$chrom_pre <-raw$Replicons
#raw$chrom_all <- gsub("chromosome.*?:", "", raw$Replicons)
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

if (status %in% c("Complete Genome", "Chromosome")){
  accs_col = "nuccore_first_chrom"
  db<- db[db$nuccore_first_chrom != "",]
} else if (status == "All"){
  accs_col = "Assembly.Accession"
} else {
  accs_col = "Assembly.Accession"
  db <- db[db$Status == status, ]
}

print(paste("writing out", nrow(db), accs_col, "of the full", nrow(raw) ))
write.table(row.names = F, col.names = T, db, sep = "\t",
            file = file.path(args[2], paste0("sraFind-", status, "-prokaryotes.txt")))
write.table(row.names = F, col.names = F, db[, c("BioSample.Accession", "Assembly.Accession", "nuccore_first_chrom" )],
            file = file.path(args[2], paste0("sraFind-", status, "-biosample-accession.txt")))

################################################################################
ncbi_columns = c("Biosample", "Id", "Title", "Platform", "@instrument_model",  "Study@acc", "Organism@ScientificName", "Organism@taxid", "Bioproject", "CreateDate", "UpdateDate", "Run@acc", "Run@total_bases", "Run@is_public")
nice_column_no_run_headers = c("biosample",  "id", "title", "platform",  "instrument_model", "study_acc", "organism_ScientificName", "organism_taxid", "bioproject", "createDate", "updateDate")

ncbi_dir <- file.path(args[2], "ncbi_dump")
dir.create(ncbi_dir)
fetch_cmds <- paste0("if [ ! -f ", file.path(ncbi_dir, db$BioSample.Accession), " ] ; then ",
  'esearch -db biosample -query ',  db$BioSample.Accession, ' | ', # get the biosample record
  'elink -target sra | ',  # link it to the SRA database (or try to, it usually fails)
  'efetch -format docsum > ', file.path(ncbi_dir, db$BioSample.Accession), " ; fi") # get the summary as XML

hits_path <- file.path(args[2], "hits.txt")

parse_cmds <- paste0("cat ", file.path(ncbi_dir, db$BioSample.Accession), " | ",
  'xtract ', # use NCBI's tool get tabular data from XML, such as the following colimns
  '-pattern DocumentSummary -element ', paste(ncbi_columns, collapse=" "),
  ' >> ' , hits_path)
#system("cd ~/GitHub/sraFind/test_direct")

fetch_cmds_path <- file.path(args[2], "sraFind-fetch-cmds.txt")
print("Writing out fetching commands")
write.table(row.names = F, col.names = F, fetch_cmds, quote = F,
            file = fetch_cmds_path)
print(paste0("Running fetch commands using ", cores, " cores"))
system(paste0("parallel -j ", cores, " --progress :::: ", fetch_cmds_path))
print("collecting all the hits")
for (i in head(parse_cmds, n=100)) system(i)
#system("ls")
print("reading hits file")




# we have to allow the last columns to be shaggy to account for biosamples with multiple SRAsand lop them off after the fact.  Most, as we can see heree, have 13 columns.  That is for 1 SRA, size, and availability.  if we have, say, 40, which means we have 9 SRAs, 9 sizes, and 9 availabilities
#hits_path <- "./output/hits.txt"
max_fields = max(count.fields(hits_path, sep="\t", skip = 0,
                             blank.lines.skip = TRUE, comment.char = "#"), na.rm = T)
min_fields = min(count.fields(hits_path, sep="\t", skip = 0,
                             blank.lines.skip = TRUE, comment.char = "#"))
table(count.fields(hits_path, sep="\t", skip = 0,
                 blank.lines.skip = TRUE, comment.char = "#"))

raw_hits <- read.csv2(hits_path, sep="\t", header=F, fill = T, col.names  = paste(c(1:(max_fields))), stringsAsFactors = F)
## raw_hits <- read.csv2("~/GitHub/sraFind/test_direct/hits.txt", sep="\t", header=F, fill = T, col.names  = paste(c(1:(max_lines))), stringsAsFactors = F)



hits <-raw_hits[, c(1:length(nice_column_no_run_headers))]
colnames(hits) <- nice_column_no_run_headers


# sort out the remaining columns
table_b <-raw_hits[, c((length(nice_column_no_run_headers) + 1) : ncol(raw_hits))]
hits$nSRAs = as.integer(rowSums("" != table_b & !is.na(table_b)) / 3)

# dont do it!  There must be a better way!
#                                                     Oh, Im doing it
# but you know the speed tradeoffs of loops in R!
#                                                   *stubs out cigarette* vectorize /this/

for (i in c(1:nrow(hits))){
  nSRAs <- hits[i, "nSRAs"]
  # if(i==1) break
  hits[i, "run_SRAs"] <- paste(table_b[i, c(1:nSRAs)], collapse=",")
  hits[i, "run_sizes"] <- paste(table_b[i, c((nSRAs + 1):(2*nSRAs))], collapse=",")
  hits[i, "run_publicities"] <- paste(table_b[i, c((2* nSRAs + 1):(3*nSRAs))], collapse=",")

}
all_biosamples <- merge(db[, c("BioSample.Accession", "Assembly.Accession", "Status", "nuccore_first_chrom")], hits, by.x="BioSample.Accession", by.y="biosample", all.x = T)

write.table(row.names = F, col.names = F, all_biosamples,
            file = file.path(args[2], paste0("sraFind-", status, "-biosample-with-SRA.txt")))
