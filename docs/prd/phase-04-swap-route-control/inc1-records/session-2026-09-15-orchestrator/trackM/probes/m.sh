#!/bin/zsh
# m.sh — per-probe pipeline against the ORACLE (PROTOCOL.md).
# usage: ./m.sh <probe.c|probe.ll> [outdir]
# prints: <name> | <verdict A/D> | <trace lines or diagnostic>
set -u
ROOT=/Users/sorenwilkening/Desktop/CQ_lang
LLVM=/usr/local/opt/llvm@19/bin
BUILD=$ROOT/build
P=$1
OUT=${2:-$ROOT/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/out}
mkdir -p $OUT
N=$(basename $P); N=${N%.c}; N=${N%.ll}
if [[ $P == *.ll ]]; then cp $P $OUT/$N.s1.ll
else "$LLVM/clang" -I$ROOT/include -include CQ.h -O1 -g -emit-llvm -S $P -o $OUT/$N.s1.ll 2>$OUT/$N.cc.err || { echo "$N | CCFAIL"; exit 0; }
fi
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S $OUT/$N.s1.ll -o $OUT/$N.s2.ll 2>$OUT/$N.err
E=$?
if [[ $E -ne 0 ]]; then
  echo "$N | D | $(head -1 $OUT/$N.err | sed 's/.*in function [^:]*: //')"
  exit 0
fi
python3 $ROOT/tools/free_pairing_check.py $OUT/$N.s2.ll > $OUT/$N.fp 2>&1
"$LLVM/clang" $OUT/$N.s2.ll "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o $OUT/$N.exe 2>$OUT/$N.link.err && $OUT/$N.exe > $OUT/$N.trace 2>&1
L=$(wc -l < $OUT/$N.trace 2>/dev/null | tr -d ' ')
echo "$N | A | ${L:-LINKFAIL} lines | $(tail -1 $OUT/$N.fp)"
