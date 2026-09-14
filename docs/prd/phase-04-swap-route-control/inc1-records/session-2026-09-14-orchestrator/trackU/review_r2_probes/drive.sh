#!/bin/bash
# Track U round-2 adversarial probe driver.
# Usage: drive.sh <name>          (expects <name>.c in this dir)
#        drive.sh -ll <name>      (expects <name>.ll — skip stage 1)
# Writes <name>.s1.ll, <name>.{oracle,subject}.{err,s2.ll}, <name>.verdicts
set -u
LLVM=/usr/local/opt/llvm@19/bin
MAIN=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_undef
D="$(cd "$(dirname "$0")" && pwd)"
MODE=c
if [ "$1" = "-ll" ]; then MODE=ll; shift; fi
N="$1"
cd "$D"
if [ "$MODE" = c ]; then
  "$LLVM/clang" -I"$MAIN/include" -include CQ.h -O1 -g -emit-llvm -S "$N.c" -o "$N.s1.ll" 2> "$N.clang.err"
  if [ ! -s "$N.s1.ll" ]; then echo "STAGE1 FAILED"; cat "$N.clang.err"; exit 1; fi
else
  cp -f "$N.ll" "$N.s1.ll"
fi
"$MAIN/build/ir-pass/cq-opt" -load-pass-plugin "$MAIN/build/ir-pass/libCQPass.so" \
   -passes=cq-lowering -S "$N.s1.ll" -o "$N.oracle.s2.ll" 2> "$N.oracle.err"; OE=$?
"$SUBJ/build/ir-pass/cq-opt" -load-pass-plugin "$SUBJ/build/ir-pass/libCQPass.so" \
   -passes=cq-lowering -S "$N.s1.ll" -o "$N.subject.s2.ll" 2> "$N.subject.err"; SE=$?
{ echo "oracle  exit=$OE stderr=$(wc -c < "$N.oracle.err" | tr -d ' ')B"
  echo "subject exit=$SE stderr=$(wc -c < "$N.subject.err" | tr -d ' ')B"; } > "$N.verdicts"
cat "$N.verdicts"
echo "--- oracle stderr ---";  head -c 600 "$N.oracle.err"
echo "--- subject stderr ---"; head -c 600 "$N.subject.err"
if [ $OE -eq 0 ] && [ $SE -eq 0 ]; then
  if cmp -s "$N.oracle.s2.ll" "$N.subject.s2.ll"; then echo "--- s2 IR: IDENTICAL ---";
  else echo "--- s2 IR: DIFFERS ---"; diff "$N.oracle.s2.ll" "$N.subject.s2.ll" | head -60; fi
fi
