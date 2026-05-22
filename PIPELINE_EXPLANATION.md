# Bacterial Genome Pipeline Explanation

## Project Goal

The goal of this project was to create a reusable automated workflow for bacterial genome analysis. The pipeline takes paired-end raw FASTQ files as input and produces quality control reports, trimmed reads, genome assembly, assembly quality statistics, genome annotation, a combined MultiQC report, and a final summary report.

This pipeline was created so future bacterial genome projects can be processed consistently by editing only one configuration file, `config.env`, and then running one Bash script.

## Tools Used

FastQC  
Used to check the quality of raw sequencing reads before trimming.

fastp  
Used to trim low-quality bases, remove poor reads, and generate cleaned paired-end FASTQ files.

FastQC after trimming  
Used to check whether read quality improved after fastp processing.

SPAdes  
Used for de novo bacterial genome assembly. It builds contigs from the cleaned paired-end reads.

QUAST  
Used to evaluate the quality of the genome assembly. It reports metrics such as contig count, total length, GC content, N50, L50, and number of unknown bases.

Prokka  
Used to annotate the assembled bacterial genome. It predicts coding sequences, rRNA, tRNA, tmRNA, and other genomic features.

MultiQC  
Used to combine supported reports and logs into one HTML summary report, making the results easier to review.

Bash  
Used to automate the entire workflow in a reproducible command-line script.

Conda  
Used to manage the bioinformatics software environment.

OpenAI Codex and ChatGPT  
Used as coding assistants to help generate, review, debug, and improve the automation script and documentation.

## Automated Workflow

The current pipeline follows this 8-step workflow:

1. Raw FastQC
2. fastp trimming
3. FastQC after trimming
4. SPAdes assembly
5. QUAST assembly QC
6. Prokka annotation
7. MultiQC combined report
8. Final summary report

## Why config.env Makes the Workflow Reusable

Instead of hardcoding one sample into the script, the pipeline reads project-specific information from `config.env`.

For each new project, only these values need to be changed:

PROJECT_DIR  
The project folder path.

SAMPLE_ID  
The sample name used for output folders and reports.

R1  
The forward FASTQ file.

R2  
The reverse FASTQ file.

GENUS  
The organism genus.

SPECIES  
The organism species.

STRAIN  
The strain or sample name.

THREADS  
The number of CPU threads to use.

SPADES_MEMORY  
The memory limit for SPAdes in GB.

This makes the same script reusable for many future bacterial genome projects.

## Output Organization

The pipeline uses a standard folder structure:

01_Raw_FASTQ  
Raw paired-end FASTQ files.

02_FastQC_Raw  
FastQC reports for raw reads.

03_Trimmed_FASTQ  
Trimmed FASTQ files and fastp reports.

04_FastQC_Trimmed  
FastQC reports after trimming.

05_Assembly  
SPAdes assembly output.

06_Assembly_QC  
QUAST assembly quality reports.

07_Annotation  
Prokka annotation output.

08_Notes  
Pipeline logs, MultiQC report, and final summary.

## Reproducibility

The pipeline improves reproducibility because:

- The same script runs every step in the same order.
- The sample-specific settings are stored in `config.env`.
- The software tools are documented in `environment.yml`.
- Logs are saved in `08_Notes/logs`.
- A final summary is written to `08_Notes/pipeline_summary.txt`.
- MultiQC creates a combined HTML report at `08_Notes/multiqc/multiqc_report.html`.

## Validation Using BTK1

The workflow was first completed manually on the BTK1 bacterial genome dataset. After that, the automated pipeline was tested on the same BTK1 data.

The automated BTK1 results matched the manual results.

Manual and automated Prokka results both showed:

organism: Bacillus thuringiensis BTK1  
contigs: 739  
bases: 6463016  
CDS: 6486  
rRNA: 22  
repeat_region: 2  
tRNA: 107  
tmRNA: 1  

Manual and automated QUAST results also matched, including:

Total length: 6,398,357 bp  
GC content: 34.71%  
N50: 34,170  
L50: 47  
N's per 100 kbp: 0.00  

This confirmed that the automated pipeline reproduced the manual workflow results and is reliable for future bacterial genome projects.

## Safety Design

The pipeline is designed not to delete raw FASTQ files.

During reruns, it only replaces generated output folders such as FastQC, trimming, assembly, QUAST, and Prokka output folders.

This protects the original sequencing data while still allowing the workflow to be rerun cleanly.

## Final Statement

This project demonstrates a reusable automated bacterial genome workflow from raw paired-end FASTQ files to annotated genome output. The pipeline was validated by comparing automated BTK1 results with manually generated results, confirming that the workflow is reproducible and suitable for future bacterial genome projects.
