#!/bin/zsh
# Track U FIX-round probe driver. Runs ONE .c or .ll through BOTH binaries and
# diffs. Writes ONLY inside the CQ_undef worktree (the main checkout and its
# build/ are the frozen session ORACLE and are READ-ONLY).
# usage: drive.sh <file.c|file.ll>
set -u
LLVM=/usr/local/opt/llvm@19/bin
MAIN=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_undef
D=$(dirname "$1"); B=$(basename "$1"); N="${B%.*}"; EXT="${B##*.}"
rm -f "$D/$N.verdicts"
cd "$SUBJ"
if [ "$EXT" = "c" ]; then
  "$LLVM/clang" -I"$SUBJ/include" -include CQ.h -O1 -g -emit-llvm -S "$1" -o "$D/$N.s1.ll" 2>"$D/$N.clang.err" || { echo "CLANGERR"; cat "$D/$N.clang.err"; exit 9; }
  S1="$D/$N.s1.ll"
else
  S1="$1"
fi
for K in oracle subject; do
  if [ "$K" = oracle ]; then BLD="$MAIN/build"; else BLD="$SUBJ/build"; fi
  "$BLD/ir-pass/cq-opt" -load-pass-plugin "$BLD/ir-pass/libCQPass.so" -passes=cq-lowering -S "$S1" -o "$D/$N.$K.s2.ll" 2>"$D/$N.$K.err"
  echo "exit_$K=$?" >> "$D/$N.verdicts"
done
echo "--- $N ---"
echo "ORACLE  exit=$(grep exit_oracle "$D/$N.verdicts"|tail -1|cut -d= -f2)  stderr=$(wc -c < "$D/$N.oracle.err"|tr -d ' ')B  sha=$(shasum -a 256 "$D/$N.oracle.err"|cut -c1-12)"
head -c 400 "$D/$N.oracle.err"
echo "SUBJECT exit=$(grep exit_subject "$D/$N.verdicts"|tail -1|cut -d= -f2)  stderr=$(wc -c < "$D/$N.subject.err"|tr -d ' ')B  sha=$(shasum -a 256 "$D/$N.subject.err"|cut -c1-12)"
head -c 400 "$D/$N.subject.err"
if [ -s "$D/$N.oracle.s2.ll" ] && [ -s "$D/$N.subject.s2.ll" ]; then
  if diff -q "$D/$N.oracle.s2.ll" "$D/$N.subject.s2.ll" >/dev/null; then echo "IR: IDENTICAL"; else echo "IR: DIFFERS"; fi
fi
