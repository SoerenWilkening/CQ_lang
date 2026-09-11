#!/usr/bin/env bash
# sweep.sh <dir> — run every .c (via clang -O1) and every *.s1.ll without a .c in
# <dir> through BOTH binaries; print "name | oracle-verdict | subject-verdict".
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang; SUBJ=/Users/sorenwilkening/Desktop/CQ_b6ap
LLVM=/usr/local/opt/llvm@19/bin; D=$1; T=$(mktemp -d)
verdict(){ # $1=root $2=ll
  local e; "$1/build/ir-pass/cq-opt" -passes=cq-lowering -S "$2" -o "$T/o.ll" 2> "$T/e.txt"; e=$?
  if [ $e -eq 0 ]; then echo "ACCEPT"; else
    grep -oE '(error|warning): .*' "$T/e.txt" | grep '^error' | head -1 | sed 's/.*: cq /cq /' ; fi
}
for f in "$D"/*.c; do
  [ -e "$f" ] || continue; n=$(basename "$f" .c)
  "$LLVM/clang" -I"$ORACLE/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/$n.ll" 2>/dev/null || { echo "$n | CLANG-FAIL |"; continue; }
  echo "$n | $(verdict $ORACLE "$T/$n.ll") | $(verdict $SUBJ "$T/$n.ll")"
done
for f in "$D"/*.s1.ll; do
  [ -e "$f" ] || continue; n=$(basename "$f" .s1.ll)
  [ -e "$D/$n.c" ] && continue
  echo "$n | $(verdict $ORACLE "$f") | $(verdict $SUBJ "$f")"
done
rm -rf "$T"
