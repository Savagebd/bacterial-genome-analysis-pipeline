#!/usr/bin/env bash

# Reusable paired-end bacterial genome pipeline template.
# Usage:
#   bash run_pipeline.sh [path/to/config.env]

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-${SCRIPT_DIR}/config.env}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}" >&2
    echo "Create config.env from config.example.env before running the pipeline." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "${CONFIG_FILE}"
# Validate SAMPLE_ID before using it in output paths.
# This prevents unsafe values such as "../sample" from escaping expected output folders.
if [[ ! "${SAMPLE_ID:-}" =~ ^[A-Za-z0-9_-]+$ ]]; then
	echo "ERROR: SAMPLE_ID may only contain letters, numbers, underscores, and hyphens." >&2
	echo "ERROR: Do not use spaces, slashes, or path traversal such as ../ in SAMPLE_ID." >&2
	exit 1
fi


# Validate raw FASTQ input paths before any cleanup can happen.
# Raw R1/R2 files must stay inside PROJECT_DIR/01_Raw_FASTQ.
if [[ -n "${PROJECT_DIR:-}" && -n "${R1:-}" && -n "${R2:-}" ]]; then
	RAW_FASTQ_ROOT="$(realpath -m "${PROJECT_DIR}/01_Raw_FASTQ")"
	R1_REALPATH="$(realpath -m "${R1}")"
	R2_REALPATH="$(realpath -m "${R2}")"

	for input_path in "${R1_REALPATH}" "${R2_REALPATH}"; do
		if [[ "${input_path}" != "${RAW_FASTQ_ROOT}/"* ]]; then
			echo "ERROR: R1 and R2 must be inside ${RAW_FASTQ_ROOT}." >&2
			echo "ERROR: Move raw FASTQ files into 01_Raw_FASTQ and update config.env." >&2
			exit 1
		fi
	done
fi


required_vars=(
    PROJECT_DIR
    SAMPLE_ID
    R1
    R2
    GENUS
    SPECIES
    STRAIN
    THREADS
    SPADES_MEMORY
)

for var_name in "${required_vars[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        echo "ERROR: Required config variable is missing or empty: ${var_name}" >&2
        exit 1
    fi
done

dependencies=(
    fastqc
    fastp
    spades.py
    quast.py
    prokka
  multiqc
)

for dependency in "${dependencies[@]}"; do
    if ! command -v "${dependency}" >/dev/null 2>&1; then
        echo "ERROR: Required command is not available on PATH: ${dependency}" >&2
        exit 1
    fi
done

if [[ ! -f "${R1}" ]]; then
    echo "ERROR: R1 FASTQ file not found: ${R1}" >&2
    exit 1
fi

if [[ ! -f "${R2}" ]]; then
    echo "ERROR: R2 FASTQ file not found: ${R2}" >&2
    exit 1
fi

PROJECT_DIR="$(cd -- "${PROJECT_DIR}" && pwd)"

RAW_FASTQ_DIR="${PROJECT_DIR}/01_Raw_FASTQ"
RAW_FASTQC_DIR="${PROJECT_DIR}/02_FastQC_Raw"
TRIMMED_FASTQ_DIR="${PROJECT_DIR}/03_Trimmed_FASTQ"
TRIMMED_FASTQC_DIR="${PROJECT_DIR}/04_FastQC_Trimmed"
ASSEMBLY_DIR="${PROJECT_DIR}/05_Assembly"
ASSEMBLY_QC_DIR="${PROJECT_DIR}/06_Assembly_QC"
ANNOTATION_DIR="${PROJECT_DIR}/07_Annotation"
NOTES_DIR="${PROJECT_DIR}/08_Notes"
LOG_DIR="${NOTES_DIR}/logs"

