library(ggplot2)
library(dplyr)
###########################

ggplot2::theme_set(
  ggplot2::theme_minimal() + ggplot2::theme(
    rect = element_rect(fill = "transparent"),
    #plot.background = element_rect(fill = "#FAFAFA", color=NA),
    plot.background = element_rect(fill = "transparent", color=NA),
    #axis.text = element_text(size=12),
    #axis.title  = element_text(size=16),
    panel.grid.minor.x = element_blank(),
    #title = element_text(size=20),
    # legend.text =  element_text(size=12), 
    #plot.subtitle = element_text(size=12, colour = "grey60")
    plot.subtitle = element_text(colour = "grey60")
  )
)


#########################


args = commandArgs(T)

# test args
# args=c("sraFind.tab", "./tmp_results/")
# setwd("~/GitHub/sraFind")
print("Note that 'Complete Genome' and 'Chromosome' level assemblies includes results for any with at least 1 chromosomal replicon, as these end up being used interchangably for microbes")
print("Note that 'Contig' and 'Scaffold' are grouped together as 'Draft'")

if( length(args) != 2 ){
  stop('USAGE: Rscript plot_results.R sraFind.tab ./plots/ ')
}
parsed_hits_file <- args[1]
plot_dir  <- args[2]
if (!dir.exists(plot_dir)) dir.create(plot_dir)

#  level <- gsub("(.*)sraFind-(.*?)-biosample.*", "\\2", parsed_hits_file)
print("reading parsed hits")
results <- read.csv(parsed_hits_file, header=T, sep="\t", stringsAsFactors=FALSE)
results$lev <- ifelse(results$Status %in% c("Scaffold", "Contig"), "Draft", "Complete")
results$exist <- ifelse(is.na(results$run_SRAs), "No", "Yes")
table(results$exist)

results$createDate <-  as.Date(strftime(gsub("-", NA, results$Release.Date)))
results$updateDate <- as.Date(strftime(gsub("-", NA, results$Modify.Date)))
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
  
#str(results)
for (level in c("Draft", "Complete", "All")){
  if (level == "All"){
      thisdf <- results
  } else{
    thisdf <- results %>% filter(lev == level)
  }
  ptitle <- paste0("'", level,"'-status prokaryotic genomes from NCBI as of ", Sys.Date())
  psubtitle <-paste0("From the ", nrow(results), " ", level, "-level assemblies with nuccore entries")
  
  
  p_bars <- ggplot(thisdf, aes(exist)) + geom_bar(width = .5) + coord_flip() +
    scale_y_continuous(expand=c(0, 0)) +
    labs(title=ptitle,
         subtitle=psubtitle, 
         x="SRA Accession Found", 
         y="Count")
  ggsave(p_bars, file=file.path(plot_dir, paste0(Sys.Date(), "-", level, "-results-totals.pdf")), width = 9, height = 5)
  
  b_byyear <- ggplot(thisdf, aes(x=year, fill=exist)) + 
    geom_bar(position="dodge") +# coord_flip() +
    scale_fill_manual(values=c("grey60", "darkgreen"))+
    scale_y_continuous(expand=c(0, 0)) +
    theme(axis.text.x = element_text(angle=65, hjust = 1))+
    labs(title=ptitle,
         subtitle=psubtitle, 
         x="", 
         y="Number of genomes",
         fill="Reads available?")
  ggsave(b_byyear, file=file.path(args[2], paste0(Sys.Date(), "-", level, "-results-byyear.pdf")), width = 9, height = 5)
  
}
ggsave(b_byyear, file=file.path("results-byyear.png"), width = 7, height = 5, units = "in", dpi = 300)
