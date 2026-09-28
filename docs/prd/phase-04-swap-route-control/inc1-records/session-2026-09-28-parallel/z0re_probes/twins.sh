#!/bin/bash
# z0re twin battery.
#   twins.sh <cq-opt> <tag> <base>...
# For each <base>: subject src/<base>C.c (+ src/<base>C.lib.c if present) and twin
# src/<base>T.c (+ src/<base>T.lib.c). Stage 1 = clang -O1 -include CQ.h (lib: plain
# C, no CQ.h) + llvm-link; stage 2 = the given cq-opt. Then:
#   both decline -> stderr byte-identical?              DECL-SAME / DECL-DIFF
#   both accept  -> stage 2b STRICT on both; link; run with args "5 7" and "2 9";
#                   traces byte-identical?                ACC-SAME / ACC-DIFF
#   otherwise    -> VERDICT-DIFF
# Prints a denominator at the end. Writes everything under out/<tag>/.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
P=$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/z0re_probes
RT="$W/build/runtime/libcq_runtime.a"; TPL="$W/build/runtime/libcq_templates.a"
OPT=$1; shift; TAG=$1; shift
O=$P/out/$TAG; mkdir -p "$O"
stage1() {  # $1 = name (e.g. l12C)
  local n=$1
  "$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$P/src/$n.c" -o "$O/$n.cq.ll" 2>/dev/null || return 1
  if [ -f "$P/src/$n.lib.c" ]; then
    "$L/clang" -I"$W/include" -O1 -emit-llvm -S "$P/src/$n.lib.c" -o "$O/$n.lib.ll" 2>/dev/null || return 1
    "$L/llvm-link" -S "$O/$n.cq.ll" "$O/$n.lib.ll" -o "$O/$n.s1.ll" || return 1
  else
    cp -f "$O/$n.cq.ll" "$O/$n.s1.ll"
  fi
  [ -s "$O/$n.s1.ll" ]
}
n=0; same=0
for b in "$@"; do
  c="${b}C"; t="${b}T"
  if ! stage1 "$c" || ! stage1 "$t"; then echo "$b STAGE1-FAIL"; continue; fi
  n=$((n+1))
  "$OPT" -passes=cq-lowering -S "$O/$c.s1.ll" -o "$O/$c.s2.ll" 2> "$O/$c.err"; rc1=$?
  "$OPT" -passes=cq-lowering -S "$O/$t.s1.ll" -o "$O/$t.s2.ll" 2> "$O/$t.err"; rc2=$?
  if [ "$rc1" != 0 ] && [ "$rc2" != 0 ]; then
    if cmp -s "$O/$c.err" "$O/$t.err"; then v=DECL-SAME; same=$((same+1)); else v=DECL-DIFF; fi
    v="$v  [$(grep -m1 -o 'lowering: .*' "$O/$c.err")]"
  elif [ "$rc1" = 0 ] && [ "$rc2" = 0 ]; then
    s2c=$(python3 "$W/tools/free_pairing_check.py" "$O/$c.s2.ll" 2>&1 | tail -1)
    s2t=$(python3 "$W/tools/free_pairing_check.py" "$O/$t.s2.ll" 2>&1 | tail -1)
    "$L/clang" "$O/$c.s2.ll" "$TPL" "$RT" -o "$O/$c.exe" 2>/dev/null
    "$L/clang" "$O/$t.s2.ll" "$TPL" "$RT" -o "$O/$t.exe" 2>/dev/null
    v=ACC-SAME
    for args in "5 7" "2 9"; do
      tag=$(echo "$args" | tr ' ' '_')
      # shellcheck disable=SC2086
      "$O/$c.exe" $args > "$O/$c.$tag.trace" 2>&1; e1=$?
      # shellcheck disable=SC2086
      "$O/$t.exe" $args > "$O/$t.$tag.trace" 2>&1; e2=$?
      if ! cmp -s "$O/$c.$tag.trace" "$O/$t.$tag.trace" || [ "$e1" != "$e2" ]; then v=ACC-DIFF; fi
    done
    [ "$v" = ACC-SAME ] && same=$((same+1))
    v="$v  lines=$(wc -l < "$O/$c.5_7.trace" | tr -d ' ')  2b(C)=[$s2c] 2b(T)=[$s2t]"
  else
    v="VERDICT-DIFF(C rc=$rc1, T rc=$rc2)  C:[$(grep -m1 -o 'lowering: .*' "$O/$c.err")] T:[$(grep -m1 -o 'lowering: .*' "$O/$t.err")]"
  fi
  printf '%-8s %s\n' "$b" "$v"
done
echo "denominator: $n pairs, $same twin-identical ($TAG)"
