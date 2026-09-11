#!/usr/bin/env bash
# ab.sh <name>  —  runs <name>.c (or <name>.s1.ll) through BOTH binaries.
#   ORACLE  = /Users/sorenwilkening/Desktop/CQ_lang        (main 0c7380c, read-only)
#   SUBJECT = /Users/sorenwilkening/Desktop/CQ_b6ap        (branch merge-phi-peel)
# Prints exit code, the first diagnostic lines, the runtime trace and stage 2b.
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_b6ap
LLVM=/usr/local/opt/llvm@19/bin
SP="$(cd "$(dirname "$0")" && pwd)"
N=$1
cd "$SP"
if [ -f "$N.c" ]; then
  "$LLVM/clang" -I"$ORACLE/include" -include CQ.h -O1 -emit-llvm -S "$N.c" -o "$N.s1.ll" || exit 9
fi
for W in ORACLE SUBJECT; do
  if [ $W = ORACLE ]; then R=$ORACLE; T=o; else R=$SUBJ; T=s; fi
  "$R/build/ir-pass/cq-opt" -load-pass-plugin "$R/build/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$N.s1.ll" -o "$N.$T.ll" > /dev/null 2> "$N.$T.err"
  RC=$?
  echo "=== $W  exit=$RC ==="
  sed -n '1,6p' "$N.$T.err"
  if [ $RC -eq 0 ]; then
    "$LLVM/clang" "$N.$T.ll" "$R/build/runtime/libcq_templates.a" "$R/build/runtime/libcq_runtime.a" \
        -o "$N.$T.exe" 2>/dev/null && { ./"$N.$T.exe" > "$N.$T.trace" 2>&1
        echo "--- trace ($(wc -l < "$N.$T.trace") lines) ---"; cat "$N.$T.trace"; } \
        || echo "LINK-OR-RUN-FAIL (probe-local: an undefined extern, not a compiler failure)"
    echo "--- 2b ---"; (cd "$R" && python3 tools/free_pairing_check.py "$SP/$N.$T.ll" 2>&1 | tail -1)
  fi
done
