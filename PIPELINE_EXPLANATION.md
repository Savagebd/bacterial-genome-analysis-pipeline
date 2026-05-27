# Bacterial Genome Pipeline Explanation

## Project Goal

This project provides a reusable workflow for paired-end bacterial genome analysis. It starts with raw FASTQ sequencing reads and produces read quality reports, trimmed reads, a draft genome assembly, assembly quality statistics, genome annotation, a combined MultiQC report, and a final summary.

The main goal is reproducibility: each new project uses the same script and changes only the local `config.env` file.

## Why Paired-End FASTQ Files?

Paired-end FASTQ files contain sequencing reads from both ends of DNA fragments. These paired reads help assemblers reconstruct bacterial genome contigs more accurately than single-end reads alone.

This pipeline is for raw paired-end reads. If a project already has an assembled genome FASTA file, a genome-annotation or genome-mining pipeline is a better fit.

## Tool Logic

### FastQC

FastQC checks the quality of the raw reads before trimming. It helps identify problems such as low-quality bases, adapter contamination, or unusual sequence composition.

### fastp

fastp trims low-quality bases and removes poor-quality reads. It also produces useful summary reports about trimming and read quality.

### FastQC After Trimming

Running FastQC again after fastp shows whether trimming improved the read set.

### SPAdes

SPAdes performs de novo bacterial genome assembly. It builds contigs from the cleaned paired-end reads.

### QUAST

QUAST evaluates the draft assembly. Important metrics include total assembly length, contig count, N50, L50, GC content, and ambiguous bases.

### Prokka

Prokka predicts and annotates genomic features such as coding sequences, rRNA, tRNA, tmRNA, and other bacterial genome features.

### MultiQC

MultiQC combines supported reports into one HTML file, making the project easier to review.

## Why config.env Matters

The pipeline avoids hardcoding sample-specific paths in the script. Instead, `config.env` stores:

- project folder
- sample ID
- R1 and R2 FASTQ paths
- organism metadata for Prokka
- thread count
- SPAdes memory limit

This makes the workflow reusable across many bacterial genome projects.

## Output Organization

The project uses a numbered folder structure:

```text
01_Raw_FASTQ
02_FastQC_Raw
03_Trimmed_FASTQ
04_FastQC_Trimmed
05_Assembly
06_Assembly_QC
07_Annotation
08_Notes
```

The raw FASTQ folder is treated as protected input. Generated output folders can be recreated during reruns.

## Safety Design

The script checks that paired-end FASTQ files are inside `PROJECT_DIR/01_Raw_FASTQ`. It also validates the sample name before using it in output paths.

This protects raw input files and reduces the chance of accidentally using or deleting files outside the project folder.

## Validation

During development, the workflow was validated using the BTK1 bacterial genome project and later tested with SRR2093871 in the same reusable project format. The automated pipeline reproduced the expected analysis steps and matched the manually generated workflow results for the BTK1 test case.

## What the Results Mean

The pipeline produces computational assembly and annotation results. These results are useful for quality review and downstream bacterial genomics work.

They do not prove strain identity, virulence, pathogenicity, clinical relevance, or biological function by themselves. Strong biological claims require additional analyses, metadata, curated databases, and often experimental validation.

## Skills Demonstrated

This project demonstrates core bioinformatics skills: command-line workflow design, raw-read quality control, read trimming, genome assembly, assembly evaluation, annotation, reproducible configuration, and safe project organization.