mkdir -p \
    "${RAW_FASTQ_DIR}" \
    "${RAW_FASTQC_DIR}" \
    "${TRIMMED_FASTQ_DIR}" \
    "${TRIMMED_FASTQC_DIR}" \
    "${ASSEMBLY_DIR}" \
    "${ASSEMBLY_QC_DIR}" \
    "${ANNOTATION_DIR}" \
    "${LOG_DIR}"

RUN_LOG="${LOG_DIR}/${SAMPLE_ID}_pipeline.log"
exec > >(tee -a "${RUN_LOG}") 2>&1

echo "Starting bacterial genome pipeline for sample: ${SAMPLE_ID}"
echo "Project directory: ${PROJECT_DIR}"
echo "Config file: ${CONFIG_FILE}"
echo "Pipeline log: ${RUN_LOG}"

RAW_FASTQC_SAMPLE_DIR="${RAW_FASTQC_DIR}/${SAMPLE_ID}"
FASTP_SAMPLE_DIR="${TRIMMED_FASTQ_DIR}/${SAMPLE_ID}"
TRIMMED_FASTQC_SAMPLE_DIR="${TRIMMED_FASTQC_DIR}/${SAMPLE_ID}"
SPADES_SAMPLE_DIR="${ASSEMBLY_DIR}/${SAMPLE_ID}_spades"
QUAST_SAMPLE_DIR="${ASSEMBLY_QC_DIR}/${SAMPLE_ID}_quast"
PROKKA_SAMPLE_DIR="${ANNOTATION_DIR}/${SAMPLE_ID}_prokka"

TRIMMED_R1="${FASTP_SAMPLE_DIR}/${SAMPLE_ID}_R1.trimmed.fastq.gz"
TRIMMED_R2="${FASTP_SAMPLE_DIR}/${SAMPLE_ID}_R2.trimmed.fastq.gz"
FASTP_HTML="${FASTP_SAMPLE_DIR}/${SAMPLE_ID}_fastp.html"
FASTP_JSON="${FASTP_SAMPLE_DIR}/${SAMPLE_ID}_fastp.json"
CONTIGS="${SPADES_SAMPLE_DIR}/contigs.fasta"
SUMMARY_FILE="${NOTES_DIR}/pipeline_summary.txt"

# Reruns replace only pipeline-generated per-sample output folders.
# Raw FASTQ paths are never included in this allowlist.
reset_generated_dir() {
    local target_dir="$1"

    case "${target_dir}" in
        "${RAW_FASTQC_DIR}/${SAMPLE_ID}"|\
        "${TRIMMED_FASTQ_DIR}/${SAMPLE_ID}"|\
        "${TRIMMED_FASTQC_DIR}/${SAMPLE_ID}"|\
        "${ASSEMBLY_DIR}/${SAMPLE_ID}_spades"|\
        "${ASSEMBLY_QC_DIR}/${SAMPLE_ID}_quast"|\
        "${ANNOTATION_DIR}/${SAMPLE_ID}_prokka")
            if [[ -e "${target_dir}" ]]; then
                echo "Replacing previous generated output folder: ${target_dir}"
                rm -rf -- "${target_dir}"
            fi
            mkdir -p "${target_dir}"
            ;;
        *)
            echo "ERROR: Refusing to reset non-allowlisted path: ${target_dir}" >&2
            exit 1
            ;;
    esac
}

echo "Step 1/8: Running FastQC on raw paired-end reads"
# Raw FastQC records read quality before any trimming or filtering.
reset_generated_dir "${RAW_FASTQC_SAMPLE_DIR}"
fastqc \
    --threads "${THREADS}" \
    --outdir "${RAW_FASTQC_SAMPLE_DIR}" \
    "${R1}" \
    "${R2}"

echo "Step 2/8: Trimming reads with fastp"
# fastp removes low-quality sequence and adapter contamination before assembly.
reset_generated_dir "${FASTP_SAMPLE_DIR}"
fastp \
    --in1 "${R1}" \
    --in2 "${R2}" \
    --out1 "${TRIMMED_R1}" \
    --out2 "${TRIMMED_R2}" \
    --thread "${THREADS}" \
    --html "${FASTP_HTML}" \
    --json "${FASTP_JSON}"

