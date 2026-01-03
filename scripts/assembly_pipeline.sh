#!/bin/bash

# Pipeline for Oryza sativa genome assembly (Rice)
# Tools used: sra-tools, jellyfish, hifiasm

# 1. Workspace preparation
PROJECT_DIR="ORYZA_SATIVA_ASSEMBLY"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 2. Downloading data (SRA)
# Accession: SRR35146894
fastq-dump --split-files SRR35146894

# 3. K-mer Analysis (Jellyfish)
mkdir -p KMER_ANALYSIS

# Prepare the trimmed fastq file for analysis
if [ -f "ALL_trimmed.fastq" ]; then
    mv ALL_trimmed.fastq KMER_ANALYSIS/
fi

cd KMER_ANALYSIS

# Run Jellyfish for k=21
conda activate jellyfish
jellyfish count -m 21 -s 100M -t 8 ALL_trimmed.fastq -o mer_counts.jf
jellyfish histo -t 8 mer_counts.jf > mer_21.histo

# Run Jellyfish for k=51
jellyfish count -C -m 51 -s 200M -t 16 ALL_trimmed.fastq -o mer_counts_51.jf
jellyfish histo -t 16 mer_counts_51.jf > mer_51.histo

conda deactivate
cd ..

# 4. Preparation for Assembly
# Rename fastq to fasta for hifiasm compatibility
if [ -f "SRR35146894_1.fastq" ]; then
    cp SRR35146894_1.fastq SRR35146894.fasta
fi

# 5. Genome Assembly (Hifiasm)
# Using 20 threads as per high-performance requirements
hifiasm -o ASSEMBLY -t 20 SRR35146894.fasta

echo "Pipeline complete. Assembly results are stored with the prefix: ASSEMBLY.*"
