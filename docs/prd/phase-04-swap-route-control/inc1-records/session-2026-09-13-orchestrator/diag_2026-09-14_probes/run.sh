#!/bin/zsh
# run.sh — the DIAG_2026-09-14 probe runner (READ-ONLY: builds nothing, runs no suite).
#
#   ./run.sh            # every probe
#   ./run.sh v6 u2      # named probes
#
# Per-probe pipeline is PROTOCOL.md's, verbatim. LLVM is NOT on PATH.
# BINARY UNDER MEASUREMENT (the 2026-09-13 closing primary; shasum it first):
#   build/ir-pass/cq-opt       f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc
#   build/ir-pass/libCQPass.so f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d
set -u
LLVM=/usr/local/opt/llvm@19/bin
HERE="${0:A:h}"
ROOT="${HERE:h:h:h:h:h:h}"            # …/inc1-records/session-…/diag_…_probes -> repo root
B="$ROOT/build"
OUT="${CQ_DIAG_OUT:-$(mktemp -d)}"
echo "repo=$ROOT  out=$OUT"
shasum -a 256 "$B/ir-pass/cq-opt" "$B/ir-pass/libCQPass.so"
probes=("$@")
[[ ${#probes[@]} -eq 0 ]] && probes=(${(f)"$(cd $HERE && ls *.c | sed 's/\.c$//')"})
printf '%-18s %-7s %-6s %s\n' PROBE EXIT LINES 'DIAGNOSTIC (or free_pairing_check)'
for t in $probes; do
  src="$HERE/$t.c"
  "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -g -emit-llvm -S "$src" -o "$OUT/$t.s1.ll" 2>/dev/null || { printf '%-18s %-7s %-6s %s\n' $t CLANG - FAILED; continue; }
  "$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering \
      -S "$OUT/$t.s1.ll" -o "$OUT/$t.s2.ll" >/dev/null 2>"$OUT/$t.err"
  e=$?
  if [[ $e -ne 0 ]]; then
    printf '%-18s %-7s %-6s %s\n' $t $e - "$(sed -n 's/.*: cq \(.*\)$/cq \1/p;s/^error: .*: \(cq_measure.*\)$/\1/p' $OUT/$t.err | head -1)"
    CQ_CTRL_DBG=1 "$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$OUT/$t.s1.ll" -o /dev/null 2>&1 | grep -a CQ_CTRL_DBG | head -1
  else
    python3 "$ROOT/tools/free_pairing_check.py" "$OUT/$t.s2.ll" >"$OUT/$t.2b" 2>&1
    "$LLVM/clang" "$OUT/$t.s2.ll" "$B/runtime/libcq_templates.a" "$B/runtime/libcq_runtime.a" \
        -o "$OUT/$t.exe" 2>/dev/null && "$OUT/$t.exe" >"$OUT/$t.trace" 2>&1
    printf '%-18s %-7s %-6s %s\n' $t 0 "$(wc -l < $OUT/$t.trace | tr -d ' ')" "$(tail -1 $OUT/$t.2b)"
  fi
done
