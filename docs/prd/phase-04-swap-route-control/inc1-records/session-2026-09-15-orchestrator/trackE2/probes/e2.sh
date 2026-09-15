#!/bin/zsh
# e2.sh — per-probe pipeline (PROTOCOL.md), parameterised by BUILD so the SAME
# script measures the ORACLE and the SUBJECT.
#   usage: BUILD=<build dir> ROOT=<repo root> ./e2.sh <probe.c|probe.ll> [outtag]
# prints: <name> | <A|D> | <trace lines | diagnostic>
set -u
ROOT=${ROOT:-/Users/sorenwilkening/Desktop/CQ_E2}
LLVM=/usr/local/opt/llvm@19/bin
BUILD=${BUILD:-$ROOT/build}
P=$1
TAG=${2:-sub}
HERE=${0:a:h}
OUT=$HERE/out/$TAG
mkdir -p $OUT
N=$(basename $P); N=${N%.c}; N=${N%.ll}
if [[ $P == *.ll ]]; then cp -f $P $OUT/$N.s1.ll
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
