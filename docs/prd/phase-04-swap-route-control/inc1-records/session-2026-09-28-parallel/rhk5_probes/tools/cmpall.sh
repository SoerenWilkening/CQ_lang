#!/bin/bash
# cmpall.sh BIN ARG SUBJ:TWIN ... : for each pair in src/, cmp.sh + a one-line census of the subject
R=$(cd $(dirname $0) && pwd)
B=$1; A=$2; shift 2
cd $R/../src
for p in "$@"; do
  s=${p%%:*}; t=${p##*:}
  echo "=== $s vs $t  (bin=$B arg=$A)"
  bash $R/cmp.sh $B $s.s1.ll $t.s1.ll $A
done
