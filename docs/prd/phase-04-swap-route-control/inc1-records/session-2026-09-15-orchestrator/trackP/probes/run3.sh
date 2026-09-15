#!/bin/bash
# three-way probe runner: ORACLE (main), BASE (3637fdd2 = Track F'), SUBJECT (my build)
# usage: run3.sh <probe.c|probe.ll>
SCRATCH=/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/1c53d18f-fd04-48d9-8e6f-94acf28a1db2/scratchpad
LLVM=/usr/local/opt/llvm@19/bin
P=/Users/sorenwilkening/Desktop/CQ_P
SRC="$1"; NAME=$(basename "$SRC"); NAME="${NAME%.*}"
OUT=$SCRATCH/out; mkdir -p $OUT
if [[ "$SRC" == *.c ]]; then
  (cd $P && "$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S "$SRC" -o "$OUT/$NAME.s1.ll") || { echo "$NAME: CLANG FAIL"; exit 1; }
  S1="$OUT/$NAME.s1.ll"
else
  S1="$SRC"
fi
for role in ORACLE BASE SUBJECT; do
  case $role in
    ORACLE)  BIN=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt; PL=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so;;
    BASE)    BIN=$SCRATCH/base/cq-opt; PL=$SCRATCH/base/libCQPass.so;;
    SUBJECT) BIN=$P/build/ir-pass/cq-opt; PL=$P/build/ir-pass/libCQPass.so;;
  esac
  if [ ! -x "$BIN" ]; then echo "$NAME | $role | <no binary>"; continue; fi
  ERR=$("$BIN" -load-pass-plugin "$PL" -passes=cq-lowering -S "$S1" -o "$OUT/$NAME.$role.s2.ll" 2>&1); EC=$?
  if [ $EC -eq 0 ]; then
    NL=$(grep -c . "$OUT/$NAME.$role.s2.ll")
    echo "$NAME | $role | ACCEPT exit=0 | ${NL} lines"
  else
    MSG=$(echo "$ERR" | head -2 | tr '\n' ' ')
    echo "$NAME | $role | DECLINE exit=$EC | $MSG"
  fi
done
