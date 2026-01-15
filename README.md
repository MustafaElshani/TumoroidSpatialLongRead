# Long-read Spatial Transcriptomic Profiling of Patient-derived ccRCC Tumoroids

Analysis code for the manuscript: **"Long-read spatial transcriptomics of patient-derived clear cell renal cell carcinoma organoids identifies heterogeneity and transcriptional remodelling following NUC-7738 treatment"**

## Overview

R Markdown workflows for analyzing long-read spatial transcriptomics data from patient-derived ccRCC organoids. Combines ONT long-read sequencing with 10x Genomics Visium for gene-level and isoform-level spatial analysis.

### Data Generation

Nanopore libraries were basecalled using dorado SUP model (v0.7.0) and processed through epi2me-labs/wf-single-cell (v2.2.0) to generate gene and transcript count matrices. Spatial barcode positions were obtained by converting tagged BAM files to FASTQ format (`bam2fastq.sh`) and running Space Ranger to extract `tissue_positions.csv`. Expression matrices were analyzed in Giotto Suite with QC filtering, Leiden clustering, and scran-based differential expression.

## Data Structure

```         
./
├── DMSO/
│   ├── spaceranger_out_run2/outs/           # 10x Visium spatial data (tissue positions, images)
│   └── SR1040-610_DMSO/                     # wf-single-cell (Nanopore) output
│       ├── gene_raw_feature_bc_matrix/      # ONT gene-level counts (features.tsv, barcodes.tsv, matrix.mtx)
│       └── transcript_raw_feature_bc_matrix/ # ONT transcript-level counts (isoform quantification)
├── 30uM7738/                                 # NUC-7738 treated sample (same structure as DMSO)
│   ├── spaceranger_out_run2/outs/
│   └── SR1040-610_30uM7738/
│       ├── gene_raw_feature_bc_matrix/
│       └── transcript_raw_feature_bc_matrix/
├── results/
│   └── Giotto_*_results/                    # QC plots and intermediate outputs
├── GiottoSuite_*/                           # Saved Giotto objects (.RDS)
└── figures/
    └── paper_figures/
        ├── main/                            # Main manuscript figures (Fig 1-5)
        └── supplementary/                   # Supplementary figures and tables
```

## Analysis Pipeline

### 1. Preprocessing

``` bash
bash bam2fastq_ONT.sh   # Convert ONT BAM to FASTQ
```

### 2. Single-Sample Analysis

#### `GiottoSuite_ONTgene_DMSO.Rmd`

Control (DMSO) gene-level analysis:
- Load Visium + ONT counts → Giotto object
- QC metrics: %Mitochondrial and %Ribosomal content per spot
- QC filtering based on feature counts and expression levels
- Normalization → HVG → PCA → Leiden clustering
- scran marker gene identification

#### `GiottoSuite_ONTgene_30uM77738.Rmd`

Same pipeline for NUC-7738 (30µM) treated sample.

#### `GiottoSuite_ONTtrans.Rmd`

Single-sample transcript-level analysis from wf-single-cell (Nanopore) output:
- Load transcript counts from `transcript_raw_feature_bc_matrix/` (wf-single-cell output)
- Create Giotto object with Visium spatial coordinates
- QC: Gene-level filtering propagates to transcript analysis (same spatial coordinates)
- Normalization at transcript level
- Isoform-level spatial visualization

#### `GiottoSuite_ONTtrans_Combo.Rmd`

Combined transcript-level analysis with differential isoform usage:
1. Load pre-processed DMSO and NUC-7738 transcript Giotto objects
2. Join and normalize combined transcript data
3. **Harmony** batch correction across conditions
4. **DRIMSeq** differential transcript usage (DTU) analysis:
   - Compare isoform proportions between DMSO vs NUC-7738
   - Identify significantly altered transcript ratios
5. Isoform spatial visualization with ggtranscript
- **Figure 3**: GLS isoform expression (KGA vs GAC)
- **Figure 5**: UQCRQ isoform expression with DTU p-values

### 3. Combined Analysis

#### `GiottoSuite_ONTgene_Combo.Rmd`

DMSO vs NUC-7738 integration:
1. Join pre-processed Giotto objects
2. Normalize combined data
3. **Harmony** batch correction across tissue sections
4. Leiden clustering on Harmony-corrected space
5. **scran pseudobulk DE** (`findMarkers_one_vs_all`) by condition
- Output: `./figures/paper_figures/supplementary/normilized_PseudoBulk_DE_DMSOvsNUC7738_scran.csv`

### 4. Figure Generation

#### `Figure.Rmd`

Gene-level publication figures:
- **Figure 1**: Spatial Leiden clusters + marker gene heatmap + GO enrichment analysis
- **Figure 2**: Top marker gene spatial expression across clusters
- **Figure 4**: DMSO vs NUC-7738 gene expression comparison with spatial plots + violin plots (scran DE p-values)

#### `GiottoSuite_ONTtrans_Combo.Rmd`

Transcript/isoform-level publication figures:
- **Figure 3**: GLS isoform spatial expression
  - KGA (ENST00000320717) and GAC (ENST00000338435) spatial distribution
  - Transcript structure visualization with ggtranscript
  - DRIMSeq differential transcript usage statistics
- **Figure 5**: UQCRQ isoform spatial expression
  - ENST00000378670 and ENST00000378667 spatial distribution
  - Isoform structure visualization
  - Violin plots with DRIMSeq DTU p-values
  - Control (DMSO) vs NUC-7738 comparison

------------------------------------------------------------------------

## Author

**Dr Mustafa Elshani**\
University of St Andrews, School of Medicine\
North Haugh, St Andrews, Fife, KY16 9TF, UK

## Citation

> Abdullah, H., Zhang, Y., Kirkwood, K., Laird, A., Mullen, P., Harrison, D. J., & Elshani, M. (2026).  
> *Long-read spatial transcriptomics of patient-derived clear cell renal cell carcinoma organoids identifies heterogeneity and transcriptional remodelling following NUC-7738 treatment*.  
> **Cancers, 18**(2), 254.  
> https://doi.org/10.3390/cancers18020254


------------------------------------------------------------------------

## Session Information

```         
R version 4.4.3 (2025-02-28)
Platform: x86_64-conda-linux-gnu
Running under: Ubuntu 24.04.3 LTS

Key packages:
  Giotto          4.2.2
  GiottoClass     0.4.10
  GiottoVisuals   0.2.14
  scran           1.32.0
  scuttle         1.14.0
  SingleCellExperiment 1.26.0
  SpatialExperiment    1.14.0
  ggplot2         4.0.1
  patchwork       1.3.2
  cowplot         1.2.0
  enrichR         3.2
  data.table      1.17.8
  terra           1.8-42
  reticulate      1.44.1

Environment: giotto_env (conda)
```
