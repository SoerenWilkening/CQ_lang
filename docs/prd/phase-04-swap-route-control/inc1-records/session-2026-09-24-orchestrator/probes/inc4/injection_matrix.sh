#!/bin/bash
# Injection matrix with a NULL CONTROL. $1 = fixture path.
F="$1"; B=$(basename $F .ll); OUT=$(mktemp -d); SDIR=$(cd "$(dirname "$F")" && pwd)
LLVM=/usr/local/opt/llvm@19/bin
export PATH="$LLVM:$PATH"
run() { # $1 = injected line (empty = null control)
  build/ir-pass/cq-opt -passes=cq-lowering -S "$F" -o "$OUT/o.ll" 2>/dev/null || { echo "DECLINED"; return; }
  if [ -n "$1" ]; then
    awk -v ins="$1" '/call i32 @cqrt_measure|call i32 @cqrt_alloc/ && !d {print ins; d=1} {print}' "$OUT/o.ll" > "$OUT/m.ll"
  else cp "$OUT/o.ll" "$OUT/m.ll"; fi
  cmp -s "$OUT/o.ll" "$OUT/m.ll" && [ -n "$1" ] && { echo "NO-OP-MUTATION"; return; }
  ok=1
  while IFS= read -r line; do
    cmd=$(echo "$line" | sed -e 's|^; RUN: ||' \
      -e "s|%t.cqd0.ll|$OUT/m.ll|g" \
      -e "s|%cq-opt|$PWD/build/ir-pass/cq-opt|g" \
      -e "s|%cq-pass|$PWD/build/ir-pass/libCQPass.so|g" \
      -e "s|%filecheck|$LLVM/FileCheck|g" \
      -e "s|%S|$SDIR|g" \
      -e "s|%s|$PWD/$F|g" \
      -e "s|%t\.|$OUT/t.|g")
    # Skip ONLY the line that regenerates the file we mutated; run every other
    # cq-opt line (a twin fixture's pipeline needs them). Without this the null
    # control reports CAUGHT and the whole matrix measures the harness.
    case "$cmd" in *cq-opt*"$OUT/m.ll") continue;; esac
    eval "$cmd" >/dev/null 2>&1 || ok=0
  done < <(grep '^; RUN:' "$F")
  [ $ok -eq 1 ] && echo "MISSED" || echo "CAUGHT"
}
echo "--- $B ---"
echo "  NULL CONTROL (must be MISSED): $(run '')"
for g in 'call void @cqrt_ry_i32(i32 0, double 1.0)' 'call i32 @cqrt_measure_i32(i32 0)' 'call void @cqrt_free(i32 0)' 'call void @cqrt_x(i32 0)' 'call i32 @cqrt_alloc_i32(i32 99)' 'call void @cqrt_copy_i32_controlled(i32 0, i32 0, i32 0)' 'call void @cqrt_rz_i1(i32 0, double 1.0)' 'call void @cqrt_cnot(i32 0, i32 0)'; do
  printf "  %-58s %s\n" "${g:0:56}" "$(run "$g")"
done
