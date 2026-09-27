#!/bin/bash
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
cd "$(dirname "$0")"
ref=$(CQ_NOFREE=1 ./multi.sh $S/r1B/cq-opt.instr $1 1 | awk '{print $2" "$3}')
echo "$1 REF[$ref] SUBJ $(./multi.sh $S/r1B/cq-opt.subj $1 12) || ORA $(./multi.sh $S/r1B/cq-opt.ora $1 2)"
