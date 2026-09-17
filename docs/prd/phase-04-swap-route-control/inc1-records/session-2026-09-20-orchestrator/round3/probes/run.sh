#!/bin/bash
# run.sh <probe.c> [binary-tag]   tags: BASE MAIN TU9QONLY COMPOSED
LLVM=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a8a02006bc710dbc0
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad
BINS=$S/bins
C="$1"; TAG="${2:-COMPOSED}"
n=$(basename "$C" .c)
d=$S/out/$TAG; mkdir -p "$d"
"$LLVM/clang" -I$W/include -include CQ.h -O1 -emit-llvm -S "$C" -o "$d/$n.s1.ll" 2>"$d/$n.cc.err" || { echo "[$TAG/$n] CLANG FAIL"; cat "$d/$n.cc.err"; exit 9; }
"$BINS/cq-opt.$TAG" -load-pass-plugin "$BINS/libCQPass.$TAG.so" -passes=cq-lowering -S "$d/$n.s1.ll" -o "$d/$n.s2.ll" 2>"$d/$n.opt.err"
rc=$?
echo "[$TAG/$n] opt exit=$rc"
if [ $rc -ne 0 ]; then head -3 "$d/$n.opt.err"; exit 0; fi
if [ -s "$d/$n.opt.err" ]; then echo "  STDERR:"; head -5 "$d/$n.opt.err"; fi
python3 $W/tools/free_pairing_check.py "$d/$n.s2.ll" > "$d/$n.2b.txt" 2>&1
echo "  2b exit=$? : $(grep -E 'rail mint|violation' $d/$n.2b.txt | head -3 | tr '\n' '|')"
"$LLVM/clang" "$d/$n.s2.ll" $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o "$d/$n.exe" 2>/dev/null && "$d/$n.exe" > "$d/$n.trace" 2>&1
echo "  trace lines=$(wc -l < $d/$n.trace 2>/dev/null)  lowered lines=$(grep -c . $d/$n.s2.ll)"
