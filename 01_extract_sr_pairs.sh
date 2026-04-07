#!/usr/bin/env bash
set -euo pipefail

usage(){ cat <<__EOT__
Usage:
  01_extract_sr_pairs.sh -b input.bam -o outdir -p prefix \
     [--mapq-min 20] [--nm-max 5] [--near-dist 500]
__EOT__
}

MAPQ_MIN=20
NM_MAX=5
NEAR_DIST=500
BAM=""
OUTDIR="."
PREFIX="sample"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) BAM="$2"; shift 2;;
    -o) OUTDIR="$2"; shift 2;;
    -p) PREFIX="$2"; shift 2;;
    --mapq-min) MAPQ_MIN="$2"; shift 2;;
    --nm-max) NM_MAX="$2"; shift 2;;
    --near-dist) NEAR_DIST="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown: $1"; usage; exit 1;;
  esac
done

[[ -f "$BAM" ]] || { echo "BAM not found: $BAM" >&2; exit 1; }
mkdir -p "$OUTDIR"
OUT="$OUTDIR/${PREFIX}_bnd_sr_raw.tsv"

samtools view -h -F 0x4 -F 0x100 -F 0x200 -F 0x400 -q "$MAPQ_MIN" "$BAM" \
| awk -v MAPQ_MIN="$MAPQ_MIN" -v NM_MAX="$NM_MAX" -v NEAR_DIST="$NEAR_DIST" '
BEGIN{OFS="\t"}
$0 ~ /^@/ {next}
function primary_strand(flag) { return (int(flag/16)%2==1) ? "-" : "+" }
{
  qname=$1; flag=$2+0; chr1=$3; pos1=$4+0; mapq1=$5+0; cigar1=$6;
  str1 = primary_strand(flag)
  sa=""
  for(i=12;i<=NF;i++){ if ($i ~ /^SA:Z:/) { sa=substr($i,6); break } }
  if (sa=="") next;
  n=split(sa, arr, ";")
  for (j=1; j<=n; j++){
    if (arr[j]=="") continue
    m=split(arr[j], f, ",")
    if (m!=6) continue
    chr2=f[1]; pos2=f[2]+0; str2=f[3]; cigar2=f[4]; mapq2=f[5]+0; nm2=f[6]+0;
    if (mapq1<MAPQ_MIN || mapq2<MAPQ_MIN) continue;
    if (nm2>NM_MAX) continue;
    if (chr2==chr1){
      d = pos2 - pos1;
      if (d>=-NEAR_DIST && d<=NEAR_DIST) continue;
    }
    print chr1,pos1,str1,cigar1,chr2,pos2,str2,cigar2,mapq1,mapq2,qname
  }
}' > "$OUT"

echo "$OUT"
