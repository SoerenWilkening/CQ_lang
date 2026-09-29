#!/bin/bash
# z0re probe driver: stage 1 (clang -O1) + a cq-opt verdict.
# usage: s1.sh <cq-opt binary> <outdir> <src.c>...
#   writes <outdir>/<base>.s1.ll, <outdir>/<base>.<tag>.ll/.err ; prints one verdict line per source.
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82
L=/usr/local/opt/llvm@19/bin
OPT=$1; shift
OUT=$1; shift
TAG=$(basename "$OPT" | tr -c 'A-Za-z0-9\n' '_')
mkdir -p "$OUT"
for src in "$@"; do
  b=$(basename "$src" .c)
  if ! "$L/clang" -I"$W/include" -include CQ.h -O1 -emit-llvm -S "$src" -o "$OUT/$b.s1.ll" 2>/dev/null; then
    echo "$b CLANGFAIL"; continue
  fi
  "$OPT" -load-pass-plugin x -passes=cq-lowering -S "$OUT/$b.s1.ll" -o "$OUT/$b.$TAG.ll" 2> "$OUT/$b.$TAG.err"
  rc=$?
  echo "$b rc=$rc $(grep -m1 -o 'error:.*' "$OUT/$b.$TAG.err")"
done
