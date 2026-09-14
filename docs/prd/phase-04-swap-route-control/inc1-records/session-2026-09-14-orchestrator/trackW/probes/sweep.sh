#!/bin/zsh
# Track W sweep: run a list of probes against the SUBJECT build with a given env.
# usage: sweep.sh <env-assignments-or-empty> <probe basenames...>
set -u
LLVM=/usr/local/opt/llvm@19/bin
SUB=/Users/sorenwilkening/Desktop/CQ_wx8g
D=${0:h}
ENVS=$1; shift
for B in "$@"; do
  T=$(mktemp -d)
  "$LLVM/clang" -I$SUB/include -include CQ.h -O1 -g -emit-llvm -S "$D/$B.c" -o $T/s1.ll 2>/dev/null || { echo "$B | STAGE1 FAIL"; continue; }
  if [ -n "$ENVS" ]; then
    env $=ENVS "$SUB/build/ir-pass/cq-opt" -load-pass-plugin "$SUB/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $T/s1.ll -o $T/s2.ll 2>$T/o.err
  else
    "$SUB/build/ir-pass/cq-opt" -load-pass-plugin "$SUB/build/ir-pass/libCQPass.so" -passes=cq-lowering -S $T/s1.ll -o $T/s2.ll 2>$T/o.err
  fi
  E=$?
  if [ $E -ne 0 ]; then
    echo "$B | DECLINE | $(grep -o 'cq [a-z ]*lowering: [^\"]*' $T/o.err | head -1)"
  else
    FP=$(python3 $SUB/tools/free_pairing_check.py $T/s2.ll 2>&1 | tail -1)
    "$LLVM/clang" $T/s2.ll $SUB/build/runtime/libcq_templates.a $SUB/build/runtime/libcq_runtime.a -o $T/a 2>/dev/null && $T/a > $D/$B.trace
    echo "$B | ACCEPT | trace=$(wc -l < $D/$B.trace 2>/dev/null) | $FP"
  fi
  rm -rf $T
done
