# SA tag–based fusion extraction and annotation scripts

This repository provides a set of shell scripts for extracting, annotating, and
filtering candidate gene fusions from short-read whole-genome sequencing (WGS) data
based on supplementary alignment (SA) tags.

The workflow was developed to support research analyses of structural variants
from formalin-fixed paraffin-embedded (FFPE) specimens, as described in the
associated manuscript.

---

## Purpose

The purpose of this pipeline is to **nominate candidate gene rearrangements**
from short-read WGS data by leveraging SA tags and soft-clipped reads, and to
annotate breakpoint coordinates with gene information and transcriptional
orientation.

This implementation is intended for **research use only** as a
**conceptual framework** for fusion nomination from FFPE-derived WGS data.
It is not designed as a comprehensive, optimized, or clinical-grade fusion
detection tool.

---

## Input

The pipeline requires the following input files:

1. **Aligned BAM file**
   - Coordinate-sorted BAM file generated from short-read WGS data
   - Supplementary alignments (SA tags) must be present
   - Reference genome build should match the gene annotation (e.g., GRCh38)

2. **Gene annotation file (GTF)**
   - Standard GTF file (plain text or gzipped)
   - Used to derive gene-level BED annotations for breakpoint annotation

---

## Output

All scripts generate plain text, tab-delimited files.

Key output files include:

- `*_bnd_sr_raw.tsv`  
  Read pairs containing SA tags extracted from the BAM file.

- `*_bnd_sr_bp.tsv`  
  Breakpoint coordinates computed from soft-clipped reads, including breakpoint
  side (LEFT/RIGHT/UNKNOWN) and reference-directional orientation.

- `*_genes.bed`  
  BED6-format gene annotation file derived from the input GTF file.

- `*_left_annot.tsv`  
  Gene name and transcriptional strand annotated for the left breakpoint.

- `*_right_annot.tsv`  
  Gene name and transcriptional strand annotated for the right breakpoint.

- `*_bnd_sr_bp_gene.tsv`  
  Merged table combining breakpoint coordinates with left- and right-side gene
  annotations.

- `*_bnd_direction_concordant.tsv`  
  Final list of fusion candidates filtered based on functional gene orientation
  concordance.

The resulting candidates are intended to be interpreted in conjunction with
orthogonal pathological validation (e.g., FISH, RNA sequencing).

---

## Scripts

### SA tag extraction and breakpoint computation

- `01_extract_sr_pairs.sh`  
  Extracts read pairs carrying SA tags from a BAM file, applying filters on
  mapping quality, edit distance, and local proximity.

- `02_compute_breakends.sh`  
  Computes breakpoint coordinates, breakpoint side, and reference coordinate
  direction based on CIGAR strings and soft-clipped segments.

- `03_gtf_to_genesbed.sh`  
  Converts a GTF file into a BED6-format gene annotation file.

### Breakpoint-to-gene annotation

- `04_annotate_left.sh`  
  Annotates the left breakpoint with gene name and transcriptional strand using
  BED overlap.

- `05_annotate_right.sh`  
  Annotates the right breakpoint with gene name and transcriptional strand using
  BED overlap.

- `06_merge_bp_gene.sh`  
  Merges breakpoint coordinates with left- and right-side gene annotations into
  a single table.

### Orientation-concordance filtering

- `07_direction_concordant.sh`  
  Filters annotated breakpoint pairs based on functional gene orientation
  concordance, taking breakpoint side and gene transcriptional strand into
  account.

Each script provides a `--help` option describing required arguments and
parameters.

---

## Recommended environment

The scripts were developed and tested in the following environment:

- Unix-like operating system (Linux / macOS)
- Bash (version 4 or later)
- `samtools` (version 1.10 or later)
- `bedtools`
- `gawk`
- Standard GNU core utilities

No Python or R dependencies are required.

---

## Limitations

- This pipeline does **not** assign statistical confidence scores or clinical
  significance to fusion candidates.
- Performance depends on read length, library preparation, and FFPE sample
  quality.
- All nominated rearrangements require **orthogonal validation**
  (e.g., fluorescence in situ hybridization or RNA sequencing).

---

## Disclaimer

**Clinical use not intended.**

These scripts are provided for **research and educational purposes only**.
They are **not validated for diagnostic or clinical decision-making** and must
not be used as a standalone clinical assay.

---

## Citation

If you use this code, please cite the associated publication describing the
methodology and its application to FFPE-derived whole-genome sequencing data.
