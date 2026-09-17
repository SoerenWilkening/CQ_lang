#!/bin/zsh
# c.sh <file.c> [--oracle] [-g]  — full C pipeline, keyed to the binary hash.
set -u
LLVM=/usr/local/opt/llvm@19/bin
WT=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a34343933d983a536
MAIN=/Users/sorenwilkening/Desktop/Projects/CQ_lang
F="$1"; MODE="${2:-subject}"; DBG="${3:-}"
if [ "$MODE" = "--oracle" ]; then
  OPT="$MAIN/build/ir-pass/cq-opt"; PLUG="$MAIN/build/ir-pass/libCQPass.so"
else
  OPT="$WT/build/ir-pass/cq-opt"; PLUG="$WT/build/ir-pass/libCQPass.so"
fi
B=$(basename "$F" .c)
OUT=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad/out
mkdir -p "$OUT"
if [ ! -s "$F" ]; then echo "HARNESS-ABORT: $F empty/missing"; exit 9; fi
echo "### $B  [$MODE $DBG]  bin=$(shasum -a 256 "$OPT" | cut -c1-16)"
"$LLVM/clang" -I"$WT/include" -include CQ.h -O1 $DBG -emit-llvm -S "$F" -o "$OUT/$B.s1.ll" || { echo "STAGE1 FAILED"; exit 7; }
if [ ! -s "$OUT/$B.s1.ll" ]; then echo "VACUITY: stage-1 module empty"; exit 8; fi
"$OPT" -load-pass-plugin "$PLUG" -passes=cq-lowering -S "$OUT/$B.s1.ll" -o "$OUT/$B.s2.ll" 2> "$OUT/$B.err"
rc=$?
echo "EXIT=$rc"
if [ -s "$OUT/$B.err" ]; then echo "--- stderr ---"; head -12 "$OUT/$B.err"; fi
if [ $rc -ne 0 ]; then exit 0; fi
echo "--- stage 2b ---"
python3 "$MAIN/tools/free_pairing_check.py" "$OUT/$B.s2.ll" 2>&1 | tail -12
echo "--- link+run ---"
"$LLVM/clang" "$OUT/$B.s2.ll" "$WT/build/runtime/libcq_templates.a" "$WT/build/runtime/libcq_runtime.a" -o "$OUT/$B.exe" 2>&1 | grep -v "built for newer\|overriding the module target\|warning generated" | head -10
if [ -x "$OUT/$B.exe" ]; then
  "$OUT/$B.exe" > "$OUT/$B.trace" 2>&1; echo "run rc=$?"
  echo "--- trace ($(wc -l < "$OUT/$B.trace") lines) ---"; cat "$OUT/$B.trace"
fi
