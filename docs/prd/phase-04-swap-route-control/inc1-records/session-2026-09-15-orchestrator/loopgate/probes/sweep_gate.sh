#!/bin/bash
# LOOP-GROUP MERGE GATE corpus sweep — one binary over one FIXED corpus.
#
# Reused from `loopfix/probes/sweep.sh` (Rule 14) with two deliberate changes:
#   (1) FULL-STDERR sha-256 instead of the shared tag regex. PROTOCOL S3: the
#       `corpus.sh` tag regex renders the whole `cq_measure_<sfx>` family as an
#       empty `D:`, so a decline→decline STRING move inside it is INVISIBLE.
#   (2) the lowered-IR sha-256 for accepts, with the `ModuleID`/`source_filename`
#       lines stripped so it IS comparable across sweeps (S3's "md5s are not
#       comparable ACROSS sweeps" is about the temp ModuleID; both sweeps read the
#       SAME corpus paths here, and the two volatile lines are removed anyway).
#
# ⚠ BOUNDARY CONTROLS — inherited, and they exist because the first spelling of
# the fix agent's script reported "0 MOVERS" while ALL 2050 ROWS WERE EXIT 127
# (CLAUDE.md L10). It refuses to emit a file unless the binary AND plugin exist,
# no row is 127, both verdict classes occur, and no module is 0 bytes (bd memory
# `empty-module-accepts-vacuity-trap`: a 0-byte .ll ACCEPTS through passthrough).
set -u
BD="$1"; OUT="$2"; CORPUS_ROOT="$3"
CQ="$BD/ir-pass/cq-opt"; PL="$BD/ir-pass/libCQPass.so"
[ -x "$CQ" ] || { echo "REFUSE: no executable at $CQ" >&2; exit 2; }
[ -f "$PL" ] || { echo "REFUSE: no plugin at $PL" >&2; exit 2; }
TMP="$OUT.part"; : > "$TMP"
HERE="$(cd "$(dirname "$0")" && pwd)"
JOBS="${JOBS:-4}"
LIST=$(mktemp); trap 'rm -f "$LIST"' EXIT
{ find "$CORPUS_ROOT/ir-pass/test" -name '*.ll' -size +0
  find "$CORPUS_ROOT/docs/prd/phase-04-swap-route-control/inc1-records" -path '*probes*' -name '*.ll' -size +0
} | sort > "$LIST"
# ⚠ ERRATUM, found by the gate agent against its OWN instrument (CLAUDE.md L10):
# the first spelling counted `nall` WITHOUT the `-path '*probes*'` filter, so
# "skipped-empty" silently reported `1 genuinely-empty + 7 out-of-scope` as `8`.
# The SWEEP was never affected (it iterates $LIST, which is filtered and non-empty);
# only the label lied. The count now uses the IDENTICAL predicate minus `-size +0`.
nall=$({ find "$CORPUS_ROOT/ir-pass/test" -name '*.ll'
         find "$CORPUS_ROOT/docs/prd/phase-04-swap-route-control/inc1-records" -path '*probes*' -name '*.ll'
       } 2>/dev/null | wc -l | tr -d ' ')
nempty=$(( nall - $(wc -l < "$LIST" | tr -d ' ') ))
xargs -P "$JOBS" -I{} "$HERE/sweep_row.sh" "$CQ" "$PL" "$CORPUS_ROOT" "{}" < "$LIST" | sort > "$TMP"
n127=$(grep -c '|D127|' "$TMP" || true)
nA=$(grep -c '|A|'   "$TMP" || true)
nD=$(grep -c '|D1|'  "$TMP" || true)
if [ "$n127" -ne 0 ] || [ "$nA" -lt 100 ] || [ "$nD" -lt 100 ]; then
  echo "REFUSE: sweep is not measuring the compiler (127=$n127 accepts=$nA declines=$nD)" >&2
  exit 2
fi
mv -f "$TMP" "$OUT"
echo "sweep OK: $(wc -l < "$OUT") rows, accepts=$nA declines=$nD, skipped-empty=$nempty"