echo "Step 3/8: Running FastQC on trimmed reads"
# Trimmed FastQC checks whether read cleanup improved the input quality.
reset_generated_dir "${TRIMMED_FASTQC_SAMPLE_DIR}"
fastqc \
    --threads "${THREADS}" \
    --outdir "${TRIMMED_FASTQC_SAMPLE_DIR}" \
    "${TRIMMED_R1}" \
    "${TRIMMED_R2}"

echo "Step 4/8: Assembling the genome with SPAdes"
# SPAdes --isolate is suited to isolate bacterial genome assemblies.
reset_generated_dir "${SPADES_SAMPLE_DIR}"
spades.py \
    --isolate \
    -1 "${TRIMMED_R1}" \
    -2 "${TRIMMED_R2}" \
    --threads "${THREADS}" \
    --memory "${SPADES_MEMORY}" \
    -o "${SPADES_SAMPLE_DIR}"

if [[ ! -f "${CONTIGS}" ]]; then
    echo "ERROR: SPAdes contigs file was not created: ${CONTIGS}" >&2
    exit 1
fi

echo "Step 5/8: Evaluating assembly quality with QUAST"
# QUAST summarizes contig count, N50, total assembly length, and related metrics.
reset_generated_dir "${QUAST_SAMPLE_DIR}"
quast.py \
    "${CONTIGS}" \
    --threads "${THREADS}" \
    --output-dir "${QUAST_SAMPLE_DIR}"

echo "Step 6/8: Annotating contigs with Prokka"
# Prokka predicts genomic features and labels bacterial genes on the assembly.
reset_generated_dir "${PROKKA_SAMPLE_DIR}"
prokka \
--force \
    --outdir "${PROKKA_SAMPLE_DIR}" \
    --prefix "${SAMPLE_ID}" \
    --genus "${GENUS}" \
    --species "${SPECIES}" \
    --strain "${STRAIN}" \
    --cpus "${THREADS}" \
    "${CONTIGS}"

echo "Step 7/8: Running MultiQC summary report"
# MultiQC combines FastQC, fastp, QUAST, and other supported logs into one HTML report.
MULTIQC_DIR="${NOTES_DIR}/multiqc"
mkdir -p "${MULTIQC_DIR}"
multiqc "${PROJECT_DIR}" --outdir "${MULTIQC_DIR}" --force

echo "Step 8/8: Writing final pipeline summary"
# The summary gives a stable handoff point for downstream review and reporting.
cat > "${SUMMARY_FILE}" <<EOF
Bacterial genome pipeline summary
=================================
Sample ID: ${SAMPLE_ID}
Project directory: ${PROJECT_DIR}
Completed: $(date)

Inputs
------
Raw R1: ${R1}
Raw R2: ${R2}
Genus: ${GENUS}
Species: ${SPECIES}
Strain: ${STRAIN}
Threads: ${THREADS}
SPAdes memory (GB): ${SPADES_MEMORY}

Important outputs
-----------------
Raw FastQC folder: ${RAW_FASTQC_SAMPLE_DIR}
Trimmed R1: ${TRIMMED_R1}
Trimmed R2: ${TRIMMED_R2}
fastp HTML report: ${FASTP_HTML}
fastp JSON report: ${FASTP_JSON}
Trimmed FastQC folder: ${TRIMMED_FASTQC_SAMPLE_DIR}
SPAdes contigs: ${CONTIGS}
QUAST report folder: ${QUAST_SAMPLE_DIR}
Prokka annotation folder: ${PROKKA_SAMPLE_DIR}
Pipeline log: ${RUN_LOG}
MultiQC report folder: ${MULTIQC_DIR}
EOF

echo "Pipeline completed for sample: ${SAMPLE_ID}"
echo "Summary report: ${SUMMARY_FILE}"

