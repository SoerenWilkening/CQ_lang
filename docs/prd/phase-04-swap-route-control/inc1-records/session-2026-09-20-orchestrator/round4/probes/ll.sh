#!/bin/zsh
# ll.sh <file.ll> [--oracle]  — run the pass on one .ll, key every line to the binary.
# Prints: EXIT, stderr (diagnostic), then stage-2b + the gate stream when it accepted.
set -u
LLVM=/usr/local/opt/llvm@19/bin
WT=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a34343933d983a536
MAIN=/Users/sorenwilkening/Desktop/Projects/CQ_lang
F="$1"
MODE="${2:-subject}"
if [ "$MODE" = "--oracle" ]; then
  OPT="$MAIN/build/ir-pass/cq-opt"; PLUG="$MAIN/build/ir-pass/libCQPass.so"
else
  OPT="$WT/build/ir-pass/cq-opt"; PLUG="$WT/build/ir-pass/libCQPass.so"
fi
B=$(basename "$F" .ll)
OUT=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad/out
mkdir -p "$OUT"
# NULL CONTROL on the harness: the file must exist and be non-empty (the
# 0-byte-module passthrough vacuity trap, CLAUDE.md L10).
if [ ! -s "$F" ]; then echo "HARNESS-ABORT: $F is empty or missing"; exit 9; fi
echo "### $B  [$MODE]  bin=$(shasum -a 256 "$OPT" | cut -c1-16)"
"$OPT" -load-pass-plugin "$PLUG" -passes=cq-lowering -S "$F" -o "$OUT/$B.s2.ll" 2> "$OUT/$B.err"
rc=$?
echo "EXIT=$rc"
if [ -s "$OUT/$B.err" ]; then echo "--- stderr ---"; cat "$OUT/$B.err"; fi
if [ $rc -ne 0 ]; then exit $rc; fi
if [ ! -s "$OUT/$B.s2.ll" ]; then echo "VACUITY: lowered module is EMPTY"; exit 8; fi
echo "--- stage 2b ---"
python3 "$MAIN/tools/free_pairing_check.py" "$OUT/$B.s2.ll" 2>&1 | tail -20
echo "--- link+run ---"
"$LLVM/clang" "$OUT/$B.s2.ll" "$WT/build/runtime/libcq_templates.a" "$WT/build/runtime/libcq_runtime.a" -o "$OUT/$B.exe" 2>&1 | grep -v "built for newer" | head -20
if [ -x "$OUT/$B.exe" ]; then
  "$OUT/$B.exe" > "$OUT/$B.trace" 2>&1; echo "run rc=$?"
  echo "--- trace ($(wc -l < "$OUT/$B.trace") lines) ---"; cat "$OUT/$B.trace"
fi
