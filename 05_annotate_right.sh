
#!/usr/bin/env bash
set -euo pipefail

usage(){ cat <<__EOT__
Usage:
05_annotate_right.sh -i bnd_sr_bp.tsv -b genes.bed -o outdir -p prefix
__EOT__
}

BP=""
BED=""
OUTDIR="."
PREFIX="sample"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i) BP="$2"; shift 2;;
    -b) BED="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -p) PREFIX="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown: $1"; usage; exit 1;;
  esac
done

[[ -f "$BP" ]]  || { echo "Input not found: $BP"  >&2; exit 1; }
[[ -f "$BED" ]] || { echo "BED not found: $BED"   >&2; exit 1; }
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PREFIX}_right_annot.tsv"

export LC_ALL=C
# A = BED3 + rid（4列固定）
gawk 'BEGIN{OFS="\t"}{print $5,$6,$6+1, NR}' "$BP" \
| bedtools intersect -a - -b "$BED" -loj \
| gawk 'BEGIN{OFS="\t"}
{
  rid = $4
  if (seen[rid]++) next
  gene   = $8
  strand = $10
  if (gene == ".")   gene = "NA"
  if (strand == ".") strand = "."
  print gene, strand
}' > "$OUT"

echo "$OUT"
