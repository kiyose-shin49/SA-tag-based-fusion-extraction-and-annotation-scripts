
#!/usr/bin/env bash
set -euo pipefail

usage(){ cat <<__EOT__
Usage:
02_compute_breakends.sh -i bnd_sr_raw.tsv -o outdir -p prefix [--s-min 20]
__EOT__
}

IN=""
OUTDIR="."
PREFIX="sample"
S_MIN=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i) IN="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -p) PREFIX="$2"; shift 2;;
    --s-min) S_MIN="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown: $1"; usage; exit 1;;
  esac
done

[[ -f "$IN" ]] || { echo "Input not found: $IN" >&2; exit 1; }
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PREFIX}_bnd_sr_bp.tsv"

# gawk を明示的に使用
gawk -v S_MIN="$S_MIN" '
BEGIN{
  OFS="\t"
}

function leftS(c, m){
  return match(c, /^([0-9]+)S/, m) ? m[1]+0 : 0
}

function rightS(c, m){
  return match(c, /([0-9]+)S$/, m) ? m[1]+0 : 0
}

# CIGAR の参照長（M/D/N/= /X を参照長に加算）
function refLen(c, i, num, ch, len){
  len=0; i=1
  while (i <= length(c)) {
    num=""
    while (i <= length(c) && substr(c,i,1) ~ /[0-9]/) { num = num substr(c,i,1); i++ }
    ch = substr(c,i,1); i++
    if (ch=="M" || ch=="D" || ch=="N" || ch=="=" || ch=="X") len += num+0
  }
  return len
}

# 端（LEFT/RIGHT/UNKNOWN）と座標（bp）、向き（dir: +1/-1/0）を決定
function side_and_dir(cigar, strand, pos,   l, r, side, bp, dir){
  l = leftS(cigar)
  r = rightS(cigar)
  if (r > 0) {
    side = "RIGHT"
    bp   = pos + refLen(cigar) - 1
  } else if (l > 0) {
    side = "LEFT"
    bp   = pos
  } else {
    side = "UNKNOWN"
    bp   = pos
  }

  if (strand == "+") {
    dir = (side == "RIGHT") ? +1 : -1
  } else if (strand == "-") {
    dir = (side == "RIGHT") ? -1 : +1
  } else {
    dir = 0
  }
  # ここは OFS で結合（split 時は FS ではなく、明示的に OFS を使って返す）
  return side OFS bp OFS dir
}

{
  chr1   = $1
  pos1   = $2+0
  strand1= $3
  cigar1 = $4
  chr2   = $5
  pos2   = $6+0
  strand2= $7
  cigar2 = $8

  split(side_and_dir(cigar1, strand1, pos1), a, OFS)
  side1 = a[1]; bp1 = a[2]+0; dir1 = a[3]+0

  split(side_and_dir(cigar2, strand2, pos2), b, OFS)
  side2 = b[1]; bp2 = b[2]+0; dir2 = b[3]+0

  # どちらかの read に S（ソフトクリップ）が S_MIN 以上あれば出力
  if ( (leftS(cigar1) >= S_MIN || rightS(cigar1) >= S_MIN) \
    || (leftS(cigar2) >= S_MIN || rightS(cigar2) >= S_MIN) )
  {
    print chr1, bp1, side1, dir1, chr2, bp2, side2, dir2
  }
}
' "$IN" > "$OUT"

echo "$OUT"
