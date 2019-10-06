args = commandArgs(T)

# test args
# args=c("Complete Genome", "./tmpO/", "./output/ncbi_dump")
# setwd("~/GitHub/sraFind")
all_statuses <- c("Complete", "Draft", "All")
print("Options for filtering:")
print(all_statuses)
print("Note that 'Complete Genome' and 'Chromosome' level assemblies includes results for any with at least 1 chromosomal replicon, as these end up being used interchangably for microbes")
print("Note that 'Contig' and 'Scaffold' are grouped together")
if (!dir.exists(args[2])) dir.create(args[2])
if(!args[1] %in% c("Complete Genome", "Draft", "All")){
  stop('USAGE: Rscript parse_results.R <Complete|Draft|All> output/dir/ /path/to/ncbi_dump/')
} else{
  status = gsub(" ", "", args[1])
  print(paste("Level of interest:", status))
}
db_path = args[3]
if (!dir.exists(db_path)) stop(paste0("datababse directory ", db_path, "not found!"))
if (length(dir(db_path)) == 0) stop(paste0("datababse directory ", db_path, "is empty!"))


destfile="prokaryotes.txt"
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

if (status == "Complete"){
  accs_col = "nuccore_first_chrom"
  db<- db[db$nuccore_first_chrom != "",]
} else if (status == "All"){
  accs_col = "Assembly.Accession"
} else if(status == "Draft"){
  accs_col = "Assembly.Accession"
  db <- db[db$Status %in% c("Contig", "Scaffold"), ]
}

print(paste("writing out", nrow(db), accs_col, "of the full", nrow(raw) ))
write.table(row.names = F, col.names = T, db, sep = "\t",
            file = file.path(args[2], paste0("sraFind-", status, "-prokaryotes.txt")))

################################################################################
ncbi_columns = c("Biosample", "Id", "Title", "Platform", "@instrument_model",  "Study@acc", "Organism@ScientificName", "Organism@taxid", "Bioproject", "CreateDate", "UpdateDate", "Run@acc", "Run@total_bases", "Run@is_public")
nice_column_no_run_headers = c("biosample",  "id", "title", "platform",  "instrument_model", "study_acc", "organism_ScientificName", "organism_taxid", "bioproject", "runCreateDate", "runUpdateDate")

##
print("determining which biosamples have hits in the DB")
db_files <- dir(db_path)
db_files_of_interest <- db_files[gsub("(.*)_(.*)", "\\2", db_files) %in% db$BioSample.Accession]


biosample_hits <- file.path(args[2], "hits.txt")

print(paste0("Of the ", nrow(db), " biosamples of level ", status,  ", ", length(db_files_of_interest),
            " have SRA links in the current database of ",nrow(raw) ))

if (file.exists(biosample_hits)){
  print("removing old hits file")
  file.remove(biosample_hits)
}
print("creating Entrez parsing cmds")
parse_cmds <- paste0("cat ", file.path(db_path, db_files_of_interest), " | ",
                     'xtract ', # use NCBI's tool get tabular data from XML, such as the following colimns
                     '-pattern DocumentSummary -element ', paste(ncbi_columns, collapse=" "),
                     ' >> ' , biosample_hits)
print("executing Entrez commands to extract relavant info from database")
ncmds <- length(parse_cmds)
for (i in 1:length(parse_cmds)){
    if (i %% 1000 == 0){print(paste("running cmd", i, "of", ncmds))}
    system(parse_cmds[i])
}
print("reading hits file")


# we have to allow the last columns to be shaggy to account for biosamples with multiple SRAsand lop them off after the fact.  Most, as we can see heree, have 13 columns.  That is for 1 SRA, size, and availability.  if we have, say, 40, which means we have 9 SRAs, 9 sizes, and 9 availabilities

#biosample_hits <- "./output/hits.txt"
max_fields = max(count.fields(biosample_hits, sep="\t", skip = 0,
                              blank.lines.skip = TRUE, comment.char = "#"), na.rm = T)
# min_fields = min(count.fields(biosample_hits, sep="\t", skip = 0,
#                               blank.lines.skip = TRUE, comment.char = "#"))
# table(count.fields(biosample_hits, sep="\t", skip = 0,
#                    blank.lines.skip = TRUE, comment.char = "#"))

raw_hits <- read.csv2(biosample_hits, sep="\t", header=F, fill = T, col.names  = paste(c(1:(max_fields))), stringsAsFactors = F)


print("making run data comma-separated")

hits <-raw_hits[, c(1:length(nice_column_no_run_headers))]
colnames(hits) <- nice_column_no_run_headers


# sort out the remaining columns
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

print("checking for missing fields")
####  here we desal with issues where the organisms scientific name was mangled/missing, resulting in a missing column.  Luckily, this only happens in a few cases, but we do need to bump these out a row.  We can (semi) easily detect them by their scientific name being numeric
bad_sci_names <- hits[grepl("^\\d*$", hits$organism_ScientificName), ]
#remove those from the full dataset
hits <- hits[!grepl("^\\d*$", hits$organism_ScientificName), ]
# put this back together with "unknown" as sci name
bad_sci_names <- cbind(bad_sci_names[, c(1:6)], rep("Unknown", nrow(bad_sci_names)), bad_sci_names[, c(7:14), ])
# fix borked col names
colnames(bad_sci_names) <- c(nice_column_no_run_headers, "nSRAs", "run_SRAs", "run_sizes","run_publicities")
# put humpty back together
hits <- rbind(hits, bad_sci_names)

# did we miss any?
bad_bioproject <- !grepl("^PRJ.*$", hits$bioproject)

print("writing dodgy rows to parsing_errors.txt")

hits <- hits[!bad_bioproject, ]
write.table(row.names = F, col.names = T,  hits[bad_bioproject, ], sep = "\t",
            file = file.path(args[2], paste0("parsing_errors.txt")))


all_biosamples <- merge(db[, c("BioSample.Accession", "Assembly.Accession", "Status", "nuccore_first_chrom", "Release.Date", "Modify.Date")], hits, by.x="BioSample.Accession", by.y="biosample", all.x = T)
print("writing out parsed")
# order them to make diffing easier
write.table(row.names = F, col.names = T, all_biosamples[order(all_biosamples$BioSample.Accession), ], sep = "\t",
            file = file.path(args[2], paste0("sraFind-", status, "-biosample-with-SRA-hits.txt")))
