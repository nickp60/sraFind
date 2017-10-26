require(ggplot2)
require(dplyr)

names <- c("replicon", "sra_uid", "name", "sra_acc", "release_date", "update_date", "bioproject_acc")
accessions <- read.csv2("~/GitHub/sraFind/data/2017-10-25-prokaryotes_subset.txt", sep="\t", header=T, stringsAsFactors = F)
results <- read.csv2("~/GitHub/sraFind/results/version0.0.1_results.txt", sep="\t", header=F, col.names = names, stringsAsFactors = F, na.strings = c(""))

results <- merge(results, accessions, by.x="replicon", by.y="chrom")
results$exist <- ifelse(is.na(results$sra_uid), "No", "Yes")
table(results$exist)

results$update_date <-  as.Date(strftime(results$Modify.Date))
results$release_date <- as.Date(strftime(results$Release.Date))
results <- results %>%
  mutate(month=format(release_date, "%Y-%m"),
         year=format(release_date, "%Y")) %>%
  group_by(year) %>%
  mutate(nyear=n(),
         nyear_open=sum(exist=="Yes"),
         nyear_closed=sum(exist=="No")) %>%
  group_by(month) %>%
  mutate(nmonth=n(),
         nmonth_open=sum(exist=="Yes")) %>%
  as.data.frame()
  
str(results)
pdf(file="~/GitHub/sraFind/results/2017-10-16-results-totals.pdf", width = 5, height = 4)
ggplot(results, aes(exist)) + geom_bar(width = .5) + coord_flip() +
  labs(title="Complete prokaryotic genomes with available reads",
  subtitle="From the 10,242 prokaryotic assemblies with nuccore entries", 
  x="SRA Accession Found", 
  y="Count")
dev.off()
pdf(file="~/GitHub/sraFind/results/2017-10-16-results-byyear.pdf", width = 5, height = 5)
# ggplot(results[!duplicated(results[, c("year", "nyear_closed", "nyear_open")]), ], aes(x=year, color=exist)) + 
  ggplot(results, aes(x=year, fill=exist)) + 
  geom_bar(position="dodge") +# coord_flip() +
    scale_fill_manual(values=c("grey60", "darkgreen"))+
  # geom_line(aes(y=nyear_open/nyear_closed, group="year"), color="green")+
  #  geom_bar(aes(o))
  # scale_x_date() +
  theme(axis.text.x = element_text(angle=65, hjust = 1))+
  labs(title="Complete prokaryotic genomes from NCBI",
       subtitle="From the 10,242 prokaryotic assemblies with nuccore \nentries linked to BioSamples linked to SRAs", 
       x="", 
       y="Number of genomes",
       fill="Reads available?")



dev.off()
