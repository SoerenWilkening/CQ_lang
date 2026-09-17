#!/bin/zsh
# pass.sh <file.ll> [--oracle] — run ONLY the pass, CPU-limited, print exit + stderr.
set -u
ulimit -t 30
WT=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a34343933d983a536
MAIN=/Users/sorenwilkening/Desktop/Projects/CQ_lang
F="$1"; MODE="${2:-subject}"
if [ "$MODE" = "--oracle" ]; then
  OPT="$MAIN/build/ir-pass/cq-opt"; PLUG="$MAIN/build/ir-pass/libCQPass.so"
else
  OPT="$WT/build/ir-pass/cq-opt"; PLUG="$WT/build/ir-pass/libCQPass.so"
fi
B=$(basename "$F" .ll)
OUT=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad/out
mkdir -p "$OUT"
if [ ! -s "$F" ]; then echo "HARNESS-ABORT: $F empty/missing"; exit 9; fi
echo "### $B [$MODE] bin=$(shasum -a 256 "$OPT" | cut -c1-16)"
"$OPT" -load-pass-plugin "$PLUG" -passes=cq-lowering -S "$F" -o "$OUT/$B.s2.ll" 2> "$OUT/$B.err"
echo "EXIT=$?"
head -8 "$OUT/$B.err"
