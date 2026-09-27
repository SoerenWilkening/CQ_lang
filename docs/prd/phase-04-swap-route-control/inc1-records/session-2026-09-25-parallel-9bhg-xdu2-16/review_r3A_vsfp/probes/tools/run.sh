#!/bin/bash
# run.sh <bin: S|M|path> <in.ll> [args...] : lower, 2b, link, trace
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8
L=/usr/local/opt/llvm@19/bin
case "$1" in S) B=$W/build/ir-pass/cq-opt;; M) B=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen/cq-opt.main_aee8;; *) B=$1;; esac
IN=$2; shift 2
[ -s "$IN" ] || { echo "EMPTY INPUT"; exit 2; }
OUT=$(cd $(dirname $IN) && pwd)/$(basename ${IN%.ll}).$(basename $B).s2.ll
$B -passes=cq-lowering -S "$IN" -o "$OUT" 2> "$OUT.err"
rc=$?
echo "opt rc=$rc"; grep -E "error|warning" "$OUT.err" | head -3
[ $rc -eq 0 ] || exit 0
python3 $W/tools/free_pairing_check.py "$OUT" | tail -2
$L/clang -Wno-everything "$OUT" $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o "$OUT.exe" 2>/dev/null || { echo LINKFAIL; exit 0; }
"$OUT.exe" "${@:-5}" > "$OUT.trace"; echo "run rc=$?"; cat "$OUT.trace"; rm -f "$OUT.exe"
