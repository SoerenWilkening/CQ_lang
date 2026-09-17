#!/bin/bash
# usage: probes/run.sh <file.c|file.ll> [buildroot]
set -uo pipefail
LLVM=/usr/local/opt/llvm@19/bin
W="$(cd "$(dirname "$0")/.." && pwd)"
B="${2:-$W/build}"
F="$1"; N="$(basename "$F" | sed 's/\.[^.]*$//')"
T="$(mktemp -d)"
if [[ "$F" == *.c ]]; then
  "$LLVM/clang" -I"$W/include" -include CQ.h -O1 -g -emit-llvm -S "$F" -o "$T/s1.ll" || { echo "$N: CLANG FAIL"; exit 1; }
else
  cp "$F" "$T/s1.ll"
fi
[[ -s "$T/s1.ll" ]] || { echo "$N: EMPTY s1 (vacuity trap)"; exit 1; }
"$B/ir-pass/cq-opt" -load-pass-plugin "$B/ir-pass/libCQPass.so" -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>"$T/err"; RC=$?
if [[ $RC -ne 0 ]]; then
  echo "$N: DECLINE(rc=$RC) $(grep -o 'cq [a-z0-9 -]*:[^\\n]*' "$T/err" | head -1)"
  sed -n '1,3p' "$T/err" | sed "s/^/$N:   /"
  exit 0
fi
echo "$N: ACCEPT ($(grep -c . "$T/s2.ll") lines)"
python3 "$W/tools/free_pairing_check.py" "$T/s2.ll" 2>&1 | sed "s/^/$N:   2b /" | head -4
if "$LLVM/clang" "$T/s2.ll" "$B/runtime/libcq_templates.a" "$B/runtime/libcq_runtime.a" -o "$T/a" 2>"$T/lderr"; then
  "$T/a" > "$T/trace"; echo "$N:   trace $(wc -l < "$T/trace" | tr -d ' ') lines -> $T/trace"
  cp "$T/trace" "/tmp/trace_$N.log"
else
  echo "$N:   LINK FAIL"; head -3 "$T/lderr" | sed "s/^/$N:   /"
fi
