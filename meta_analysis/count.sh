#!/bin/bash

# Set paths
MAP_DIR="/data/kidege/meta_analysis_new/map"
OUTPUT_DIR="/data/kidege/meta_analysis_new/count"
GTF_FILE="/data/kidege/reference/ncbi_dataset/data/GCF_047663525.1/genomic.gtf"
LOG_FILE="featureCounts.log"
THREADS=20

# Create output directory if not exists
mkdir -p "$OUTPUT_DIR"

# Find single-end and paired-end SAM files
single_end_files=($(find "$MAP_DIR" -name "*_single_*.sam"))
paired_end_files=($(find "$MAP_DIR" -name "*_paired_*.sam"))

# Run featureCounts for single-end files
if [ ${#single_end_files[@]} -gt 0 ]; then
    echo "Counting features for single-end files..."
    featureCounts -T $THREADS \
                  -t exon \
                  -g gene_id \
                  -a "$GTF_FILE" \
                  -o "$OUTPUT_DIR/counts_single.txt" \
                  "${single_end_files[@]}" > "$LOG_FILE" 2>&1
else
    echo "No single-end SAM files found."
fi

# Run featureCounts for paired-end files
if [ ${#paired_end_files[@]} -gt 0 ]; then
    echo "Counting features for paired-end files..."
    featureCounts -T $THREADS \
                  -p -B -C \
                  -t exon \
                  -g gene_id \
                  -a "$GTF_FILE" \
                  -o "$OUTPUT_DIR/counts_paired.txt" \
                  "${paired_end_files[@]}" >> "$LOG_FILE" 2>&1
else
    echo "No paired-end SAM files found."
fi


# Done
echo "Feature counting complete! Check results in: $OUTPUT_DIR"
