#!/bin/bash
# run.sh <S|R5|R4|M> <in.ll> [args] : lower, 2b STRICT, link, run; one summary line; trace at $OUT/<base>.<tag>.trace
# bash only. rc is captured from cq-opt directly (no pipeline before `rc=$?`).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8; L=/usr/local/opt/llvm@19/bin
SP=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
case "$1" in S) B=$W/build/ir-pass/cq-opt;; R5) B=$SP/vsfp/bin/cq-opt.r5keep;; R4) B=$SP/vsfp/bin/cq-opt.r4keep;; M) B=$SP/frozen/cq-opt.main_aee8;; *) echo bad; exit 2;; esac
T=$1; IN=$2; shift 2
[ -s "$IN" ] || { echo "EMPTY INPUT"; exit 2; }
D=${OUT:-$SP/r6rev/out}; mkdir -p $D; O=$D/$(basename ${IN%.ll}).$T.s2.ll
"$B" -passes=cq-lowering -S "$IN" -o "$O" 2> "$O.err"; rc=$?
if [ $rc -ne 0 ]; then echo "opt=$rc $(grep -o 'error: .*' $O.err | head -1 | cut -c1-140)"; exit 0; fi
w=$(grep -c 'warning' $O.err)
pb=$(python3 $W/tools/free_pairing_check.py "$O" 2>&1 | grep -oE '[0-9]+ verified, [0-9]+ violation\(s\), [0-9]+ unproven|[0-9]+ template rail mint\(s\) of which [0-9]+ left dirty' | tr '\n' ';')
$L/clang -Wno-everything "$O" $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o "$O.exe" 2>/dev/null || { echo "opt=0 LINKFAIL"; exit 0; }
"$O.exe" "${@:-5}" > "${O%.s2.ll}.trace" 2>/dev/null; r=$?
echo "opt=0 warn=$w 2b[$pb] run=$r lines=$(wc -l < ${O%.s2.ll}.trace | tr -d ' ')"; rm -f "$O.exe"
