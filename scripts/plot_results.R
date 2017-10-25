require(ggplot2)
require(dplyr)

names <- c("replicon", "sra_uid", "name", "sra_acc", "release_date", "update_date", "bioproject_acc")
accessions <- read.csv2("~/GitHub/sraFind/data/accs.txt", sep="\t", header=F)
results <- read.csv2("~/GitHub/sraFind/version0.0.1_results.txt", sep="\t", header=F, col.names = names, stringsAsFactors = F, na.strings = c(""))

results$update_date <-  as.Date(strftime(results$update_date))
results$release_date <- as.Date(strftime(results$release_date))
results <- results %>%
  mutate(month=format(release_date, "%Y-%m"),
         year=format(release_date, "%Y")) %>%
  group_by(year) %>%
  mutate(nyear=n()) %>%
  group_by(month) %>%
  mutate(nmonth=n()) %>%
  as.data.frame()
  
results$exist <- ifelse(is.na(results$sra_uid), "No", "Yes")
table(results$exist)
str(results)
pdf(file="~/GitHub/sraFind/2017-10-16-results.pdf", width = 5, height = 4)
ggplot(results, aes(exist)) + geom_bar(width = .5) + coord_flip() +
  labs(title="Complete prokaryotic genomes with available reads",
  subtitle="From the 10,242 prokaryotic assemblies with nuccore entries", 
  x="SRA Accession Found", 
  y="Count")
ggplot(results[results$exist == "Yes",], aes(year)) + geom_bar(width = .5) +# coord_flip() +
  # scale_x_date() +
  theme(axis.text.x = element_text(angle=90))+
  labs(title="Complete prokaryotic genomes with available reads",
       subtitle="From the 10,242 prokaryotic assemblies with nuccore entries", 
       x="SRA Accession Found", 
       y="Count")
dev.off()
