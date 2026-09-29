#!/bin/bash
# ab_r2.sh : round 2's corpus A/B. Rebuild the corpus (now incl. both reviewers' batteries), run
# the NULL control (SUBJECT vs SUBJECT) FIRST, then `main` ba4fdad4 -> SUBJECT (the landing
# delta) and the merged pre-fix build M -> SUBJECT (round 2's own delta), plus the drop census.
set -u
H=$(cd "$(dirname "$0")" && pwd); T=$H/../tools; R=$H/../results/r2
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
S=$SP/nlfd/bin/cq-opt.R2; OB=$SP/frozen/cq-opt.main_ba4fdad4; M=$SP/nlfd/bin/cq-opt.M
mkdir -p "$R"
rm -rf "$SP/nlfd/corpus"
python3 "$T/ab.py" --build > "$R/ab_corpus_build.txt" 2>&1
python3 "$T/ab.py" "$S" "$S" > "$R/ab_null_SS.txt" 2>&1
python3 "$T/ab.py" "$OB" "$S" > "$R/ab_OB_S.txt" 2>&1
python3 "$T/ab.py" "$M" "$S" > "$R/ab_M_S.txt" 2>&1
python3 "$T/census.py" "$OB" "$S" > "$R/census_OB_S.txt" 2>&1
echo done
