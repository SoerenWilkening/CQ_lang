#!/bin/bash
# Re-derive a rolled-vs-hand-unrolled pair on a given build, reporting BOTH the
# trace-LINE count and the gate-symbol MULTISET.
# ⚠ CLAUDE.md / loopfix §3: "A LINE-COUNT EQUALITY IS NOT A MULTISET EQUALITY."
#   The loopfix depth-3 probe read as 72 == 72 while the multiset was 12/8 vs 10/10.
# Usage: rederive.sh <build-dir> <probe.c> <probe_un.c> <outdir>
set -euo pipefail
L=/usr/local/opt/llvm@19/bin
BD="$1"; A="$2"; B="$3"; OUT="$4"
test -x "$BD/ir-pass/cq-opt" || { echo "SELF-CHECK FAIL: no cq-opt at $BD" >&2; exit 2; }
test -f "$BD/ir-pass/libCQPass.so" || { echo "SELF-CHECK FAIL: no plugin at $BD" >&2; exit 2; }
mkdir -p "$OUT"
run1() {
  local src="$1" tag="$2"
  "$L/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S "$src" -o "$OUT/$tag.s1.ll"
  test -s "$OUT/$tag.s1.ll" || { echo "SELF-CHECK FAIL: empty stage-1 for $tag" >&2; exit 2; }
  if ! "$BD/ir-pass/cq-opt" -passes=cq-lowering -S "$OUT/$tag.s1.ll" -o "$OUT/$tag.s2.ll" 2>"$OUT/$tag.err"; then
    echo "$tag DECLINE: $(head -1 "$OUT/$tag.err")"; return 0
  fi
  "$L/clang" "$OUT/$tag.s2.ll" "$BD/runtime/libcq_templates.a" "$BD/runtime/libcq_runtime.a" -o "$OUT/$tag.exe" 2>/dev/null
  "$OUT/$tag.exe" > "$OUT/$tag.trace"
  echo "$tag ACCEPT lines=$(wc -l < "$OUT/$tag.trace" | tr -d ' ')"
  sed 's/(.*//' "$OUT/$tag.trace" | sort | uniq -c > "$OUT/$tag.mset"
}
ta=$(basename "$A" .c); tb=$(basename "$B" .c)
run1 "$A" "$ta"; run1 "$B" "$tb"
if [ -f "$OUT/$ta.mset" ] && [ -f "$OUT/$tb.mset" ]; then
  echo "--- gate-symbol MULTISET delta ($ta vs $tb) ---"
  if diff "$OUT/$ta.mset" "$OUT/$tb.mset" > "$OUT/$ta.msetdiff"; then
    echo "MULTISET DELTA EMPTY"
  else
    cat "$OUT/$ta.msetdiff"; echo "MULTISET DELTA NON-EMPTY"
  fi
  echo "--- byte diff ---"
  if diff "$OUT/$ta.trace" "$OUT/$tb.trace" > "$OUT/$ta.tracediff"; then
    echo "TRACE BYTE-IDENTICAL"
  else
    echo "TRACE DIFFERS (positional); see $OUT/$ta.tracediff"
  fi
fi
