#!/bin/bash
# Track C review r1 runner — ORACLE vs SUBJECT on every probe in this dir.
# Row: <probe> | <binary> | exit=<n> | <first DS_Error line or gate census>
# Census on accept: M=<cqrt_measure_ count> A=<cqrt_alloc_ count> R=<cqrt_ry_ count> md5=<lowered IR md5>
LLVM=/usr/local/opt/llvm@19/bin
SUBJ=/Users/sorenwilkening/Desktop/CQ_21mg/build
ORAC=/Users/sorenwilkening/Desktop/CQ_lang/build
SRC=/Users/sorenwilkening/Desktop/CQ_21mg
TMP="${TMPDIR_R1:-/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/ddf48412-8498-4d8b-9bac-51279fb090c0/scratchpad/trackC_review/run}"
mkdir -p "$TMP"
cd "$(dirname "$0")"
for f in "$@"; do
  b=$(basename "$f" .c); b=$(basename "$b" .ll)
  case "$f" in
    *.c) "$LLVM/clang" -I"$SRC/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$TMP/$b.s1.ll" 2>"$TMP/$b.clang.err" \
           || { echo "$b | CLANGERR | $(head -1 "$TMP/$b.clang.err")"; continue; } ;;
    *.ll) cp -f "$f" "$TMP/$b.s1.ll" ;;
  esac
  for role in ORACLE SUBJECT; do
    [ "$role" = ORACLE ] && B="$ORAC" || B="$SUBJ"
    "$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering \
        -S "$TMP/$b.s1.ll" -o "$TMP/$b.$role.ll" >/dev/null 2>"$TMP/$b.$role.err"; rc=$?
    if [ $rc -ne 0 ]; then
      echo "$b | $role | exit=$rc | D:$(grep -m1 -o 'error:.*' "$TMP/$b.$role.err" | sed 's/^error: //')"
    else
      M=$(grep -c 'call.*@cqrt_measure_' "$TMP/$b.$role.ll"); A=$(grep -c '@cqrt_alloc_' "$TMP/$b.$role.ll")
      R=$(grep -c '@cqrt_ry_' "$TMP/$b.$role.ll"); Z=$(grep -c '@cqrt_rz_' "$TMP/$b.$role.ll")
      echo "$b | $role | exit=0 | M=$M A=$A R=$R Z=$Z md5=$(md5 -q "$TMP/$b.$role.ll" | cut -c1-8)"
    fi
  done
done
