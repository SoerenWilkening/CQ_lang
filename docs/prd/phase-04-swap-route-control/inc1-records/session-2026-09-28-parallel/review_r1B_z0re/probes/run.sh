#!/bin/bash
# run.sh <S|O> <src.c> [lib.c] -- <args...>   : stage1 (+llvm-link lib), stage2, 2b, link, run
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
SUBJ=$W/build/ir-pass/cq-opt
ORA=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646
H=$(cd "$(dirname "$0")" && pwd)
case $1 in S) OPT=$SUBJ;; O) OPT=$ORA;; esac; shift
SRC=$1; shift; LIB=""
if [ "$1" != "--" ] && [ -n "$1" ]; then LIB=$1; shift; fi
[ "$1" = "--" ] && shift
b=$(basename "$SRC" .c); tag=$(basename $OPT | cut -c1-6)
O=$H/out/$b.$tag; mkdir -p $H/out
"$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$SRC" -o "$O.s1a.ll" 2>/dev/null || { echo CLANGFAIL; exit 1; }
if [ -n "$LIB" ]; then
  "$L/clang" -O1 -emit-llvm -S "$LIB" -o "$O.lib.ll" 2>/dev/null || { echo LIBFAIL; exit 1; }
  "$L/llvm-link" -S "$O.s1a.ll" "$O.lib.ll" -o "$O.s1.ll"
else cp -f "$O.s1a.ll" "$O.s1.ll"; fi
if ! "$OPT" -passes=cq-lowering -S "$O.s1.ll" -o "$O.s2.ll" 2> "$O.err"; then
  echo "DECLINE rc=$? : $(grep -m1 -o 'lowering: .*' "$O.err")"; grep -m1 -o 'error: .*' "$O.err" | head -1; exit 0
fi
[ -s "$O.err" ] && echo "STDERR: $(head -c 300 $O.err)"
python3 "$W/tools/free_pairing_check.py" "$O.s2.ll" 2>&1 | tail -2
"$L/clang" -c "$O.s2.ll" -o "$O.o" 2>/dev/null && "$W/build/tests/e2e/cq_link.sh" -o "$O.exe" "$O.o" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" 2>/dev/null || { echo LINKFAIL; exit 1; }
"$O.exe" "$@" > "$O.trace" 2>&1; echo "exit=$? lines=$(wc -l < $O.trace) lowered=$(wc -l < $O.s2.ll)"
cat "$O.trace"
