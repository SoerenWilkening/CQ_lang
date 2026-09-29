#!/bin/bash
# run.sh <bin: S|M|path> <in.ll> [args...] : lower, 2b (strict), link, trace
# S = this worktree's build/ir-pass/cq-opt ; M = the frozen ORACLE (main 9a230646)
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
L=/usr/local/opt/llvm@19/bin
case "$1" in
  S) B=$W/build/ir-pass/cq-opt;;
  M) B=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646;;
  *) B=$1;;
esac
IN=$2; shift 2
[ -s "$IN" ] || { echo "EMPTY INPUT"; exit 2; }
OUTD=$(cd "$(dirname "$0")/.." && pwd)/results/run_out; mkdir -p "$OUTD"; OUT=$OUTD/$(basename ${IN%.ll}).$(basename $B).s2.ll   # never next to the input (a stray .ll in ir-pass/test is a lit test)
$B -passes=cq-lowering -S "$IN" -o "$OUT" 2> "$OUT.err"
rc=$?
echo "opt rc=$rc"; grep -E "error|warning" "$OUT.err" | head -3
[ $rc -eq 0 ] || exit 0
python3 $W/tools/free_pairing_check.py "$OUT" | tail -2
$L/clang -Wno-everything "$OUT" $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o "$OUT.exe" 2>/dev/null || { echo LINKFAIL; exit 0; }
"$OUT.exe" "${@:-5}" > "$OUT.trace"; echo "run rc=$?"; cat "$OUT.trace"; rm -f "$OUT.exe"
