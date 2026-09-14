#!/bin/bash
# Track F round-2 review runner. Prints byte size before EVERY measurement and
# REFUSES a 0-byte module (SCOPE_F erratum: a 0-byte .ll ACCEPTS via passthrough).
LLVM=/usr/local/opt/llvm@19/bin
ORACLE=/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
SUBJECT=/Users/sorenwilkening/Desktop/CQ_f2phi/build/ir-pass/cq-opt
PREFIX=/Users/sorenwilkening/Desktop/CQ_f2phi/build/prefix_147cb3d6/cq-opt
here="$(cd "$(dirname "$0")" && pwd)"

emit() {   # emit <file.c>  -> file.s1.ll
  local c="$1"; local base="${c%.c}"
  "$LLVM/clang" -I/Users/sorenwilkening/Desktop/CQ_lang/include -include CQ.h \
      -O1 -emit-llvm -S "$c" -o "$base.s1.ll" || return 1
  local sz; sz=$(wc -c < "$base.s1.ll")
  echo "   [emit] $base.s1.ll = $sz bytes"
  [ "$sz" -gt 0 ] || { echo "   !! 0-BYTE MODULE — REFUSED"; return 1; }
}

measure() {  # measure <file.ll>
  local f="$1"
  local sz; sz=$(wc -c < "$f")
  echo "=== $f ($sz bytes) ==="
  [ "$sz" -gt 0 ] || { echo "   !! 0-BYTE MODULE — REFUSED, not measured"; return 1; }
  for name in ORACLE PREFIX SUBJECT; do
    local bin; eval "bin=\$$name"
    out=$("$bin" -load-pass-plugin x -passes=cq-lowering -S "$f" -o "$f.$name.out.ll" 2>"$f.$name.err")
    rc=$?
    local osz=0; [ -f "$f.$name.out.ll" ] && osz=$(wc -c < "$f.$name.out.ll")
    printf "  %-8s exit=%d  out=%sB  %s\n" "$name" "$rc" "$osz" "$(head -c 300 "$f.$name.err" | tr '\n' ' ')"
  done
}
