# Duck Host Transcriptome Meta-Analysis

RNA-seq meta-analysis of the duck (*Anas platyrhynchos*) host transcriptomic response to highly pathogenic avian influenza (HPAI) infection, combining four independently published studies into a unified differential expression and functional enrichment analysis.

## Studies included

| Study | Year | Reference (short) |
|---|---|---|
| Campbell | 2021 | Campbell et al. 2021, *Tissue-specific transcriptome changes upon influenza...* |
| Huang | 2013 | Huang et al. 2013, *The duck genome and transcriptome provide insight...* |
| Morris | 2023 | Morris et al. 2023, *The molecular basis of differential host responses...* |
| Smith | 2015 | Smith et al. 2015, *A comparative analysis of host responses to avian...* |

Each study challenged ducks with a highly pathogenic (HP) H5-clade influenza virus (clade varies by study — see the metadata) and profiled lung transcriptomes at one or more days post infection (dpi) alongside matched controls. Raw sequencing reads for all four studies were reprocessed from scratch through a single, consistent pipeline (below) so that per-study differential expression results are directly comparable before being statistically combined.

Because Huang et al. 2013 lacks biological replicates for its control condition (dispersion has to be borrowed from the other studies) and a reviewer specifically asked whether it was distorting the combined result, the repository includes a full parallel re-analysis with Huang excluded (`meta_analysis_without_huang.Rmd`) as a sensitivity check.

## Pipeline overview

The analysis runs in two stages: shell scripts that turn raw reads into gene-level count tables, and an R Markdown notebook that does everything from there (QC, differential expression, meta-analysis, and functional enrichment).

```
raw FASTQ
   │
   ▼
1. trim.sh          Adapter/quality trimming (Trim Galore)
   │
   ▼
2. map.sh            Read alignment to the duck genome (STAR)
   │
   ▼
3. count.sh           Gene-level read counting (featureCounts / Subread)
   │                   → counts_paired.txt / counts_single.txt
   ▼
4. meta_analysis.Rmd (or meta_analysis_without_huang.Rmd)
       2.  Load counts, metadata, and gene annotation
       3.  QC, PCA, low-count filtering, TMM normalisation (edgeR)
       4.  Per-study differential expression (edgeR GLM-LRT) + Venn diagrams
       5.  Cross-study p-value combination (weighted Fisher's method, `metapro`)
           + jackknife / robustness sensitivity analysis
       6.  Interactive result tables (DT)
       7.  Log fold-change bar plots, incl. a curated innate-immune gene panel
       8.  GO overrepresentation analysis (clusterProfiler + NCBI gene2go)
       9.  KEGG enrichment (organism "apla")
       10. KEGG pathway visualisation (pathview)
       11. Cross-study/cross-day KEGG & GO comparison (compareCluster)
       12. Publication-ready combined KEGG + GO figure
```

Steps 1–3 are one-off preprocessing and were run on a compute cluster (see the hard-coded paths inside each script — update these for your own environment before rerunning). Their output (`counts_paired.txt`, `counts_single.txt`) is what's shipped in this repo as `counts_paired.zip` / `counts_single.zip`, so step 4 can be reproduced without re-running 1–3.

## Repository contents

