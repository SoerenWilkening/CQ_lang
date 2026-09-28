#!/bin/bash
# run.sh <S|O|path-to-cq-opt> <in.s1.ll> [args...]
#   lower -> stage 2b STRICT (+ CENSUS) -> link templates-before-runtime -> run.
#   Prints ONE summary line; keeps <out>/<base>.<tag>.{s2.ll,err,trace}.
#   rc is taken from cq-opt DIRECTLY (no pipeline before rc=$?).
#   S = this worktree's build, O = the frozen ORACLE (main 9a230646).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
L=/usr/local/opt/llvm@19/bin
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
case "$1" in
  S) B=$W/build/ir-pass/cq-opt;;
  O) B=$SP/frozen/cq-opt.main_9a230646;;
  *) B=$1;;
esac
T=$(basename "$1"); IN=$2; shift 2
[ -s "$IN" ] || { echo "EMPTY INPUT"; exit 2; }
D=${OUT:-$SP/nlfd/out}; mkdir -p "$D"
base=$(basename "${IN%.s1.ll}"); base=${base%.ll}
O=$D/$base.$T.s2.ll
"$B" -passes=cq-lowering -S "$IN" -o "$O" 2> "$O.err"; rc=$?
if [ $rc -ne 0 ]; then
  echo "opt=$rc $(grep -o 'error: .*' "$O.err" | head -1 | cut -c1-150)"
  rm -f "$D/$base.$T.trace"; exit 0
fi
w=$(grep -c 'warning' "$O.err")
pb=$(python3 $W/tools/free_pairing_check.py "$O" 2>&1 | grep -oE '[0-9]+ verified, [0-9]+ violation\(s\), [0-9]+ unproven|[0-9]+ template rail mint\(s\) of which [0-9]+ left dirty' | tr '\n' ';')
$L/clang -Wno-everything "$O" $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o "$O.exe" 2>/dev/null || { echo "opt=0 LINKFAIL"; exit 0; }
"$O.exe" "${@:-5}" > "$D/$base.$T.trace" 2>/dev/null; r=$?
echo "opt=0 warn=$w 2b[$pb] run=$r lines=$(wc -l < "$D/$base.$T.trace" | tr -d ' ')"
rm -f "$O.exe"
