#!/bin/bash
# One row of the PROTOCOL corpus sweep, ORACLE vs SUBJECT, on ONE stage-1 module.
# Row:  <rel>|<O verdict>|<S verdict>|<O stderr sha16>|<S stderr sha16>
# A verdict is `A:<md5 of lowered IR, 8>` or `D:<first cq diagnostic, 80 chars>`.
#
# ⚠ S3: the shared recipe's tag regex renders the whole `cq_measure_<sfx>` family
# as an empty `D:`, so a decline->decline string change inside it is INVISIBLE.
# Closed here by carrying a sha256 of the FULL stderr beside the tag, and by
# comparing exit codes explicitly.
LLVM=/usr/local/opt/llvm@19/bin
ORC=/Users/sorenwilkening/Desktop/CQ_lang/build
SUB=/Users/sorenwilkening/Desktop/CQ_A/build
INC=/Users/sorenwilkening/Desktop/CQ_A/include
f=$1; rel=$2
T=$(mktemp -d)
if [[ "$f" == *.c ]]; then
  "$LLVM/clang" -I"$INC" -include CQ.h -O1 -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
    || { echo "$rel|CLANGERR|CLANGERR|-|-"; rm -rf "$T"; exit 0; }
else cp "$f" "$T/s1.ll"; fi
v() {
  "$1/ir-pass/cq-opt" -passes=cq-lowering -S "$T/s1.ll" -o "$T/$2.ll" 2>"$T/$2.err"
  if [ $? -eq 0 ]; then printf 'A:%s' "$(md5 -q "$T/$2.ll" | cut -c1-8)"
  else printf 'D:%s' "$(grep -oE 'cq [a-z0-9 -]+: [^"]+' "$T/$2.err" | head -1 | cut -c1-80)"; fi
}
O=$(v "$ORC" o); S=$(v "$SUB" s)
OE=$(shasum -a 256 "$T/o.err" | cut -c1-16); SE=$(shasum -a 256 "$T/s.err" | cut -c1-16)
echo "$rel|$O|$S|$OE|$SE"
rm -rf "$T"
