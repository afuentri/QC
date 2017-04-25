#!/usr/bin/env Rscript
# R script for fastQC_table.py fastqc output stats table plots for read number distribution generation
# The first argument must be an excel file whose "Sheet1" has the number of reads per sample on a column
# named "numero_lecturas_inicial". The second argument will be the output folder without final slash.

# Import libraries
library(xlsx)
library(ggplot2)

# Read arguments given
args = commandArgs(trailingOnly=TRUE)

# Checking if there are two arguments provided
if (length(args)!=2) {
  stop("At least two arguments must be supplied", call.=FALSE)
}

# Open excel file
stats <- read.xlsx(args[1], sheetName = "Sheet1")

# Convert column to numeric type (important)
stats$numero_lecturas_inicial = as.numeric(stats$numero_lecturas_inicial)

# Plotting

## Histogram
h <- ggplot(stats, aes(x = numero_lecturas_inicial))
h + geom_histogram(binwidth = .5, colour = "black") +
ylab("conteo") + xlab("numero de lecturas") +
ggtitle("Distribucion de numero de lecturas en los FASTQ")

## Save plot
dev.copy(png, paste(args[2], 'read_counts.png', sep = '/')
dev.off()

## Density
g <- ggplot(stats, aes(x = numero_lecturas_inicial))
g + geom_line(stat = "density") +
ylab("densidad") + xlab("numero de lecturas") +
ggtitle("Densidad de lecturas en los FASTQ")

## Save plot
dev.copy(png, paste(args[2], 'read_density.png', sep = '/')
dev.off()
