
#!/usr/bin/env bash
set -euo pipefail

usage(){ cat <<__EOT__
Usage:
03_gtf_to_genesbed.sh -g genes.gtf[.gz] -o outdir -p prefix
__EOT__
}

GTF=""
OUTDIR="."
PREFIX="sample"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g) GTF="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -p) PREFIX="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown: $1"; usage; exit 1;;
  esac
done

[[ -f "$GTF" ]] || { echo "GTF not found: $GTF" >&2; exit 1; }
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PREFIX}_genes.bed"

if [[ "$GTF" == *.gz ]]; then CAT="zcat"; else CAT="cat"; fi

# 可能ならロケール固定（正規表現や分類の挙動を一定化）
export LC_ALL=C

$CAT "$GTF" \
| tr -d '\r' \
| gawk 'BEGIN{FS="\t"; OFS="\t"}
# コメント行はスキップ
/^#/ { next }

# gene 行のみ対象
$3=="gene" {
  attrs=$9

  # まず gene_name を探す（"gene_name" の前後空白にもある程度ロバスト）
  gene="NA"
  if (match(attrs, /gene_name *"([^"]+)"/, m)) {
    gene = m[1]
  } else if (match(attrs, /gene_id *"([^"]+)"/, m)) {
    # フォールバック：gene_name が無い場合は gene_id
    gene = m[1]
  } else if (match(attrs, /gene *"([^"]+)"/, m)) {
    gene = m[1]
  } else if (match(attrs, /Name *"([^"]+)"/, m)) {
    gene = m[1]
  } else if (match(attrs, /gene_symbol *"([^"]+)"/, m)) {
    gene = m[1]
  }

  # BED6: chrom, start(0-based), end(1-based), name, score, strand
  print $1, $4-1, $5, gene, ".", $7
}' > "$OUT"

echo "$OUT"
