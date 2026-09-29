#!/bin/bash
# ab_all.sh SUBJECT OUTDIR : corpus A/B of the frozen ORACLE vs SUBJECT over the four
# lists mkcorpus.py wrote (lit, e2e, multi, probes), each with its own null control.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
D="$(cd "$(dirname "$0")" && pwd)"
ORA="${ORA:-$S/frozen/cq-opt.main_9a230646}"   # ROUND 3: ORA=<frozen main ba4fdad4> after the merge
SUBJ=$1; OUT=$2
mkdir -p "$OUT"
shasum -a 256 "$ORA" "$SUBJ" > "$OUT/binaries.txt"
for set in lit e2e multi probes; do
  python3 "$D/ab.py" "$ORA" "$SUBJ" "$S/cepm/corpus/$set.txt" "$set" > "$OUT/ab_$set.txt" 2>&1
done
echo ALLDONE > "$OUT/done"
