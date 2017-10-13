raw <- read.csv("ftp://ftp.ncbi.nlm.nih.gov/genomes/GENOME_REPORTS/prokaryotes.txt", header=T, sep="\t", stringsAsFactors=FALSE)

accs <- gsub("(.*?)[/;](.*)", "\\1", gsub("chromosome.*?:", "", raw$Replicons)
     
     accs <- accs[accs != "-"]
     
     accs <- accs[!("plasmid" %in% accs)]
      
     
     write.table(row.names = F, col.names = F, accs, file = "~/GitHub/sraFind/accs.txt")
     
