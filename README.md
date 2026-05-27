# Bacterial Genome Analysis Pipeline

Reusable bacterial genome analysis workflow for paired-end FASTQ quality control, trimming, assembly, annotation, and summary reporting.


## What This Pipeline Does

The pipeline starts from paired-end bacterial FASTQ files and runs a standard genome analysis workflow:

```text
Raw paired-end FASTQ
-> raw FastQC
-> fastp trimming
-> post-trim FastQC
-> SPAdes assembly
-> QUAST assembly QC
-> Prokka annotation
-> MultiQC combined report
-> final summary report
```

The workflow is intended for educational, research, and portfolio use. It is not a clinical diagnostic workflow.

## Input Requirements

This pipeline requires paired-end bacterial FASTQ reads, not assembled genome FASTA files.

Place the input files inside the project-local input folder:

```text
01_Raw_FASTQ/
```

Accepted file extensions include:

```text
.fastq
.fq
.fastq.gz
.fq.gz
```

The `R1` and `R2` paths in `config.env` must point to files inside `PROJECT_DIR/01_Raw_FASTQ`.

## Workflow Overview

1. Validate `config.env` and input FASTQ paths.
2. Run FastQC on raw reads.
3. Trim reads with fastp.
4. Run FastQC on trimmed reads.
5. Assemble the genome with SPAdes.
6. Evaluate assembly quality with QUAST.
7. Annotate the assembly with Prokka.
8. Build a combined MultiQC report.
9. Write a final pipeline summary.

## Folder Structure

Each analysis project should use this numbered folder style:

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


## Template Files

```text
run_pipeline.sh
config.example.env
environment.yml
README.md
PIPELINE_EXPLANATION.md
.gitignore
```

The reusable template belongs in `00_Pipeline_Templates`. Each real analysis should be run from a separate project folder under `09_Projects`.

## Environment Setup

Create the Conda environment:

```bash
conda env create -f environment.yml
```

Activate it:

```bash
conda activate Cortex
```

The environment file records the required software tools. The pipeline does not install or modify Conda environments automatically.

## Configuration

Copy the public example configuration into a private local config file:

```bash
cp config.example.env config.env
nano config.env
```

Edit these values:

```text
PROJECT_DIR
SAMPLE_ID
R1
R2
GENUS
SPECIES
STRAIN
THREADS
SPADES_MEMORY
```

Example:

```bash
PROJECT_DIR="$HOME/Bioinformatics/09_Projects/BTK1"
SAMPLE_ID="BTK1"

R1="${PROJECT_DIR}/01_Raw_FASTQ/BTK1_S1_R1_001.fastq"
R2="${PROJECT_DIR}/01_Raw_FASTQ/BTK1_S1_R2_001.fastq"

GENUS="Bacillus"
SPECIES="thuringiensis"
STRAIN="BTK1"

THREADS="4"
SPADES_MEMORY="8"
```

`config.example.env` is safe to commit. `config.env` is local, sample-specific, and ignored by Git.

## How to Run

From the project folder:

```bash
chmod +x run_pipeline.sh
./run_pipeline.sh
```

The script can also be run with an explicit config path:

```bash
./run_pipeline.sh path/to/config.env
```

## Output Explanation

Important outputs include:

```text
02_FastQC_Raw/
```

Raw read quality reports.

```text
03_Trimmed_FASTQ/
```

Trimmed paired-end FASTQ files and fastp reports.

```text
04_FastQC_Trimmed/
```

Post-trimming read quality reports.

```text
05_Assembly/
```

SPAdes assembly output, including `contigs.fasta`.

```text
06_Assembly_QC/
```

QUAST assembly quality reports.

```text
07_Annotation/
```

Prokka genome annotation files such as `.gff`, `.gbk`, `.faa`, `.ffn`, `.fna`, `.tsv`, and `.txt`.

```text
08_Notes/multiqc/multiqc_report.html
08_Notes/pipeline_summary.txt
08_Notes/logs/
```

Combined MultiQC report, final pipeline summary, and logs.

## Safety Design

The pipeline includes basic safety checks:

- `SAMPLE_ID` is validated before being used in output names.
- `R1` and `R2` must resolve inside `PROJECT_DIR/01_Raw_FASTQ`.
- Raw FASTQ files are not deleted during reruns.
- Rerun cleanup only removes generated output folders.
- Path traversal patterns are rejected for input files.

Always inspect `config.env` before running the workflow.

## Validation Note

This pipeline was validated during development with the BTK1 bacterial genome project and later tested with SRR2093871 in the same reusable workflow style. The validation compared manually generated results with automated pipeline results to confirm that the scripted workflow reproduced the expected analysis steps.

## Interpretation Notes

The outputs support genome assembly and annotation review. QUAST metrics help assess assembly quality, and Prokka annotations provide predicted genomic features.

These outputs do not prove strain identity, virulence, pathogenicity, or clinical significance by themselves. Any biological interpretation should be made with appropriate downstream analyses, metadata, and experimental context.

## Limitations

- The pipeline is designed for paired-end bacterial FASTQ reads.
- It is not intended for raw long-read-only workflows without modification.
- It does not perform taxonomic confirmation, contamination screening, antimicrobial resistance prediction, or virulence prediction.
- It is not a clinical or diagnostic pipeline.
- Assembly and annotation results are computational predictions and should be reviewed before biological conclusions are made.

## Future Improvements

Possible future additions include:

- contamination screening
- taxonomic classification
- antimicrobial resistance gene screening
- virulence gene screening
- plasmid detection
- long-read or hybrid assembly support
- automated final report tables from QUAST and Prokka outputs

## Skills Demonstrated

This project demonstrates practical command-line bioinformatics skills, reproducible project organization, Bash automation, Conda environment management, and safe handling of raw sequencing input files. It serves as the foundational project in a broader bacterial genomics portfolio.

## Author

Created by Raihanul Islam (`Savagebd`) as a reusable bacterial genome analysis pipeline project.

This repository is shared publicly as a portfolio and learning project. If you use or reference this work, please provide proper credit to the original repository.

## Academic Integrity Notice

This project represents my own learning, implementation, testing, and documentation work. The repository is public for transparency and portfolio purposes. Direct copying and submitting this project as someone else's original coursework is not permitted.
