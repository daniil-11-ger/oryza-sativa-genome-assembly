# oryza-sativa-genome-assembly
Advanced plant genome assembly pipeline for Oryza sativa using HiFi reads, k-mer profiling (Jellyfish), and Hifiasm
# Plant Genome Assembly: Oryza sativa (Rice)

This repository contains a high-performance bioinformatics pipeline for assembling the *Oryza sativa* genome using PacBio HiFi reads (Accession: SRR35146894).

## Project Features
Compared to bacterial assembly, this project handles a larger eukaryotic genome, requiring advanced k-mer profiling and specialized assemblers for long reads.

### Key Components:
* **Data Retrieval:** Automated SRA data download via `sra-tools`.
* **K-mer Profiling (Jellyfish):** Multi-k analysis (k=21, 51) to estimate genome size, heterozygosity, and repeat content.
* **Long-read Assembly (Hifiasm):** State-of-the-art assembler specifically designed for PacBio HiFi reads.
* **HPC Optimized:** Configured for multi-threading (up to 20 threads) and memory-intensive processing.

## Pipeline Workflow

1. **Setup:** Workspace initialization.
2. **K-mer Counting:** Generating histograms with `jellyfish` to assess data quality.
3. **Format Conversion:** Preparing sequences for the assembly engine.
4. **Assembly:** Executing `hifiasm` for high-fidelity contig generation.

## K-mer Analysis Insights
The k-mer analysis is a crucial step in plant genomics. It allows us to:
- Predict the genome size.
- Identify the level of duplication and repeats.
- Optimize assembly parameters.

> **Analogy:** If assembly is building a house, K-mer analysis is checking the quality and quantity of bricks before the first wall is even raised.

## How to Run
```bash
# Clone the repository
git clone [https://github.com/ВАШ_НИК/oryza-sativa-genome-assembly.git](https://github.com/ВАШ_НИК/oryza-sativa-genome-assembly.git)

# Run the pipeline
bash scripts/assembly_pipeline.sh
