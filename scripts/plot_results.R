require(ggplot2)
require(dplyr)
args = commandArgs(T)

# test args
#args=c("./parsed/sraFind-CompleteGenome-biosample-with-SRA-hits.txt", "./output/plotter/")
# setwd("~/GitHub/sraFind")

if (!dir.exists(args[2])) dir.create(args[2])
print('USAGE: Rscript plot_results.R ./sraFind-Biosample-with-SRA-hits.csv output/dir/')
parsed_hits_file <- args[1]

level <- gsub("(.*)sraFind-(.*?)-biosample.*", "\\2", parsed_hits_file)

print("reading parsed hits")
results <- read.csv(parsed_hits_file, header=T, sep="\t", stringsAsFactors=FALSE)


results$exist <- ifelse(is.na(results$run_SRAs), "No", "Yes")
table(results$exist)

results$createDate <-  as.Date(strftime(results[, "Release.Date"]))
results$updateDate <- as.Date(strftime(results[, "Modify.Date"]))
results <- results %>%
  mutate(month=format(createDate, "%Y-%m"),
         year=format(createDate, "%Y")) %>%
  group_by(year) %>%
  mutate(nyear=n(),
         nyear_open=sum(exist=="Yes"),
         nyear_closed=sum(exist=="No")) %>%
  group_by(month) %>%
  mutate(nmonth=n(),
         nmonth_open=sum(exist=="Yes")) %>%
  as.data.frame()
  
str(results)

ptitle <- paste0("'", level,"'-status prokaryotic genomes from NCBI as of ", Sys.Date())
psubtitle <-paste0("From the ", nrow(results), " ", level, "-level assemblies with nuccore entries")
if (level %in% c("CompleteGenome", "Chromosome")){
  psubtitle <- paste0(psubtitle, "\nNote: ", level, " includes both 'Complete Genome' and 'Chromosome' levels")
  
}
pdf(file=file.path(args[2], paste0(Sys.Date(), "-results-totals.pdf")), width = 5, height = 4)
ggplot(results, aes(exist)) + geom_bar(width = .5) + coord_flip() +
  labs(title=ptitle,
       subtitle=psubtitle, 
       x="SRA Accession Found", 
  y="Count")
dev.off()
pdf(file=file.path(args[2], paste0(Sys.Date(), "-results-byyear.pdf")), width = 5, height = 5)
ggplot(results, aes(x=year, fill=exist)) + 
  geom_bar(position="dodge") +# coord_flip() +
    scale_fill_manual(values=c("grey60", "darkgreen"))+
  theme(axis.text.x = element_text(angle=65, hjust = 1))+
  labs(title=ptitle,
       subtitle=psubtitle, 
       x="", 
       y="Number of genomes",
       fill="Reads available?")

dev.off()
# this gets used for the readme
png(file=file.path("results-byyear.png"), width = 7, height = 5, units = "in", res = 300)
ggplot(results, aes(x=year, fill=exist)) + 
  geom_bar(position="dodge") +# coord_flip() +
  scale_fill_manual(values=c("grey60", "darkgreen"))+
  theme(axis.text.x = element_text(angle=65, hjust = 1))+
  labs(title=ptitle,
       subtitle=psubtitle, 
       x="", 
       y="Number of genomes",
       fill="Reads available?")

dev.off()
