#!/bin/bash
# ab.sh <file.c|file.ll> -> prints ORACLE and SUBJECT verdicts
LLVM=/usr/local/opt/llvm@19/bin
SUBJ=/Users/sorenwilkening/Desktop/CQ_l4x4
ORC=/Users/sorenwilkening/Desktop/CQ_lang
F="$1"
B=$(basename "$F"); B=${B%.*}
T=$(mktemp -d)
if [[ "$F" == *.c ]]; then
  "$LLVM/clang" -I$ORC/include -include CQ.h -O1 -emit-llvm -S "$F" -o "$T/s1.ll" 2>"$T/cerr" || { echo "$B|CLANG-ERROR|$(head -c 200 $T/cerr|tr '\n' ' ')"; rm -rf $T; exit 0; }
else
  cp "$F" "$T/s1.ll"
fi
run() {
  local tag=$1 root=$2
  "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$tag.ll" 2>"$T/$tag.err"
  local rc=$?
  if [ $rc -eq 0 ]; then
    local md5=$(md5 -q "$T/$tag.ll")
    local warn=$(grep -c 'warning:' "$T/$tag.err")
    echo "ACCEPT(md5=${md5:0:8},warn=$warn)"
  else
    echo "DECLINE($(grep -o 'cq [a-z ]*lowering: [^\"]*' "$T/$tag.err" | head -1 | cut -c1-90))"
  fi
}
O=$(run orc $ORC)
S=$(run subj $SUBJ)
echo "$B|$O|$S"
cp "$T/s1.ll" "$SC_OUT/$B.s1.ll" 2>/dev/null
cp "$T/subj.ll" "$SC_OUT/$B.subj.ll" 2>/dev/null
cp "$T/subj.err" "$SC_OUT/$B.subj.err" 2>/dev/null
rm -rf $T
