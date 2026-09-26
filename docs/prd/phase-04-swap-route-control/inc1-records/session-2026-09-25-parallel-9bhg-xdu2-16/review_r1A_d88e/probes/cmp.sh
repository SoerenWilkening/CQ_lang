#!/bin/bash
# cmp.sh REF.tsv SUB.tsv : classify movers (A->D, D->A, STREAM, DIAG, STDERR); prints denominator
join -t$'\t' <(cut -f1-5 "$1") <(cut -f1-5 "$2") | awk -F'\t' '
 {n++} $2!=$6||$3!=$7||$4!=$8 { if($2==0&&$6!=0)c="A->D"; else if($2!=0&&$6==0)c="D->A"; else if($2==0&&$6==0)c="STREAM"; else if($5!=$9)c="DIAG"; else c="STDERR"; m[c]++; print c"\t"$1 }
 END { printf "denominator %d;", n; for (k in m) printf " %s=%d", k, m[k]; printf "\n" }'
