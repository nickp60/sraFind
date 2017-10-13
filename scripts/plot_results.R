require(ggplot2)

names <- c("replicon", "sra_uid", "name", "sra_acc", "release_date", "update_date", "bioproject_acc")
results <- read.csv2("~/GitHub/sraFind/accs_results_sraFind.txt", sep="\t", header=F, col.names = names)
results$update_date <- strftime(results$update_date)
results$release_date <- strftime(results$release_date)
results$exists <- ifelse(is.na(results$sra_uid), "No", "Yes")
pdf(file="~/GitHub/sraFind/2017-10-13-results.pdf", width = 5, height = 4)
ggplot(results, aes(exists)) + geom_bar(width = .5) + coord_flip() +
  labs(title="Complete prokaryotic genomes with available reads",
  subtitle="From the 10,242 prokaryote assemblies with nuccore accessions that have linked SRA accessions", 
  x="SRA Accession Found", 
  y="Count")
dev.off()
