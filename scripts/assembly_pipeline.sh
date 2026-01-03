#!/bin/bash

# Pipeline for Oryza sativa (Rice) Genome Assembly and Annotation
# Process: SRA Download -> K-mer Analysis -> Assembly -> Scaffolding -> Annotation
# Tools: sra-tools, jellyfish, hifiasm, quast, ragtag, augustus


# 1. Workspace Initialization
PROJECT_DIR="ORYZA_SATIVA_ASSEMBLY_FINAL"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 2. Data Retrieval (SRA)
# Accession for Rice HiFi reads: SRR35146894
echo "[INFO] Downloading SRA data..."
fastq-dump --split-files SRR35146894

# Preparing fasta file for hifiasm assembly
if [ -f "SRR35146894_1.fastq" ]; then
    cp SRR35146894_1.fastq SRR35146894.fasta
fi

# 3. K-mer Profiling (Jellyfish)
# Used to estimate genome size and complexity
mkdir -p KMER_ANALYSIS
if [ -f "ALL_trimmed.fastq" ]; then
    cp ALL_trimmed.fastq KMER_ANALYSIS/
fi
cd KMER_ANALYSIS

echo "[INFO] Starting K-mer analysis (k=21 and k=51)..."
conda activate jellyfish

# Analysis for k=21
jellyfish count -m 21 -s 100M -t 8 ALL_trimmed.fastq -o mer_counts_21.jf
jellyfish histo -t 8 mer_counts_21.jf > mer_21.histo

# Analysis for k=51
jellyfish count -C -m 51 -s 200M -t 16 ALL_trimmed.fastq -o mer_counts_51.jf
jellyfish histo -t 16 mer_counts_51.jf > mer_51.histo

conda deactivate
cd ..

# 4. Genome Assembly (Hifiasm)
# Specialized for PacBio HiFi reads
echo "[INFO] Starting de novo assembly with Hifiasm..."
hifiasm -o ASSEMBLY -t 20 SRR35146894.fasta

# Identify the assembly output file (primary contigs)
ASSEMBLY_FA="rice_assembly.bp.p_ctg.fa"
if [ -f "ASSEMBLY.bp.p_ctg.gfa" ]; then
    # Convert GFA to FASTA if necessary
    awk '/^S/{print ">"$2"\n"$3}' ASSEMBLY.bp.p_ctg.gfa > $ASSEMBLY_FA
fi

# 5. Assembly Quality Assessment (QUAST)
echo "[INFO] Assessing assembly quality..."
conda activate quast
quast.py -o QUAST_RESULTS -t 20 $ASSEMBLY_FA
conda deactivate

# 6. Reference-Guided Scaffolding (RagTag)
# Using IRGSP-1.0 as a reference genome for Oryza sativa
echo "[INFO] Running scaffolding with RagTag..."
conda activate ragtag
# Reference: GCF_001433935.1_IRGSP-1.0_genomic.fna
ragtag.py scaffold GCF_001433935.1_IRGSP-1.0_genomic.fna $ASSEMBLY_FA -t 20 -o RAGTAG_OUTPUT
cd RAGTAG_OUTPUT

# 7. Organelle Sorting and Final Genome Construction
echo "[INFO] Sorting nuclear and organelle genomes..."
mkdir -p FINAL_GENOME
# Extracting and renaming identified organelles (based on log identification)
if [ -f "nc_001320.1_ragtag.fasta" ]; then
    mv nc_001320.1_ragtag.fasta FINAL_GENOME/chloroplast_kasalath.fasta
fi
if [ -f "nc_011033.1_ragtag.fasta" ]; then
    mv nc_011033.1_ragtag.fasta FINAL_GENOME/mitochondrion_kasalath.fasta
fi

# Building the final genome file
cat ragtag.scaffold.fasta > FINAL_GENOME/genome_kasalath.fasta
FINAL_FASTA="FINAL_GENOME/genome_kasalath.fasta"
cd ..
conda deactivate

# 8. Gene Prediction (Augustus)
# Final stage: finding coding sequences in the assembled rice genome
echo "[INFO] Starting gene annotation with Augustus..."
conda activate augustus_3.5

# Note: genome_kasalath.fasta.masked should be prepared via RepeatMasker/EDTA
augustus --species=rice \
         --hintsfile=hints.gff \
         --extrinsicCfgFile=extrinsic.cfg \
         $FINAL_FASTA.masked \
         --softmasking=1 \
         --alternatives-from-evidence=false > rice_annotation.gff

echo "[SUCCESS] Pipeline complete. Final annotation: rice_annotation.gff"
