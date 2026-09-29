#!/bin/bash
# r1A fmt3 probe runner.  run.sh <name> [runtime args...]
#   src/<name>.c           single TU, clang -O1 -include CQ.h
#   src/<name>.c + src/<name>.lib*.c   multi TU: every TU -O1 separately (CQ.h forced on all
#                          unless NOLIBHDR=1), then llvm-link (mirrors run_slice_multi.sh's shape)
#   src/<name>.ll          hand IR (header-independent)
# For each header H in {old,new} (old = git show 9a230646:include/CQ.h, new = subject's):
#   stage 1 -> the ORACLE cq-opt (bit-identical to the subject's) -> verdict; on ACCEPT stage 2b
#   STRICT, link (templates before runtime), run with args.
# Env: HDRS="old new" (default), CFLAGS extra stage-1 flags, CC=clang or clang++
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b
L=/usr/local/opt/llvm@19/bin
P=$(cd "$(dirname "$0")" && pwd)
ORA=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
CC=${CC:-clang}
n=$1; shift
O=$P/out; mkdir -p "$O"
for H in ${HDRS:-old new}; do
  INC=$P/${H}inc
  S1="$O/$n.$H.s1.ll"
  if [ -f "$P/src/$n.ll" ]; then cp -f "$P/src/$n.ll" "$S1"
  else
    EXT=c; [ -f "$P/src/$n.cpp" ] && EXT=cpp
    TUS="$P/src/$n.$EXT $(ls $P/src/$n.lib*.c 2>/dev/null)"
    parts=""; i=0
    for tu in $TUS; do
      i=$((i+1)); inc="-include CQ.h"
      case $tu in *.lib*) [ "${NOLIBHDR:-0}" = 1 ] && inc="";; *) [ "${NOHDR:-0}" = 1 ] && inc="";; esac
      "$L/$CC" -I"$INC" $inc -O1 ${CFLAGS:-} -emit-llvm -S "$tu" -o "$O/$n.$H.tu$i.ll" 2>"$O/$n.$H.tu$i.cerr" || { echo "$n[$H] STAGE1-FAIL $(head -3 $O/$n.$H.tu$i.cerr)"; continue 2; }
      parts="$parts $O/$n.$H.tu$i.ll"
    done
    if [ $i = 1 ]; then cp -f $parts "$S1"; else "$L/llvm-link" -S $parts -o "$S1" || { echo "LINKFAIL"; continue; }; fi
  fi
  [ -s "$S1" ] || { echo "EMPTY s1"; continue; }
  "$ORA" -passes=cq-lowering -S "$S1" -o "$O/$n.$H.s2.ll" 2> "$O/$n.$H.err"; rc=$?
  if [ $rc != 0 ]; then
    echo "$n[$H] DECLINE rc=$rc [$(grep -m1 -o 'error: .*' "$O/$n.$H.err" | cut -c1-160)]"
  else
    w=$(grep -c 'warning' "$O/$n.$H.err")
    s2=$(python3 "$W/tools/free_pairing_check.py" "$O/$n.$H.s2.ll" 2>&1 | tail -1 | tr '\n' ' ')
    "$L/clang" "$O/$n.$H.s2.ll" "$TPL" "$RT" -o "$O/$n.$H.exe" 2>/dev/null
    "$O/$n.$H.exe" "$@" > "$O/$n.$H.trace" 2>&1
    echo "$n[$H] ACCEPT warn=$w trace=$(wc -l < "$O/$n.$H.trace" | tr -d ' ') 2b=[$s2]"
  fi
done
