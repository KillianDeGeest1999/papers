#!/bin/bash

# Set paths and parameters
TRIM_DIR="/data/kidege/meta_analysis_old/trim"
OUTPUT_DIR="/data/kidege/meta_analysis_new/map"
GENOME_DIR="/data/kidege/reference/duck_star_index_t2t"
THREADS=20

# Process single-end files
echo "Processing single-end files..."
for file in "$TRIM_DIR"/*_trimmed.fq.gz; do
    if [ -f "$file" ]; then
        base=$(basename "$file" | sed -E 's/_trimmed\.fq\.gz//')
        echo "Mapping single-end reads: $file"
        STAR --runThreadN $THREADS \
             --genomeDir "$GENOME_DIR" \
             --readFilesIn "$file" \
             --readFilesCommand gunzip -c \
             --outFileNamePrefix "$OUTPUT_DIR/${base}_single_"
    fi
done

# Process paired-end files
echo "Processing paired-end files..."
for file in "$TRIM_DIR"/*_1_val_1.fq.gz; do
    if [ -f "$file" ]; then
        base=$(basename "$file" | sed -E 's/_1_val_1\.fq\.gz//')
        pair_file="$TRIM_DIR/${base}_2_val_2.fq.gz"
        
        if [ -f "$pair_file" ]; then
            echo "Mapping paired-end reads: $file and $pair_file"
            STAR --runThreadN $THREADS \
                 --genomeDir "$GENOME_DIR" \
                 --readFilesIn "$file" "$pair_file" \
                 --readFilesCommand gunzip -c \
                 --outFileNamePrefix "$OUTPUT_DIR/${base}_paired_"
        else
            echo "Warning: Paired file for $file not found. Skipping."
        fi
    fi
done


echo "Mapping complete!"
