
#!/usr/bin/env bash
set -euo pipefail

usage(){ cat <<__EOT__
Usage:
07_direction_concordant.sh -i bnd_sr_bp_gene.tsv -o outdir -p prefix
__EOT__
}

IN=""
OUTDIR="."
PREFIX="sample"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i) IN="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -p) PREFIX="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown: $1"; usage; exit 1;;
  esac
done

[[ -f "$IN" ]] || { echo "Not found: $IN" >&2; exit 1; }
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PREFIX}_bnd_direction_concordant.tsv"

gawk '
BEGIN{
  OFS="\t"
  # ヘッダー（列名）を先頭に出力
  print "chr1","bp1","side1","dir1","geneA","strandA","chr2","bp2","side2","dir2","geneB","strandB","geneA&geneB"
}
function tdown(str){ return (str=="+") ? +1 : (str=="-") ? -1 : 0 }
function expect_dir(side, sgn){
  # LEFT なら gene strand と同符号、RIGHT なら反転、UNKNOWN は既定で同符号扱い
  if (side=="LEFT")  return sgn
  if (side=="RIGHT") return -sgn
  return sgn
}
{
  chr1=$1; bp1=$2+0; side1=toupper($3); dir1=$4+0;
  chr2=$5; bp2=$6+0; side2=toupper($7); dir2=$8+0;
  geneA=$9;  strandA=$10;
  geneB=$11; strandB=$12;

  da = tdown(strandA);
  db = tdown(strandB);
  if (da==0 || db==0) next  # strand 不明は除外（必要ならここを緩和）

  exp1 = expect_dir(side1, da);
  exp2 = expect_dir(side2, db);

  # UNKNOWN 側はドントケアにする（片側一致で可）
  ok1 = (side1=="UNKNOWN") ? 1 : (dir1 == exp1);
  ok2 = (side2=="UNKNOWN") ? 1 : (dir2 == exp2);

  if (ok1 && ok2) {
    pair = geneA "&" geneB              # geneA&geneB の新列
    print chr1,bp1,side1,dir1,geneA,strandA,chr2,bp2,side2,dir2,geneB,strandB,pair
  }
}
' "$IN" > "$OUT"

echo "$OUT"
