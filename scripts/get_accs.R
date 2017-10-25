raw <- read.csv("ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt", header=T, sep="\t", stringsAsFactors=FALSE)
length(raw$Replicons == "-")
raw$chrom <- gsub("(.*?)[/;](.*)", "\\1", gsub("chromosome.*?:", "", raw$Replicons))
     
sub_raw<- raw[raw$chrom != "-",]

accs <- sub_raw[!("plasmid" %in% sub_raw$chrom), "chrom"]

write.table(row.names = F, col.names = T, raw, sep = "\t",
            file = paste0("~/GitHub/sraFind/data/", Sys.Date(), "-prokaryotes.txt"))
write.table(row.names = F, col.names = T, sub_raw,  sep="\t",
            file = paste0("~/GitHub/sraFind/data/", Sys.Date(), "-prokaryotes_subset.txt"))
write.table(row.names = F, col.names = F, accs, file = "~/GitHub/sraFind/data/accs.txt")

