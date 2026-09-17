#!/bin/bash
# Per-probe pipeline, BOTH binaries. Usage: run.sh <probe.c|probe.ll> [tag]
LLVM=/usr/local/opt/llvm@19/bin
REPO=/Users/sorenwilkening/Desktop/Projects/CQ_lang
SUBJ=$REPO/.claude/worktrees/agent-ad7349188dd3b67bd
P="$1"; TAG="${2:-$(basename "$P" | sed 's/\..*//')}"
OUT=$(mktemp -d)
if [[ "$P" == *.c ]]; then
  "$LLVM/clang" -I$REPO/include -include CQ.h -O1 -g -emit-llvm -S "$P" -o "$OUT/s1.ll" || { echo "CLANG FAIL"; exit 1; }
else
  cp -f "$P" "$OUT/s1.ll"
fi
for W in ORACLE:$REPO SUBJECT:$SUBJ; do
  N="${W%%:*}"; B="${W##*:}"
  "$B/build/ir-pass/cq-opt" -load-pass-plugin "$B/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$OUT/s1.ll" -o "$OUT/$N.s2.ll" 2>"$OUT/$N.err"
  E=$?
  if [ $E -eq 0 ]; then
    M=$(md5 -q "$OUT/$N.s2.ll")
    echo "$TAG | $N | exit=0 ACCEPT | md5=$M"
  else
    echo "$TAG | $N | exit=$E DECLINE | $(grep -o 'cq [a-z ]*lowering: .*' "$OUT/$N.err" | head -1)"
  fi
done
echo "WORKDIR=$OUT"
