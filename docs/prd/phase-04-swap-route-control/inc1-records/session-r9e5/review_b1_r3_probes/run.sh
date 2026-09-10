#!/bin/bash
# run.sh [PRE|PREB1|POST] [filter] — run the ROUND-3 probe corpus on one binary.
#   POST  = the tree under review (a1e6d62 + nothing) -> build/ir-pass
#   PRE   = f8d29e8, the pre-fix checkpoint (scratchpad/fix_r2/pre)
#   PREB1 = the pre-B.1 pair (scratchpad/impl_b1/pre)
# Prints: <name> rc=<n> DECLINE: <diag>  |  <name> rc=0 ACCEPT trace=<N> 2b=<...>
set -u
LLVM=/usr/local/opt/llvm@19/bin
ROOT=${CQ_ROOT:-/Users/sorenwilkening/Desktop/CQ_lang}
HERE=$(cd "$(dirname "$0")" && pwd)
SCR=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad
which=${1:-POST}; filt=${2:-}
case "$which" in
  PRE)   OPT="$SCR/fix_r2/pre/cq-opt";  PLUG="$SCR/fix_r2/pre/libCQPass.so" ;;
  PREB1) OPT="$SCR/impl_b1/pre/cq-opt"; PLUG="$SCR/impl_b1/pre/libCQPass.so" ;;
  *)     OPT="$ROOT/build/ir-pass/cq-opt"; PLUG="$ROOT/build/ir-pass/libCQPass.so" ;;
esac
OUT="$HERE/out/$which"; mkdir -p "$OUT"
for f in "$HERE"/c/*.c "$HERE"/ll/*.ll; do
  [ -e "$f" ] || continue
  b=$(basename "$f"); b="${b%.*}"
  if [ -n "$filt" ]; then case "$b" in $filt) ;; *) continue;; esac; fi
  case "$f" in
    *.c)  "$LLVM/clang" -I"$ROOT/include" -include CQ.h -O1 -emit-llvm -S "$f" -o "$OUT/$b.s1.ll" 2>"$OUT/$b.clang" || { echo "$b CLANGFAIL"; continue; } ;;
    *.ll) cp -f "$f" "$OUT/$b.s1.ll" ;;
  esac
  "$OPT" -load-pass-plugin "$PLUG" -passes=cq-lowering -S "$OUT/$b.s1.ll" -o "$OUT/$b.s2.ll" 2>"$OUT/$b.err"; rc=$?
  if [ $rc -ne 0 ]; then
    echo "$b rc=$rc DECLINE: $(grep -o "cq [a-z0-9/ -]*: [^;]*" "$OUT/$b.err" | head -1)"
  else
    python3 "$ROOT/tools/free_pairing_check.py" "$OUT/$b.s2.ll" > "$OUT/$b.2b" 2>&1
    "$LLVM/clang" "$OUT/$b.s2.ll" "$ROOT/build/runtime/libcq_templates.a" "$ROOT/build/runtime/libcq_runtime.a" -o "$OUT/$b.bin" 2>"$OUT/$b.link" && "$OUT/$b.bin" > "$OUT/$b.trace" 2>&1
    lr=$?
    n=$(wc -l < "$OUT/$b.trace" 2>/dev/null | tr -d ' ')
    echo "$b rc=0 ACCEPT trace=$n link/run=$lr 2b=$(sed -n 's/.*: \([0-9]* verified.*\)/\1/p' "$OUT/$b.2b" | head -1)"
  fi
done
