#!/bin/bash
# measure.sh <BUILD_DIR> <REPO_ROOT_for_include> <file.c...>
# Prints: <name> | exit=<n> | <first error/warning line or ACCEPT>
LLVM=/usr/local/opt/llvm@19/bin
BUILD="$1"; shift
INC="$1"; shift
TMP=$(mktemp -d)
for f in "$@"; do
  n=$(basename "$f" .c)
  "$LLVM/clang" -I"$INC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$TMP/$n.s1.ll" 2> "$TMP/$n.c.err"
  if [ $? -ne 0 ]; then echo "$n | STAGE1_FAIL | $(head -1 "$TMP/$n.c.err")"; continue; fi
  "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering \
      -S "$TMP/$n.s1.ll" -o "$TMP/$n.s2.ll" > /dev/null 2> "$TMP/$n.err"
  rc=$?
  if [ $rc -eq 0 ]; then
    msg=$(grep -m1 -o 'warning: .*' "$TMP/$n.err")
    [ -z "$msg" ] && msg="ACCEPT"
    echo "$n | exit=0 | $msg | md5=$(grep -v '^; ModuleID' "$TMP/$n.s2.ll" | md5 -q)"
  else
    echo "$n | exit=$rc | $(grep -m1 -o 'error: .*' "$TMP/$n.err")"
  fi
done
echo "TMPDIR=$TMP" >&2
