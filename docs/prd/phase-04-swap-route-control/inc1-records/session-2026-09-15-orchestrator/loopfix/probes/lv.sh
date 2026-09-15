#!/bin/bash
# loopfix harness — ORACLE vs the MERGED binary (whatever is built in CQ_LOOPFIX).
# Self-guarded: VACUOUS-NO-QUANTUM for an empty/quantum-free stage 1, and its own
# tags for a link failure and an empty lowered module.
set -u
LLVM=/usr/local/opt/llvm@19/bin
declare -a NAMES=(ORA M)
declare -a BUILDS=(/Users/sorenwilkening/Desktop/CQ_lang/build \
                   /Users/sorenwilkening/Desktop/CQ_LOOPFIX/build)
INC=/Users/sorenwilkening/Desktop/CQ_lang/include
run() {
  local D=$1 B=$2 T=$3 BD=$4 E
  rm -f "$D/$B.$T.ll" "$D/$B.$T.err" "$D/$B.$T.trace" "$D/$B.$T.bin"
  "$BD/ir-pass/cq-opt" -load-pass-plugin "$BD/ir-pass/libCQPass.so" \
      -passes=cq-lowering -S "$D/$B.s1.ll" -o "$D/$B.$T.ll" 2> "$D/$B.$T.err"; E=$?
  if [ $E -ne 0 ]; then
    printf 'D%s:%s' "$E" "$(grep -o 'cq [a-z0-9 -]*lowering: [^;]*\|cq taint escape: [^;]*' "$D/$B.$T.err" | head -1)"
    return
  fi
  if [ ! -s "$D/$B.$T.ll" ]; then printf 'BROKEN-EMPTY-OUTPUT'; return; fi
  "$LLVM/clang" "$D/$B.$T.ll" "$BD/runtime/libcq_templates.a" "$BD/runtime/libcq_runtime.a" \
      -o "$D/$B.$T.bin" 2>/dev/null
  if [ ! -x "$D/$B.$T.bin" ]; then printf 'A:LINKFAIL'; return; fi
  "$D/$B.$T.bin" > "$D/$B.$T.trace" 2>/dev/null
  printf 'A:%s' "$(wc -l < "$D/$B.$T.trace" | tr -d ' ')"
}
row() {
  local P="$1" B D NQ out
  B=$(basename "$P" .c); D=$(dirname "$P")
  rm -f "$D/$B.s1.ll" "$D/$B.clang.err"
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$D/$B.s1.ll" 2> "$D/$B.clang.err"
  if [ ! -s "$D/$B.s1.ll" ]; then echo "$B | CLANGERR"; return 1; fi
  NQ=$(grep -c 'call .*@cq_\(theta\|phi\|measure\)_' "$D/$B.s1.ll")
  if [ "$NQ" -eq 0 ]; then echo "$B | VACUOUS-NO-QUANTUM"; return 2; fi
  out="$B |"
  for i in 0 1; do out="$out ${NAMES[$i]} $(run "$D" "$B" "${NAMES[$i]}" "${BUILDS[$i]}") |"; done
  echo "$out"
}
for p in "$@"; do row "$p"; done
