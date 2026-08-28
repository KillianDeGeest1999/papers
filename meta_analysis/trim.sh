#!/bin/bash

# Set the base directory and output folder
BASE_DIR="/data/kidege/meta_analysis"
OUTPUT_DIR="$BASE_DIR/trim"
CORES=8

# Loop through each subfolder
for folder in campbell huang morris smith; do
    echo "Processing folder: $folder"
    INPUT_DIR="$BASE_DIR/$folder"

    # Check if the folder is 'smith' (single-end)
    if [ "$folder" == "smith" ]; then
        for file in "$INPUT_DIR"/*.fastq.gz "$INPUT_DIR"/*.fq.gz; do
            if [ -f "$file" ]; then
                echo "Trimming single-end file: $(basename "$file")"
                trim_galore --cores $CORES -o "$OUTPUT_DIR" "$file"
            fi
        done
    else
        # For paired-end reads, find matching pairs
        for file in "$INPUT_DIR"/*_R1.fastq.gz "$INPUT_DIR"/*_1.fastq.gz; do
            if [ -f "$file" ]; then
                base=$(basename "$file" | sed -E 's/_R1|_1.*//')
                file1="$file"
                file2="$INPUT_DIR/${base}_2.fastq.gz"
                
                if ls $file2 1> /dev/null 2>&1; then
                    echo "Trimming paired-end files: $(basename "$file1") and $(basename "$file2")"
                    trim_galore --cores $CORES --paired -o "$OUTPUT_DIR" "$file1" "$file2"
                else
                    echo "Warning: Paired file for $file1 not found. Skipping."
                fi
            fi
        done
    fi

done

echo "Trimming complete!"

# Let me know if you’d like me to tweak anything! ??
