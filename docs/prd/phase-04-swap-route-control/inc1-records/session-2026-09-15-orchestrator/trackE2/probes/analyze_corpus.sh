#!/bin/bash
# analyze_corpus.sh <corpus_<hash16>.txt> — the five questions a sweep is read for.
# A row is: <path>|<ORACLE verdict>|<SUBJECT verdict>|<ORACLE first stderr line>|<SUBJECT first stderr line>
# verdict = A:<md5 of lowered IR>:<sha of stderr>  or  D<exit>:<sha of stderr>
F=$1
echo "rows                 : $(grep -vc '^DONE' $F)"
echo "  of which fixtures  : $(grep -c '^ir-pass/test/' $F)"
echo "  of which probes    : $(grep -c '^docs/' $F)"
echo "VACUOUS / CLANGERR   : $(grep -c 'VACUOUS' $F) / $(grep -c 'CLANGERR' $F)"
echo "finished (DONE line) : $(grep -c '^DONE' $F)"
echo
echo "--- 1. MOVERS (verdict field differs) ---"
awk -F'|' '$2!=$3 && $2!~/VACUOUS|CLANGERR/ {print "  "$1" | "$2" -> "$3}' $F
echo "  total movers       : $(awk -F'|' '$2!=$3 && $2!~/VACUOUS|CLANGERR/' $F | wc -l | tr -d ' ')"
echo
echo "--- 2. D->A (the expected direction) / A->D (a REGRESSION) ---"
echo "  D->A : $(awk -F'|' '$2~/^D/ && $3~/^A:/' $F | wc -l | tr -d ' ')"
echo "  A->D : $(awk -F'|' '$2~/^A:/ && $3~/^D/' $F | wc -l | tr -d ' ')"
echo
echo "--- 3. A->A with a MOVED STREAM (lowered-IR md5 differs within the row) ---"
awk -F'|' '$2~/^A:/ && $3~/^A:/ {split($2,a,":"); split($3,b,":"); if(a[2]!=b[2]) print "  "$1}' $F
echo "  count: $(awk -F'|' '$2~/^A:/ && $3~/^A:/ {split($2,a,":"); split($3,b,":"); if(a[2]!=b[2]) print}' $F | wc -l | tr -d ' ')"
echo
echo "--- 4. D->D with a MOVED STRING (full-stderr sha differs; the tag regex is blind here) ---"
awk -F'|' '$2~/^D/ && $3~/^D/ {split($2,a,":"); split($3,b,":"); if(a[2]!=b[2]) print "  "$1"\n    O: "$4"\n    S: "$5}' $F
echo "  count: $(awk -F'|' '$2~/^D/ && $3~/^D/ {split($2,a,":"); split($3,b,":"); if(a[2]!=b[2]) print}' $F | wc -l | tr -d ' ')"
echo
echo "--- 5. A->A with MOVED STDERR (a WARNING appearing or vanishing on an accept) ---"
awk -F'|' '$2~/^A:/ && $3~/^A:/ {split($2,a,":"); split($3,b,":"); if(a[3]!=b[3]) print "  "$1"\n    O: "$4"\n    S: "$5}' $F
echo "  count: $(awk -F'|' '$2~/^A:/ && $3~/^A:/ {split($2,a,":"); split($3,b,":"); if(a[3]!=b[3]) print}' $F | wc -l | tr -d ' ')"
echo
echo "--- 6. ATTRIBUTION: every mover's ORACLE diagnostic, de-prefixed ---"
awk -F'|' '$2!=$3 && $2!~/VACUOUS|CLANGERR/ {print $4}' $F | sed 's/.*in function [^:]*: //' | sort | uniq -c