| File | Description |
|---|---|
| `trim.sh` | Trims raw FASTQ reads with Trim Galore. Runs paired-end trimming for the Campbell, Huang, and Morris studies and single-end trimming for Smith. |
| `map.sh` | Aligns trimmed reads to the duck reference genome with STAR, handling single-end and paired-end samples separately. |
| `count.sh` | Summarises aligned reads (SAM output from `map.sh`) to gene-level counts with `featureCounts` (Subread), against the NCBI RefSeq GTF annotation. Produces `counts_single.txt` and `counts_paired.txt`. |
| `counts_paired.zip` | Gene-level count matrix (`counts_paired.txt`) for all paired-end samples (Campbell, Huang, Morris), output of `count.sh`. Unzip before knitting the Rmd files. |
| `counts_single.zip` | Gene-level count matrix (`counts_single.txt`) for all single-end samples (Smith), output of `count.sh`. Unzip before knitting the Rmd files. |
| `metadata.csv` | Per-sample metadata: SRA run accession (`Run`), tissue (`organ`), `treatment` (control vs. HP challenge, with clade where applicable), `dpi`, `biological_replicate`, source `study`, and a derived `group` label used to build the edgeR design matrices. 161 samples across the four studies. |
| `GCF_047663525.1_IASCAAS_PekinDuck_T2T_feature_table.zip` | NCBI RefSeq feature table for the duck T2T reference genome assembly (GCF_047663525.1, IASCAAS_PekinDuck_T2T). Used to build the gene annotation table (Ensembl-style gene ID, symbol, Entrez ID, biotype, description, coordinates). |
| `duck_gene2go.tsv` | NCBI `gene2go` GO annotation for the duck genome, used for GO overrepresentation analysis (section 8) and to append GO terms in the without-Huang analysis. |
| `meta_analysis.Rmd` | **Main analysis.** Full differential expression + meta-analysis pipeline across all four studies (Campbell, Huang, Morris, Smith). Knit this to reproduce every main-text and supplementary figure/table. |
| `meta_analysis_without_huang.Rmd` | **Sensitivity analysis.** Identical pipeline with Huang excluded from every step (filtering, normalisation, dispersion estimation, testing, and the combined meta-analysis), addressing a reviewer question about Huang's influence on the combined result. Days 1 and 3 fall back to a two-study concordance rule (`robust` flag) instead of a true leave-one-out jackknife, since only Campbell and Smith remain at those timepoints; day 2 (Campbell + both Morris sub-strains) still supports a full jackknife. |
| `readme` | This file. |

## Requirements

**Command-line (steps 1–3):**
- [Trim Galore](https://github.com/FelixKrueger/TrimGalore) (and Cutadapt)
- [STAR](https://github.com/alexdobin/STAR) aligner, plus a STAR genome index built from the duck T2T assembly
- [Subread/featureCounts](https://subread.sourceforge.net/)

**R (≥ 4.3, step 4), packages used across the two `.Rmd` files:**
`dplyr`, `tidyr`, `stringr`, `purrr`, `ggplot2`, `edgeR`, `biomaRt`, `metapro`, `ggVennDiagram`, `UpSetR`, `DT`, `clusterProfiler`, `pathview`, `gage`, `gageData`, `grid`, `GO.db`, `patchwork`, `scales`, `enrichplot`, `KEGGREST`.

## Reproducing the analysis

1. Unzip `counts_paired.zip`, `counts_single.zip`, and `GCF_047663525.1_IASCAAS_PekinDuck_T2T_feature_table.zip` into the same directory as the `.Rmd` files.
2. Make sure `metadata.csv` and `duck_gene2go.tsv` are alongside them.
3. Open `meta_analysis.Rmd` (full analysis) or `meta_analysis_without_huang.Rmd` (Huang-excluded sensitivity analysis) in RStudio and knit, or run `rmarkdown::render()` from the R console. Each produces a self-contained HTML report plus a set of publication-ready figures (PNG/PDF) saved alongside it.

To regenerate the count matrices from raw reads instead of using the provided zips, run `trim.sh`, then `map.sh`, then `count.sh` in order — updating the hard-coded input/output paths at the top of each script for your own filesystem first.

## Outputs

Knitting either `.Rmd` produces:
- QC/PCA plots (raw and post-normalisation, per study and combined)
- Per-study and combined differential expression results, with Venn/UpSet diagrams of overlap
- A robustness/jackknife sensitivity flag per gene, per day post infection
- Interactive, sortable result tables (full and various significance/robustness subsets)
- Log fold-change bar plots, including a curated panel of innate-immune / antiviral genes
- GO and KEGG overrepresentation results, per study/day and combined
- KEGG pathway diagrams (Influenza A, TLR, NOD-like receptor, RIG-I-like receptor, apoptosis, necroptosis) with differentially expressed genes overlaid
- A final publication figure combining KEGG and GO enrichment across days post infection
