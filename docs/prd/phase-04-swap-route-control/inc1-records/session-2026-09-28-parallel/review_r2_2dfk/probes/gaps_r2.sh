#!/bin/bash
# r2 reviewer probes (bd 2dfk r2): planted edits OUTSIDE the four HD files, a
# golden edit, CQ_E2E_NO_CACHE, and an unlisted clang-steering env var.
# Each: cache WARM (populated by the unmodified tree first) vs CQ_E2E_NO_CACHE=1.
. "$(dirname "$0")/env.sh"
cd "$MY" || exit 2
P() { python3 "$SP/rev_r2_probes/plant.py" "$@" || exit 3; }
TT="$T1|$T4"
echo "== warm-up (unmodified)"; D "$TT" $C | tail -1
echo "== (A) free_pairing_check.py: main() returns 1 after printing (checker-source edit)"
P tools/free_pairing_check.py 'def main(argv=None):' 'def main(argv=None):
    print("PLANTED-CHECKER-REJECT"); return 1
def _orig_main(argv=None):'
echo -n "  WARM:     "; D "$TT" $C | tail -1
echo -n "  NO_CACHE: "; D "$TT" $C --nocache | tail -1
git checkout -q tools/free_pairing_check.py
echo "== (B) golden edit (theta-add-measure), warm"
G=tests/e2e/slice_theta_add_measure.expected.log
P $G "$(head -1 $G)" "$(head -1 $G) PLANTED"
echo -n "  WARM:     "; D '^e2e-slice-theta-add-measure$' $C | tail -1
echo -n "  NO_CACHE: "; D '^e2e-slice-theta-add-measure$' $C --nocache | tail -1
git checkout -q $G
echo "== (C) include/CQ.h edit with NO reconfigure (CQ_S1_BASE unchanged): '#error' appended"
printf '\n#error PLANTED-CQH\n' >> include/CQ.h
echo -n "  WARM:     "; D "$TT" $C | tail -1
echo -n "  NO_CACHE: "; D "$TT" $C --nocache | tail -1
git checkout -q include/CQ.h
echo "== (D) NO_CACHE ignores the run cache: corrupt theta-add-measure's recorded trace"
n=0; for f in $C/run/run/*.out; do if grep -q . "$f" && diff -q "$f" tests/e2e/slice_theta_add_measure.expected.log >/dev/null; then cp -f "$f" $SP/rev_r2_probes/saved.out; echo CORRUPT >> "$f"; n=$((n+1)); CF=$f; fi; done; echo "  corrupted $n entr(y/ies)"
echo -n "  WARM:     "; D '^e2e-slice-theta-add-measure$' $C | tail -1
echo -n "  NO_CACHE: "; D '^e2e-slice-theta-add-measure$' $C --nocache | tail -1
cp -f $SP/rev_r2_probes/saved.out "$CF"
echo "== (E) unlisted env var CLANG_NO_DEFAULT_CONFIG=1 (drops Homebrew's -isysroot cfg)"
echo -n "  WARM:     "; CLANG_NO_DEFAULT_CONFIG=1 D "$TT" $C | tail -1
echo -n "  NO_CACHE: "; CLANG_NO_DEFAULT_CONFIG=1 D "$TT" $C --nocache | tail -1
echo "== restored, warm"; D "$TT" $C | tail -1
git status --short
