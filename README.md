# Reusable Bacterial Genome Pipeline

This folder contains a reusable Bash pipeline for paired-end bacterial genome analysis. The pipeline automates the workflow from raw FASTQ files to genome annotation and summary reporting.

## Workflow Steps

1. Raw FastQC
2. fastp trimming
3. FastQC after trimming
4. SPAdes assembly
5. QUAST assembly QC
6. Prokka annotation
7. MultiQC combined report
8. Final summary report

## Required Input Files

Each project should contain paired-end FASTQ files inside:

01_Raw_FASTQ/

Example:

sample_R1.fastq.gz
sample_R2.fastq.gz

The files may be `.fastq` or `.fastq.gz`, but the exact filenames must be written correctly in `config.env`.

R1 and R2 must point to files inside 01_Raw_FASTQ. The pipeline rejects raw FASTQ paths outside this folder to protect original sequencing files during reruns.

## Project Folder Structure

Each project should use this structure:

01_Raw_FASTQ
02_FastQC_Raw
03_Trimmed_FASTQ
04_FastQC_Trimmed
05_Assembly
06_Assembly_QC
07_Annotation
08_Notes

## Files in This Template

run_pipeline.sh  
Main automation script.

config.example.env  
Example configuration file. Copy this into a project as `config.env` and edit it.

environment.yml  
Conda environment recipe for recreating the required software environment.

PIPELINE_EXPLANATION.md  
Faculty-ready explanation of the pipeline and validation.

README.md  
Usage instructions.

## How to Use This Pipeline in a New Project

Create a new project folder:

mkdir -p ~/Bioinformatics/09_Projects/Your_Project_Name

Go inside it:

cd ~/Bioinformatics/09_Projects/Your_Project_Name

Create standard folders:

mkdir -p 01_Raw_FASTQ 02_FastQC_Raw 03_Trimmed_FASTQ 04_FastQC_Trimmed 05_Assembly 06_Assembly_QC 07_Annotation 08_Notes

Place the paired FASTQ files inside:

01_Raw_FASTQ/

Copy the pipeline files into the project:

cp ~/Bioinformatics/00_Pipeline_Templates/bacterial_genome_pipeline/run_pipeline.sh .
cp ~/Bioinformatics/00_Pipeline_Templates/bacterial_genome_pipeline/config.example.env ./config.env
cp ~/Bioinformatics/00_Pipeline_Templates/bacterial_genome_pipeline/environment.yml .

Edit the config file:

nano config.env

## What to Edit in config.env

PROJECT_DIR  
Full path to the project folder.

SAMPLE_ID  
Short sample name used for output folders and reports.

R1  
Full path to the forward FASTQ file.

R2  
Full path to the reverse FASTQ file.

GENUS  
Organism genus for Prokka annotation.

SPECIES  
Organism species for Prokka annotation.

STRAIN  
Strain/sample name for Prokka annotation.

THREADS  
Number of CPU threads to use.

SPADES_MEMORY  
RAM limit in GB for SPAdes.

Example:

PROJECT_DIR="$HOME/Bioinformatics/09_Projects/BTK1"
SAMPLE_ID="BTK1"

R1="${PROJECT_DIR}/01_Raw_FASTQ/BTK1_S1_R1_001.fastq"
R2="${PROJECT_DIR}/01_Raw_FASTQ/BTK1_S1_R2_001.fastq"

GENUS="Bacillus"
SPECIES="thuringiensis"
STRAIN="BTK1"

THREADS="4"
SPADES_MEMORY="8"

## How to Run

Activate the Conda environment:

conda activate Cortex

Run the pipeline:

./run_pipeline.sh

## Important Outputs

Raw FastQC reports:

02_FastQC_Raw/

Trimmed FASTQ files:

03_Trimmed_FASTQ/

Trimmed FastQC reports:

04_FastQC_Trimmed/

SPAdes assembly:

05_Assembly/

Main assembly file:

contigs.fasta

QUAST assembly QC report:

06_Assembly_QC/

Prokka annotation:

07_Annotation/

Important Prokka files:

.gff
.gbk
.faa
.ffn
.fna
.tsv
.txt

MultiQC combined report:

08_Notes/multiqc/multiqc_report.html

Final pipeline summary:

08_Notes/pipeline_summary.txt

Pipeline log:

08_Notes/logs/

## Safety Notes

The pipeline does not delete raw FASTQ files.

Only generated output folders are replaced during reruns.

Always check `config.env` carefully before running the pipeline.

Always confirm that R1 and R2 filenames match the actual files in `01_Raw_FASTQ`.

## Environment Recreation

The required Conda environment can be recreated with:

conda env create -f environment.yml

Then activate it with:

conda activate Cortex
