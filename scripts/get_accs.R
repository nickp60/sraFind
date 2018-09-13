args = commandArgs(T)

# test args
# args=list("Chromosome", "./")


if (!dir.exists(args[2])) dir.create(args[2])
if(!args[1] %in% c("Chromosome", "Complete Genome", "Contig", "Scaffold", "All")){
  stop('USAGE: Rscript get_accs.R <"Chromosome", "Complete Genome", "Contig", "Scaffold" "All> output/dir/')
} else{
  status = args[1]
}
destfile="prokaryotes.txt"
if(!file.exists(destfile)){
  system("wget ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt")
}


raw <- read.csv(destfile, header=T, sep="\t", stringsAsFactors=FALSE)

db <- raw

if (status %in% c("Complete Genome", "Chromosome")){
  accs_col = "nuccore_first_chrom"
# here we select out the first record for each replicon.  We dont' really care if there are multiple chromosome, as they would all come from the same sequencing run/bioproject

# if debugging, add this column for easy viewing of greped vs raw
#raw$chrom_pre <-raw$Replicons
#raw$chrom_all <- gsub("chromosome.*?:", "", raw$Replicons)
  db[, accs_col] <- ifelse(grepl("[cC]hromosome.*?:", db$Replicons),
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


  db<- db[db$nuccore_first_chrom != "",]
} else if (status == "All"){
  accs_col = "Assembly.Accession"
} else {
  accs_col = "Assembly.Accession"
  db <- db[db$Status == status, ]
}

print(paste("writing out", nrow(db), accs_col, "of the full", nrow(raw) ))
write.table(row.names = F, col.names = T, db, sep = "\t",
            file = file.path(args[2], paste0(Sys.Date(), "-sraFind-", status, "-prokaryotes.txt")))
write.table(row.names = F, col.names = F, db[, accs_col],
            file = file.path(args[2], paste0(Sys.Date(), "-sraFind-", status, ".txt")))

