
#!/usr/bin/env bash
set -euo pipefail

usage(){ cat <<__EOT__
Usage:
06_merge_bp_gene.sh -b bnd_sr_bp.tsv -l left_annot.tsv -r right_annot.tsv \
  -o outdir -p prefix
__EOT__
}

BP=""
LEFT=""
RIGHT=""
OUTDIR="."
PREFIX="sample"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) BP="$2"; shift 2;;
    -l) LEFT="$2"; shift 2;;
    -r) RIGHT="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -p) PREFIX="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown: $1"; usage; exit 1;;
  esac
done

[[ -f "$BP" ]]   || { echo "Not found: $BP" >&2;   exit 1; }
[[ -f "$LEFT" ]] || { echo "Not found: $LEFT" >&2; exit 1; }
[[ -f "$RIGHT" ]]|| { echo "Not found: $RIGHT" >&2;exit 1; }

mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PREFIX}_bnd_sr_bp_gene.tsv"

paste "$BP" "$LEFT" "$RIGHT" > "$OUT"

echo "$OUT"
